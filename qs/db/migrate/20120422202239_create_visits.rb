class CreateVisits < ActiveRecord::Migration
  def change
    create_table :visits do |t|
      t.integer :number

      t.timestamps
    end
  end
end
