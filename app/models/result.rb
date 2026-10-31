class Result < ApplicationRecord
  # 判定に使うセクション（A・B・C）のスコアがそろっていない状態で判定しようとしたときの例外（Issue #45）
  class IncompleteSectionScoresError < StandardError
  end

  # 高ストレスの基準（Issue #45）。
  # 厚生労働省の実施マニュアルの「合計点数を使う方法」（評価基準の例（その1））の数値。
  # 次の㋐・㋑のどちらかを満たすと高ストレス。D（満足度）は使わない。
  # ㋐ 領域 B の合計が 77点以上
  # ㋑ 領域 A と C の合算が 76点以上、かつ領域 B の合計が 63点以上
  HIGH_STRESS_B_SCORE = 77
  HIGH_STRESS_A_AND_C_SCORE = 76
  HIGH_STRESS_B_SCORE_WITH_A_AND_C = 63

  belongs_to :employee
  belongs_to :stress_check_period

  enum :stress_level, { high_stress: 0, low_to_moderate_stress: 1 }

  validates :stress_level, presence: true
  validates :employee_id, uniqueness: { scope: :stress_check_period_id }

  # セクション A・B・C の合計点から、ストレスの程度（:high_stress か :low_to_moderate_stress）を返す（Issue #45）。
  # 点数を基準と比べるだけで、DB は使わない。
  def self.stress_level_for(score_a:, score_b:, score_c:)
    a_and_c_score = score_a + score_c
    meets_criterion_1 = score_b >= HIGH_STRESS_B_SCORE
    meets_criterion_2 = a_and_c_score >= HIGH_STRESS_A_AND_C_SCORE && score_b >= HIGH_STRESS_B_SCORE_WITH_A_AND_C

    if meets_criterion_1 || meets_criterion_2
      :high_stress
    else
      :low_to_moderate_stress
    end
  end

  # 保存済みのセクション別スコア（judgments）から高ストレスかどうかを判定し、結果を1件保存する（Issue #45）。
  # 判定の前に、実施回の判定方法と、A・B・C のスコアがそろっていることを確かめる。
  # 問題があるとき・保存できなかったときは例外が発生し、保存されない。
  def self.create_from_section_scores!(employee:, stress_check_period:)
    unless stress_check_period.simple_sum?
      raise Judgment::UnsupportedJudgmentMethodError, "合計点数を使う方法以外の判定には対応していません"
    end

    # { "a" => 50, "b" => 61, "c" => 27, "d" => 8 } の形にする
    scores = employee.judgments
                     .where(stress_check_period: stress_check_period)
                     .joins(:section)
                     .pluck("sections.code", :section_score)
                     .to_h

    unless %w[a b c].all? { |code| scores.key?(code) }
      raise IncompleteSectionScoresError, "セクション A・B・C のスコアがそろっていません"
    end

    create!(
      employee: employee,
      stress_check_period: stress_check_period,
      stress_level: stress_level_for(score_a: scores["a"], score_b: scores["b"], score_c: scores["c"])
    )
  end

  # セッションに預けた回答から、高ストレスかどうかを判定して返す（Issue #160 お試し受検）。
  # DB には何も保存しない。点数（逆転項目の置き換え）は StressCheckResponse#score、
  # 基準は stress_level_for を使うので、通常の受検と同じ判定になる。
  # セクションごとの合計の計算は、Judgment.create_section_scores! と同じ。
  #
  # answers の形: { "質問のID（文字列）" => 選んだ番号（1〜4の整数）, ... }（session[:answers] と同じ）
  def self.stress_level_from_answers(answers)
    # 保存しない回答を、57問版の質問ごとに1件ずつ作る
    responses = Question.standard_57.includes(:section).map do |question|
      StressCheckResponse.new(question: question, raw_answer: answers[question.id.to_s])
    end

    # { "a" => 50, "b" => 61, "c" => 27, "d" => 8 } の形にする
    scores = responses.group_by { |response| response.question.section.code }
                      .to_h { |code, section_responses| [ code, section_responses.sum { |response| response.score } ] }

    stress_level_for(score_a: scores["a"], score_b: scores["b"], score_c: scores["c"])
  end
end
