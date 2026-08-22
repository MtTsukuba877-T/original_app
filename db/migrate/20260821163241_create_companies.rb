class CreateCompanies < ActiveRecord::Migration[7.2]
  def change
    create_table :companies do |t|
      t.string :name, null: false, limit: 100, comment: "企業名(100文字まで)"
      t.timestamps
    end
    add_index :companies, :name
  end
end
