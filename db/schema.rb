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

ActiveRecord::Schema[7.2].define(version: 2026_08_22_042914) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

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

  add_foreign_key "employees", "companies"
  add_foreign_key "users", "companies"
end
