# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2026_08_23_090553) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "answer_options", force: :cascade do |t|
    t.bigint "section_id", null: false, comment: "所属セクション"
    t.integer "answer_number", null: false, comment: "受検者が選択する番号(1〜4)"
    t.string "text", limit: 50, null: false, comment: "選択肢の文言(50文字まで)"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["section_id", "answer_number"], name: "index_answer_options_on_section_id_and_answer_number", unique: true
    t.index ["section_id"], name: "index_answer_options_on_section_id"
  end

  create_table "companies", force: :cascade do |t|
    t.string "name", limit: 100, null: false, comment: "企業名(100文字まで)"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_companies_on_name"
  end

  create_table "employees", force: :cascade do |t|
    t.bigint "company_id", null: false, comment: "所属企業"
    t.string "examinee_number", limit: 15, null: false, comment: "受検者番号(15文字まで)"
    t.string "name", limit: 50, null: false, comment: "氏名(50文字まで)"
    t.date "date_of_birth", null: false, comment: "生年月日"
    t.integer "sex", null: false, comment: "enum: 1=male, 2=female"
    t.string "department", limit: 100, comment: "所属部署(NULL許容、100文字まで)"
    t.string "email", limit: 255, comment: "メールアドレス(NULL許容、255文字まで、メール配信用)"
    t.string "password_digest", null: false, comment: "bcrypt暗号化パスワード"
    t.datetime "password_changed_at", comment: "パスワード変更日時(NULL許容、NULLは初回ログイン扱い)"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "examinee_number"], name: "index_employees_on_company_id_and_examinee_number", unique: true
    t.index ["company_id"], name: "index_employees_on_company_id"
  end

  create_table "judgments", force: :cascade do |t|
    t.bigint "employee_id", null: false, comment: "受検者"
    t.bigint "stress_check_period_id", null: false, comment: "所属実施回"
    t.bigint "section_id", null: false, comment: "対象セクション"
    t.integer "section_score", null: false, comment: "セクション別の合計評価点"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["employee_id", "stress_check_period_id", "section_id"], name: "index_judgments_on_employee_period_and_section", unique: true
    t.index ["employee_id"], name: "index_judgments_on_employee_id"
    t.index ["section_id"], name: "index_judgments_on_section_id"
    t.index ["stress_check_period_id"], name: "index_judgments_on_stress_check_period_id"
  end

  create_table "line_friends", force: :cascade do |t|
    t.bigint "company_id", null: false, comment: "所属企業"
    t.string "line_user_id", limit: 50, null: false, comment: "LINE識別子(50文字まで)"
    t.bigint "employee_id", comment: "紐付け完了後にセット(NULL許容)"
    t.string "initial_reg_token", limit: 50, comment: "初期登録トークン(50文字まで、NULL許容)"
    t.datetime "token_generated_at", comment: "トークン生成日時(NULL許容)"
    t.integer "token_send_count", default: 0, null: false, comment: "トークン送信回数"
    t.datetime "token_expires_at", comment: "トークン有効期限(NULL許容)"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "line_user_id"], name: "index_line_friends_on_company_id_and_line_user_id", unique: true
    t.index ["company_id"], name: "index_line_friends_on_company_id"
    t.index ["employee_id"], name: "index_line_friends_on_employee_id", unique: true
    t.index ["initial_reg_token"], name: "index_line_friends_on_initial_reg_token", unique: true
  end

  create_table "questions", force: :cascade do |t|
    t.integer "question_type", null: false, comment: "質問セット種類(57=57問版、80=80問版)、MVPは57固定"
    t.bigint "section_id", null: false, comment: "所属セクション"
    t.integer "question_number", null: false, comment: "セクション内の質問番号"
    t.string "content", limit: 255, null: false, comment: "質問文本文(255文字まで)"
    t.boolean "reversed", default: false, null: false, comment: "逆転項目か否か"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["question_type", "section_id", "question_number"], name: "index_questions_on_type_section_and_number", unique: true
    t.index ["section_id"], name: "index_questions_on_section_id"
  end

  create_table "results", force: :cascade do |t|
    t.bigint "employee_id", null: false, comment: "受検者"
    t.bigint "stress_check_period_id", null: false, comment: "所属実施回"
    t.integer "stress_level", null: false, comment: "enum: 0=high_stress, 1=not_high_stress"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["employee_id", "stress_check_period_id"], name: "index_results_on_employee_and_period", unique: true
    t.index ["employee_id"], name: "index_results_on_employee_id"
    t.index ["stress_check_period_id"], name: "index_results_on_stress_check_period_id"
  end

  create_table "sections", force: :cascade do |t|
    t.string "code", limit: 10, null: false, comment: "セクション識別コード(a/b/c/d、10文字まで)"
    t.string "name", limit: 50, null: false, comment: "セクション名(50文字まで)"
    t.text "intro_text", null: false, comment: "受検画面の導入文"
    t.text "group_text", comment: "Cセクションのみ使用(NULL許容)"
    t.integer "display_order", null: false, comment: "表示順(1〜4)"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_sections_on_code", unique: true
    t.index ["display_order"], name: "index_sections_on_display_order", unique: true
  end

  create_table "stress_check_periods", force: :cascade do |t|
    t.bigint "company_id", null: false, comment: "所属企業"
    t.string "name", limit: 30, null: false, comment: "実施回の表示名(30文字まで)"
    t.date "start_date", comment: "受検開始日(NULL許容)"
    t.date "end_date", comment: "受検終了日(NULL許容)"
    t.integer "judgment_method", default: 0, null: false, comment: "enum: 0=simple_sum, 1=raw_score_conversion"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "name"], name: "index_stress_check_periods_on_company_id_and_name", unique: true
    t.index ["company_id"], name: "index_stress_check_periods_on_company_id"
  end

  create_table "stress_check_responses", force: :cascade do |t|
    t.bigint "employee_id", null: false, comment: "受検者"
    t.bigint "stress_check_period_id", null: false, comment: "所属実施回"
    t.bigint "question_id", null: false, comment: "質問番号"
    t.integer "raw_answer", null: false, comment: "受検者が選択した生回答(1〜4)"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["employee_id", "stress_check_period_id", "question_id"], name: "index_stress_check_responses_on_employee_period_and_question", unique: true
    t.index ["employee_id"], name: "index_stress_check_responses_on_employee_id"
    t.index ["question_id"], name: "index_stress_check_responses_on_question_id"
    t.index ["stress_check_period_id"], name: "index_stress_check_responses_on_stress_check_period_id"
  end

  create_table "users", force: :cascade do |t|
    t.bigint "company_id", comment: "NULL許容(システム管理者はNULL)"
    t.integer "role", null: false, comment: "enum: 0=system_admin, 1=company_hr"
    t.string "name", limit: 50, null: false, comment: "氏名(50文字まで)"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "invitation_token"
    t.datetime "invitation_created_at"
    t.datetime "invitation_sent_at"
    t.datetime "invitation_accepted_at"
    t.integer "invitation_limit"
    t.string "invited_by_type"
    t.bigint "invited_by_id"
    t.integer "invitations_count", default: 0
    t.index ["company_id"], name: "index_users_on_company_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["invitation_token"], name: "index_users_on_invitation_token", unique: true
    t.index ["invited_by_id"], name: "index_users_on_invited_by_id"
    t.index ["invited_by_type", "invited_by_id"], name: "index_users_on_invited_by"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "answer_options", "sections"
  add_foreign_key "employees", "companies"
  add_foreign_key "judgments", "employees"
  add_foreign_key "judgments", "sections"
  add_foreign_key "judgments", "stress_check_periods"
  add_foreign_key "line_friends", "companies"
  add_foreign_key "line_friends", "employees"
  add_foreign_key "questions", "sections"
  add_foreign_key "results", "employees"
  add_foreign_key "results", "stress_check_periods"
  add_foreign_key "stress_check_periods", "companies"
  add_foreign_key "stress_check_responses", "employees"
  add_foreign_key "stress_check_responses", "questions"
  add_foreign_key "stress_check_responses", "stress_check_periods"
  add_foreign_key "users", "companies"
end
