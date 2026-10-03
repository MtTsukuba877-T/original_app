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

      it "E-5d で全問に答えて「回答を送信する」を押すと、確認のメッセージとともに受検者トップ画面へ移動すること（Issue #41 時点の仮の動き）" do
        answer_sections("a", "b", "c", "d")
        expect(response).to redirect_to(examinees_home_path)

        follow_redirect!
        expect(response).to redirect_to(examinees_section_path("a"))

        follow_redirect!
        expect(response.body).to include("全57問の回答を確認しました。（回答の保存は Issue #42 で実装予定）")
      end
    end
  end
end
