class CreateJournals < ActiveRecord::Migration[6.1]
  def change
    create_table :journals do |t|
      t.text :direction
      t.integer :event_id
      t.text :status
      t.integer :visitor_id

      t.timestamps
    end
  end
end
