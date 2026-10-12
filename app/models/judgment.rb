class Judgment < ApplicationRecord
  # 判定方法が「合計点数を使う方法（simple_sum）」ではない実施回を判定しようとしたときの例外（Issue #44）
  class UnsupportedJudgmentMethodError < StandardError
  end

  # 57問版の全質問の回答がそろっていない状態で判定しようとしたときの例外（Issue #44）
  class IncompleteResponsesError < StandardError
  end

  belongs_to :employee
  belongs_to :stress_check_period
  belongs_to :section

  validates :section_score, presence: true,
                            numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :employee_id, uniqueness: { scope: [ :stress_check_period_id, :section_id ] }

  # 保存済みの回答から、セクション（A〜D）ごとの合計点を計算し、1セクション1件ずつ保存する（Issue #44）。
  # 計算方法は、厚生労働省の実施マニュアルの「合計点数を使う方法」。1問ごとの点数は StressCheckResponse#score。
  # 計算の前に、実施回の判定方法と、57問版の全質問の回答がそろっていることを確かめる。
  # 問題があるとき・保存できなかったときは例外が発生し、1件も保存されない。
  def self.create_section_scores!(employee:, stress_check_period:)
    unless stress_check_period.simple_sum?
      raise UnsupportedJudgmentMethodError, "合計点数を使う方法以外の判定には対応していません"
    end

    questions = Question.standard_57
    responses = employee.stress_check_responses
                        .where(stress_check_period: stress_check_period, question: questions)
                        .includes(:question)
                        .to_a

    # 同じ質問への回答は1件しか保存できない（unique index）ので、件数が同じなら全問そろっている。
    unless responses.size == questions.count
      raise IncompleteResponsesError, "57問版の全質問の回答がそろっていません"
    end

    transaction do
      responses.group_by { |response| response.question.section_id }.each do |section_id, section_responses|
        create!(
          employee: employee,
          stress_check_period: stress_check_period,
          section_id: section_id,
          section_score: section_responses.sum { |response| response.score }
        )
      end
    end
  end
end
