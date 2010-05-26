class AddMileageMaintenanceTasks < ActiveRecord::Migration
  def self.up
    add_column :maintenance_tasks, :target_mileage, :float
  end

  def self.down
    remove_column :maintenance_tasks, :target_mileage
  end
end