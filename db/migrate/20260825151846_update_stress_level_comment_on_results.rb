class UpdateStressLevelCommentOnResults < ActiveRecord::Migration[7.2]
  def change
    change_column_comment :results, :stress_level,
      from: "enum: 0=high_stress, 1=not_high_stress",
      to: "enum: 0=high_stress, 1=low_to_moderate_stress"
  end
end
