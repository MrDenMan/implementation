class CreateTickets < ActiveRecord::Migration[6.1]
  def change
    create_table :tickets do |t|
      t.integer :event_id
      t.decimal :price
      t.text :category
      t.integer :visitor_id
      t.integer :status
      t.timestamp :ticket_timestamp

      t.timestamps
    end
  end
end
