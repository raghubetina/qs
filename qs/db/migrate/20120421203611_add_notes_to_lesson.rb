class AddNotesToLesson < ActiveRecord::Migration
  def change
    add_column :lessons, :notes, :text
  end
end
