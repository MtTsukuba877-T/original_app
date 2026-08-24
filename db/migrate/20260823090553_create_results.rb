class CreateResults < ActiveRecord::Migration[7.2]
  def change
    create_table :results do |t|
      t.references :employee, null: false, foreign_key: true, comment: "受検者"
      t.references :stress_check_period, null: false, foreign_key: true, comment: "所属実施回"
      t.integer :stress_level, null: false, comment: "enum: 0=high_stress, 1=not_high_stress"
      t.timestamps
    end
    add_index :results, [:employee_id, :stress_check_period_id], unique: true, name: "index_results_on_employee_and_period"
  end
end
