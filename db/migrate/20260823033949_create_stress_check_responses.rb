class CreateStressCheckResponses < ActiveRecord::Migration[7.2]
  def change
    create_table :stress_check_responses do |t|
      t.references :employee, null: false, foreign_key: true, comment: "受検者"
      t.references :stress_check_period, null: false, foreign_key: true, comment: "所属実施回"
      t.references :question, null: false, foreign_key: true, comment: "質問番号"
      t.integer :raw_answer, null: false, comment: "受検者が選択した生回答(1〜4)"
      t.timestamps
    end
    add_index :stress_check_responses, [:employee_id, :stress_check_period_id, :question_id], unique: true, name: "index_stress_check_responses_on_employee_period_and_question"
  end
end
