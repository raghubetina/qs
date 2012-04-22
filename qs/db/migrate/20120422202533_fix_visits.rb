class FixVisits < ActiveRecord::Migration
  def up
    add_column :visits, :lesson_id, :integer
    rename_column :visits, :number, :delta
  end

  def down
  end
end
