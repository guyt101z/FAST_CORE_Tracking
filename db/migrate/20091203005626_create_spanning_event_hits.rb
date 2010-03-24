class CreateSpanningEventHits < ActiveRecord::Migration
  def self.up
    create_table :spanning_event_hits do |t|
      t.column :device_id,:integer
      t.column :event_type,:string
      t.column :ignition,:boolean
      t.column :speed,:float
      t.column :created_at,:datetime
    end
    add_index :spanning_event_hits,[:created_at,:id]
    add_index :trip_events,[:device_id,:created_at,:suspect]
    add_index :idle_events,[:device_id,:created_at,:suspect]
    add_index :stop_events,[:device_id,:created_at,:suspect]
  end

  def self.down
    remove_index :trip_events,[:device_id,:created_at,:suspect]
    remove_index :idle_events,[:device_id,:created_at,:suspect]
    remove_index :stop_events,[:device_id,:created_at,:suspect]
    drop_table :spanning_event_hits
    add_index :trip_events,[:device_id,:suspect,:created_at]
    add_index :idle_events,[:device_id,:suspect,:created_at]
    add_index :stop_events,[:device_id,:suspect,:created_at]
  end
end
