class AddCommentToQuestionsGroupText < ActiveRecord::Migration[7.2]
  def change
    change_column_comment :questions, :group_text, from: nil, to: "グループ設問文(Cセクションのみ使用、NULL許容)"
  end
end
