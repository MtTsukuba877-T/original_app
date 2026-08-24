class CreateLineFriends < ActiveRecord::Migration[7.2]
  def change
    create_table :line_friends do |t|
      t.references :company, null: false, foreign_key: true, comment: "所属企業"
      t.string :line_user_id, null: false, limit: 50, comment: "LINE識別子(50文字まで)"
      t.references :employee, foreign_key: true, index: { unique: true }, comment: "紐付け完了後にセット(NULL許容)"
      t.string :initial_reg_token, limit: 50, comment: "初期登録トークン(50文字まで、NULL許容)"
      t.datetime :token_generated_at, comment: "トークン生成日時(NULL許容)"
      t.integer :token_send_count, null: false, default: 0, comment: "トークン送信回数"
      t.datetime :token_expires_at, comment: "トークン有効期限(NULL許容)"
      t.timestamps
    end
    add_index :line_friends, [:company_id, :line_user_id], unique: true
    add_index :line_friends, :initial_reg_token, unique: true
  end
end
