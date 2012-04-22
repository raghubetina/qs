class AddIsAnsweredToQuestions < ActiveRecord::Migration
  def change
    add_column :questions, :is_answered, :boolean
  end
end
