class CreateJudgments < ActiveRecord::Migration[7.2]
  def change
    create_table :judgments do |t|
      t.references :employee, null: false, foreign_key: true, comment: "受検者"
      t.references :stress_check_period, null: false, foreign_key: true, comment: "所属実施回"
      t.references :section, null: false, foreign_key: true, comment: "対象セクション"
      t.integer :section_score, null: false, comment: "セクション別の合計評価点"
      t.timestamps
    end
    add_index :judgments, [:employee_id, :stress_check_period_id, :section_id], unique: true, name: "index_judgments_on_employee_period_and_section"
  end
end
