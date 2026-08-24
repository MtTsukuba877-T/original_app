class CreateAnswerOptions < ActiveRecord::Migration[7.2]
  def change
    create_table :answer_options do |t|
      t.references :section, null: false, foreign_key: true, comment: "所属セクション"
      t.integer :answer_number, null: false, comment: "受検者が選択する番号(1〜4)"
      t.string :text, null: false, limit: 50, comment: "選択肢の文言(50文字まで)"
      t.timestamps
    end
    add_index :answer_options, [:section_id, :answer_number], unique: true
  end
end
