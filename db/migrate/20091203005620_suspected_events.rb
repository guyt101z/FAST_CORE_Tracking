class SuspectedEvents < ActiveRecord::Migration
  def self.up
    add_column :trip_events,:suspect,:boolean
    add_column :idle_events,:suspect,:boolean
    add_column :stop_events,:suspect,:boolean
  end

  def self.down
    remove_column :trip_events,:suspect
    remove_column :idle_events,:suspect
    remove_column :stop_events,:suspect
  end
end
