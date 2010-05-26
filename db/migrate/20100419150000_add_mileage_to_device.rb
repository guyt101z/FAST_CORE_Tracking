class AddMileageToDevice < ActiveRecord::Migration
  def self.up
    add_column :devices, :total_mileage, :float, :default => 0.0
    add_column :devices, :latest_mileage_reading_id, :integer
  end

  def self.down
    remove_column :devices, :total_mileage
    remove_column :devices, :latest_mileage_reading_id
  end
end
