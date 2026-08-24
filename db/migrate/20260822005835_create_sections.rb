class CreateSections < ActiveRecord::Migration[7.2]
  def change
    create_table :sections do |t|
      t.string :code, null: false, limit: 10, comment: "セクション識別コード(a/b/c/d、10文字まで)"
      t.string :name, null: false, limit: 50, comment: "セクション名(50文字まで)"
      t.text :intro_text, null: false, comment: "受検画面の導入文"
      t.text :group_text, comment: "Cセクションのみ使用(NULL許容)"
      t.integer :display_order, null: false, comment: "表示順(1〜4)"

      t.timestamps
    end
    add_index :sections, :code, unique: true
    add_index :sections, :display_order, unique: true
  end
end
