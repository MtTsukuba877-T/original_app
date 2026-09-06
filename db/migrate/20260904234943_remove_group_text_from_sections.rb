class RemoveGroupTextFromSections < ActiveRecord::Migration[7.2]
  def change
    remove_column :sections, :group_text, :text
  end
end
