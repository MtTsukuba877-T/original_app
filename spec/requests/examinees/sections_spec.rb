require "rails_helper"

RSpec.describe "Examinees::Sections", type: :request do
  let(:employee) { create(:employee, :password_changed, password: "password123") }

  # セクション A〜D（各セクションに選択肢4つ・質問2問）を用意する。
  # C の1問目にだけグループ設問文を入れる。
  before do
    %w[a b c d].each.with_index(1) do |code, order|
      section = create(:section, code: code, display_order: order, intro_text: "#{code.upcase}の導入文")
      (1..4).each { |number| create(:answer_option, section: section, answer_number: number, text: "選択肢#{number}") }
      (1..2).each do |number|
        create(:question, section: section, question_number: number, content: "#{code.upcase}の質問#{number}")
      end
    end
    Question.find_by(content: "Cの質問1").update!(group_text: "Cのグループ設問文")
  end

  # 受検者としてログインする
  def sign_in_employee
    post examinees_sign_in_path, params: {
      company_id: employee.company_id,
      examinee_number: employee.examinee_number,
      password: "password123"
    }
  end

  # 受検者の会社に、今日を含む実施回を作る
  def create_period_in_examination
    create(:stress_check_period, company: employee.company,
                                 start_date: Date.current - 1,
                                 end_date: Date.current + 1)
  end

  # 指定したセクションの質問（質問番号の順）
  def questions_of(code)
    Section.find_by(code: code).questions.order(:question_number)
  end

  # 指定したセクションの全問に「選択肢1」で答えた送信内容
  def all_answers_params(code)
    questions_of(code).to_h { |question| [ question.id.to_s, "1" ] }
  end

  # 指定したセクションの全問に答えて「次へ」を押す（先の画面を開くための準備）
  def answer_sections(*codes)
    codes.each do |code|
      patch examinees_section_path(code), params: { answers: all_answers_params(code), move: "next" }
    end
  end

  # 受検者を受検済みにする（指定した実施回の回答を1件作る）。
  # 質問は before で作ったものを使う（ファクトリーに任せると、セクションと質問が余分に作られるため）。
  def create_response_in(period)
    create(:stress_check_response, employee: employee, stress_check_period: period, question: Question.first)
  end

  describe "GET /examinees/sections/:code" do
    context "未ログインの場合" do
      it "ログイン画面にリダイレクトすること" do
        get examinees_section_path("a")
        expect(response).to redirect_to(examinees_sign_in_path)
      end
    end

    context "ログイン済・受検期間外の場合" do
      before { sign_in_employee }

      it "受検者トップ画面（振り分け係）にリダイレクトすること" do
        get examinees_section_path("a")
        expect(response).to redirect_to(examinees_home_path)
      end
    end

    context "ログイン済・受検期間内の場合" do
      before do
        sign_in_employee
        create_period_in_examination
      end

      it "E-5a に注意事項・導入文・質問・選択肢・「次へ」が表示され、「戻る」は表示されないこと" do
        get examinees_section_path("a")
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("これから全部で57問の質問をします。")
        expect(response.body).to include("A. Aの導入文")
        expect(response.body).to include("1. Aの質問1")
        expect(response.body).to include("選択肢1")
        expect(response.body).to include("次へ")
        expect(response.body).not_to include("戻る")
      end

      it "最初はどの選択肢も選ばれていないこと" do
        get examinees_section_path("a")
        assert_select "input[type=radio][checked]", count: 0
      end

      it "ログアウトボタンに確認ポップアップが設定されていること" do
        get examinees_section_path("a")
        expect(response.body).to include("onsubmit")
        expect(response.body).to include("回答は保存されません。ログアウトしますか？")
      end

      it "E-5c にグループ設問文が表示されること" do
        answer_sections("a", "b")
        get examinees_section_path("c")
        expect(response.body).to include("Cのグループ設問文")
      end

      it "E-5d に「戻る」と「回答を送信する」が表示され、注意事項は表示されないこと" do
        answer_sections("a", "b", "c")
        get examinees_section_path("d")
        expect(response.body).to include("戻る")
        expect(response.body).to include("回答を送信する")
        expect(response.body).not_to include("これから全部で57問の質問をします。")
      end

      it "存在しないコードの場合は E-5a にリダイレクトすること" do
        get examinees_section_path("z")
        expect(response).to redirect_to(examinees_section_path("a"))
      end

      it "前の画面に未回答があるまま先の画面を開くと、未回答のある画面に戻されること" do
        get examinees_section_path("c")
        expect(response).to redirect_to(examinees_section_path("a"))
        follow_redirect!
        expect(response.body).to include("未回答の質問があります。すべての質問に回答してください。")
      end
    end

    context "ログイン済・受検期間内で、受検済みの場合（Issue #42）" do
      before do
        sign_in_employee
        create_response_in(create_period_in_examination)
      end

      it "受検者トップ画面（振り分け係）にリダイレクトすること" do
        get examinees_section_path("a")
        expect(response).to redirect_to(examinees_home_path)
      end
    end
  end

  describe "PATCH /examinees/sections/:code" do
    context "ログイン済・受検期間外の場合" do
      before { sign_in_employee }

      it "受検者トップ画面（振り分け係）にリダイレクトすること" do
        patch examinees_section_path("a"), params: { answers: all_answers_params("a"), move: "next" }
        expect(response).to redirect_to(examinees_home_path)
      end
    end

    context "ログイン済・受検期間内の場合" do
      before do
        sign_in_employee
        create_period_in_examination
      end

      it "全問に答えて「次へ」を押すと次の画面へ移動し、戻ったときに回答が選ばれた状態であること" do
        patch examinees_section_path("a"), params: { answers: all_answers_params("a"), move: "next" }
        expect(response).to redirect_to(examinees_section_path("b"))

        get examinees_section_path("a")
        assert_select "input[type=radio][checked]", count: 2
      end

      it "未回答があって「次へ」を押すと、同じ画面にエラーを表示し、答えた分は選ばれたままであること" do
        first_question = questions_of("a").first
        patch examinees_section_path("a"), params: { answers: { first_question.id.to_s => "2" }, move: "next" }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("未回答の質問があります。すべての質問に回答してください。")
        assert_select "p", text: "この質問に回答してください。", count: 1
        assert_select "input[name='answers[#{first_question.id}]'][value='2'][checked]"
      end

      it "未回答があっても「戻る」を押すと前の画面へ移動し、途中の回答が残っていること" do
        answer_sections("a")
        first_question = questions_of("b").first
        patch examinees_section_path("b"), params: { answers: { first_question.id.to_s => "3" }, move: "back" }
        expect(response).to redirect_to(examinees_section_path("a"))

        get examinees_section_path("b")
        assert_select "input[name='answers[#{first_question.id}]'][value='3'][checked]"
      end

      it "1〜4 以外の値や、別の画面の質問の回答は預からないこと" do
        a_question1, a_question2 = questions_of("a").to_a
        b_question = questions_of("b").first
        patch examinees_section_path("a"), params: {
          answers: { a_question1.id.to_s => "5", a_question2.id.to_s => "1", b_question.id.to_s => "1" },
          move: "next"
        }
        expect(response).to have_http_status(:unprocessable_entity)
        assert_select "p", text: "この質問に回答してください。", count: 1

        answer_sections("a")
        get examinees_section_path("b")
        assert_select "input[type=radio][checked]", count: 0
      end

      it "E-5d で全問に答えて「回答を送信する」を押すと、回答が DB に保存され、受検者トップ画面に完了の表示が出ること" do
        answer_sections("a", "b", "c", "d")
        expect(response).to redirect_to(examinees_home_path)

        period = employee.company.stress_check_periods.first
        responses = StressCheckResponse.where(employee: employee, stress_check_period: period)
        expect(responses.count).to eq(Question.count)
        expect(responses.pluck(:raw_answer).uniq).to eq([ 1 ])

        follow_redirect!
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("受検が完了しました")
      end

      it "回答を保存した後は、session に回答が残っていないこと" do
        answer_sections("a", "b", "c")
        expect(session[:answers]).to be_present

        answer_sections("d")
        expect(session[:answers]).to be_nil
      end

      # 全問に1番で回答する。A は1問目を逆転項目にするので、4点 ＋ 1点で5点。B〜D は 1点 × 2問で2点。
      it "「回答を送信する」を押すと、セクション別スコアが judgments に保存されること（Issue #44）" do
        questions_of("a").first.update!(reversed: true)

        answer_sections("a", "b", "c", "d")
        expect(response).to redirect_to(examinees_home_path)

        period = employee.company.stress_check_periods.first
        judgments = Judgment.where(employee: employee, stress_check_period: period)
        expect(judgments.count).to eq(Section.count)
        scores = judgments.joins(:section).order("sections.display_order").pluck("sections.code", :section_score)
        expect(scores).to eq([ [ "a", 5 ], [ "b", 2 ], [ "c", 2 ], [ "d", 2 ] ])
      end

      # 全問に1番で回答する。各セクション2問なので、B は2点で、基準に届かない（高ストレスではない）。
      it "「回答を送信する」を押すと、高ストレスの判定結果が results に1件保存されること（Issue #45）" do
        answer_sections("a", "b", "c", "d")
        expect(response).to redirect_to(examinees_home_path)

        period = employee.company.stress_check_periods.first
        results = Result.where(employee: employee, stress_check_period: period)
        expect(results.count).to eq(1)
        expect(results.first.stress_level).to eq("low_to_moderate_stress")
      end

      it "保存に失敗し、受検済みになっていない場合は、E-5d に戻ってエラーを表示し、回答は session に残っていること" do
        allow(StressCheckResponse).to receive(:save_answers!).and_raise(ActiveRecord::RecordInvalid)

        answer_sections("a", "b", "c", "d")
        expect(response).to redirect_to(examinees_section_path("d"))
        expect(StressCheckResponse.count).to eq(0)
        expect(session[:answers]).to be_present

        follow_redirect!
        expect(response.body).to include("回答を保存できませんでした。お手数ですが、もう一度「回答を送信する」を押してください。")
      end

      # 回答の保存は成功し、その後の判定で失敗する状況（ブラウザでは、実施回の判定方法を変えて確かめた）。
      it "判定方法が合計点数を使う方法でない実施回では、E-5d に戻ってエラーを表示し、回答も判定も保存されず、回答は session に残っていること（Issue #44）" do
        employee.company.stress_check_periods.first.update!(judgment_method: :raw_score_conversion)

        answer_sections("a", "b", "c", "d")
        expect(response).to redirect_to(examinees_section_path("d"))
        expect(StressCheckResponse.count).to eq(0)
        expect(Judgment.count).to eq(0)
        expect(session[:answers]).to be_present

        follow_redirect!
        expect(response.body).to include("回答を保存できませんでした。お手数ですが、もう一度「回答を送信する」を押してください。")
      end

      it "判定で回答がそろっていないと判断された場合も、E-5d に戻ってエラーを表示し、回答も判定も保存されないこと（Issue #44）" do
        allow(Judgment).to receive(:create_section_scores!).and_raise(Judgment::IncompleteResponsesError)

        answer_sections("a", "b", "c", "d")
        expect(response).to redirect_to(examinees_section_path("d"))
        expect(StressCheckResponse.count).to eq(0)
        expect(Judgment.count).to eq(0)

        follow_redirect!
        expect(response.body).to include("回答を保存できませんでした。お手数ですが、もう一度「回答を送信する」を押してください。")
      end

      it "判定でスコアがそろっていないと判断された場合も、E-5d に戻ってエラーを表示し、回答もスコアも判定結果も保存されないこと（Issue #45）" do
        allow(Result).to receive(:create_from_section_scores!).and_raise(Result::IncompleteSectionScoresError)

        answer_sections("a", "b", "c", "d")
        expect(response).to redirect_to(examinees_section_path("d"))
        expect(StressCheckResponse.count).to eq(0)
        expect(Judgment.count).to eq(0)
        expect(Result.count).to eq(0)
        expect(session[:answers]).to be_present

        follow_redirect!
        expect(response.body).to include("回答を保存できませんでした。お手数ですが、もう一度「回答を送信する」を押してください。")
      end

      # 「回答を送信する」を2回押したときの、後の送信を再現する。
      # 保存の途中で、先の送信が保存を終え、後の送信は重複で失敗した、という状況。
      # 先の送信の回答は、後の送信のトランザクションの外で確定している。
      # そのため、保存と判定をまとめる Employee#submit_answers! そのものを差し替えて再現する（Issue #44）。
      it "保存が重複で失敗したが、受検済みになっている場合は、エラーを出さずに完了の表示になること" do
        period = employee.company.stress_check_periods.first
        allow_any_instance_of(Employee).to receive(:submit_answers!) do
          create_response_in(period)
          raise ActiveRecord::RecordNotUnique, "duplicate key"
        end

        answer_sections("a", "b", "c", "d")
        expect(response).to redirect_to(examinees_home_path)
        expect(session[:answers]).to be_nil

        follow_redirect!
        expect(response.body).to include("受検が完了しました")
        expect(response.body).not_to include("回答を保存できませんでした。")
      end
    end

    context "ログイン済・受検期間内で、受検済みの場合（Issue #42）" do
      before do
        sign_in_employee
        create_response_in(create_period_in_examination)
      end

      it "回答を送信しても受検者トップ画面（振り分け係）にリダイレクトし、回答の件数が増えないこと" do
        patch examinees_section_path("d"), params: { answers: all_answers_params("d"), move: "next" }
        expect(response).to redirect_to(examinees_home_path)
        expect(StressCheckResponse.count).to eq(1)
      end
    end
  end
end
