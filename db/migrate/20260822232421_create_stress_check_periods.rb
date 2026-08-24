class CreateStressCheckPeriods < ActiveRecord::Migration[7.2]
  def change
    create_table :stress_check_periods do |t|
      t.references :company, null: false, foreign_key: true, comment: "所属企業"
      t.string :name, null: false, limit: 30, comment: "実施回の表示名(30文字まで)"
      t.date :start_date, comment: "受検開始日(NULL許容)"
      t.date :end_date, comment: "受検終了日(NULL許容)"
      t.integer :judgment_method, null: false, default: 0, comment: "enum: 0=simple_sum, 1=raw_score_conversion"
      t.timestamps
    end
    add_index :stress_check_periods, [:company_id, :name], unique: true
  end
end
