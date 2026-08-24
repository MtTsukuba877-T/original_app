class CreateQuestions < ActiveRecord::Migration[7.2]
  def change
    create_table :questions do |t|
      t.integer :question_type, null: false, comment: "質問セット種類(57=57問版、80=80問版)、MVPは57固定"
      t.references :section, null: false, foreign_key: true, comment: "所属セクション"
      t.integer :question_number, null: false, comment: "セクション内の質問番号"
      t.string :content, null: false, limit: 255, comment: "質問文本文(255文字まで)"
      t.boolean :reversed, null: false, default: false, comment: "逆転項目か否か"

      t.timestamps
    end
    add_index :questions, [:question_type, :section_id, :question_number], unique: true, name: "index_questions_on_type_section_and_number"
  end
end
