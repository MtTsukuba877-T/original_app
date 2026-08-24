class CreateEmployees < ActiveRecord::Migration[7.2]
  def change
    create_table :employees do |t|
      t.references :company, null: false, foreign_key: true, comment: "所属企業"
      t.string :examinee_number, null: false, limit: 15, comment: "受検者番号(15文字まで)"
      t.string :name, null: false, limit: 50, comment: "氏名(50文字まで)"
      t.date :date_of_birth, null: false, comment: "生年月日"
      t.integer :sex, null: false, comment: "enum: 1=male, 2=female"
      t.string :department, limit: 100, comment: "所属部署(NULL許容、100文字まで)"
      t.string :email, limit: 255, comment: "メールアドレス(NULL許容、255文字まで、メール配信用)"
      t.string :password_digest, null: false, comment: "bcrypt暗号化パスワード"
      t.datetime :password_changed_at, comment: "パスワード変更日時(NULL許容、NULLは初回ログイン扱い)"
      t.timestamps
    end
    add_index :employees, [ :company_id, :examinee_number ], unique: true
  end
end
