class FixLatlonPrecision < ActiveRecord::Migration
  def self.up
    change_column :readings, :latitude, :decimal, :precision => 15, :scale => 10
    change_column :readings, :longitude, :decimal, :precision => 15, :scale => 10

    change_column :idle_events, :latitude, :decimal, :precision => 15, :scale => 10
    change_column :idle_events, :longitude, :decimal, :precision => 15, :scale => 10

    change_column :runtime_events, :latitude, :decimal, :precision => 15, :scale => 10
    change_column :runtime_events, :longitude, :decimal, :precision => 15, :scale => 10

    change_column :stop_events, :latitude, :decimal, :precision => 15, :scale => 10
    change_column :stop_events, :longitude, :decimal, :precision => 15, :scale => 10
  end

  def self.down
    change_column :readings, :latitude, :float
    change_column :readings, :longitude, :float

    change_column :idle_events, :latitude, :float
    change_column :idle_events, :longitude, :float

    change_column :runtime_events, :latitude, :float
    change_column :runtime_events, :longitude, :float

    change_column :stop_events, :latitude, :float
    change_column :stop_events, :longitude, :float
  end
end
