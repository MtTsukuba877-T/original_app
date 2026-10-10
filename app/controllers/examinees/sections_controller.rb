# 受検画面（E-5a〜E-5d）（Issue #41、#42、#44、#45）
#
# 57問をセクション（A〜D）ごとに1画面ずつ表示する。URL の :code はセクションのコード（a〜d）。
# 回答は「次へ」「戻る」を押すたびに session[:answers] に一時的に預け、
# 「回答を送信する」で DB（stress_check_responses）にまとめて保存し（Issue #42）、
# あわせてセクション別スコアを計算して judgments に保存し（Issue #44）、
# 高ストレスかどうかを判定して results に保存する（Issue #45）。
# MVP では途中保存を行わないため、ログアウトやタイムアウトで session が消えると回答も消える。
# 受検は1回限りのため、受検済みの受検者がこの画面を開いたときは、振り分け係（受検者トップ画面）へ戻す。
#
# session[:answers] の形: { "質問のID（文字列）" => 選んだ番号（1〜4の整数）, ... }
# （session は Cookie に JSON で保存されるため、キーは文字列になる）
class Examinees::SectionsController < Examinees::BaseController
  UNANSWERED_MESSAGE = "未回答の質問があります。すべての質問に回答してください。".freeze
  SAVE_FAILED_MESSAGE = "回答を保存できませんでした。お手数ですが、もう一度「回答を送信する」を押してください。".freeze

  before_action :redirect_unless_in_examination_period
  before_action :redirect_if_responded
  before_action :set_section
  before_action :redirect_if_previous_sections_unanswered
  before_action :set_section_contents

  def show
  end

  # 画面の回答を session に預けてから、押されたボタンに応じて移動する
  def update
    store_answers

    if params[:move] == "back" && @section.previous_section
      redirect_to examinees_section_path(@section.previous_section.code)
    elsif unanswered_questions(@section).any?
      @unanswered_question_ids = unanswered_questions(@section).map(&:id)
      flash.now[:alert] = UNANSWERED_MESSAGE
      render :show, status: :unprocessable_entity
    elsif @section.next_section
      redirect_to examinees_section_path(@section.next_section.code)
    else
      complete_examination
    end
  end

  private

  # 受検期間外の受検者は、振り分け係（受検者トップ画面）へ戻す。
  # 振り分け係が、受検期間外であることを表示する。
  def redirect_unless_in_examination_period
    redirect_to examinees_home_path if current_stress_check_period.nil?
  end

  # 受検済みの受検者は、振り分け係へ戻す（Issue #42）。振り分け係が、受検が完了したことを表示する。
  # URL の直接入力や、「回答を送信する」を2回押した場合に備える。
  def redirect_if_responded
    return unless current_employee.responded_to?(current_stress_check_period)

    clear_answers_and_redirect_to_home
  end

  # URL の :code からセクションを探す。存在しないコードのときは E-5a へ戻す。
  def set_section
    @section = Section.find_by(code: params[:code])
    redirect_to examinees_section_path("a") if @section.nil?
  end

  # URL を直接入力して前の画面を飛ばすことを防ぐ。
  # この画面より前に未回答の質問が残っていれば、その画面へ戻す。
  def redirect_if_previous_sections_unanswered
    section = first_unanswered_section
    return if section.nil? || section.display_order >= @section.display_order

    redirect_to examinees_section_path(section.code), alert: UNANSWERED_MESSAGE
  end

  # 画面の表示に使うデータを用意する
  def set_section_contents
    @questions = @section.questions.standard_57.order(:question_number)
    @answer_options = @section.answer_options.order(:answer_number)
    @answers = stored_answers
    @unanswered_question_ids = []
  end

  # 預けてある回答（まだ何もなければ空のハッシュ）
  def stored_answers
    session[:answers] || {}
  end

  # この画面の質問の回答だけを取り出し、session[:answers] に追加する。
  # 送信内容は書き換えられる前提で、この画面の質問の ID と、1〜4 の値だけを受け取る。
  def store_answers
    submitted = params.fetch(:answers, {})
    answers = stored_answers.dup

    @questions.each do |question|
      value = submitted[question.id.to_s].to_i
      answers[question.id.to_s] = value if value.between?(1, 4)
    end

    session[:answers] = answers
    @answers = answers
  end

  # 指定したセクションの質問のうち、まだ回答を預かっていないもの
  def unanswered_questions(section)
    section.questions.standard_57.reject { |question| stored_answers.key?(question.id.to_s) }
  end

  # 表示順で最初の、未回答の質問が残っているセクション（すべて回答済みなら nil）
  def first_unanswered_section
    Section.order(:display_order).find { |section| unanswered_questions(section).any? }
  end

  # 「回答を送信する」を押したとき（最後のセクション）。
  # 全57問がそろっているか確認し、そろっていれば DB に保存する（Issue #42）。
  def complete_examination
    section = first_unanswered_section

    if section
      redirect_to examinees_section_path(section.code), alert: UNANSWERED_MESSAGE
    else
      save_responses
    end
  end

  # 預かっている回答を DB に保存し、セクション別スコアと高ストレスの判定結果を保存して、振り分け係へ移動する（Issue #42、#44、#45）。
  # 保存・計算・判定は Employee#submit_answers! がまとめて行う（全部か0件か）。
  # 失敗しても Rails のエラー画面は出さない。
  # 「回答を送信する」を2回押した場合、後の送信は重複で失敗するが、
  # 先の送信で保存できているので、保存できたときと同じ動きにする。
  def save_responses
    current_employee.submit_answers!(
      stress_check_period: current_stress_check_period,
      answers: stored_answers
    )
    clear_answers_and_redirect_to_home
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique,
         Judgment::IncompleteResponsesError, Judgment::UnsupportedJudgmentMethodError,
         Result::IncompleteSectionScoresError
    if current_employee.responded_to?(current_stress_check_period)
      clear_answers_and_redirect_to_home
    else
      redirect_to examinees_section_path(@section.code), alert: SAVE_FAILED_MESSAGE
    end
  end

  # 預かっていた回答を session から消して、振り分け係へ移動する（Issue #42）。
  # 心身の情報を、必要以上に Cookie に残さないため。
  def clear_answers_and_redirect_to_home
    session.delete(:answers)
    redirect_to examinees_home_path
  end
end
