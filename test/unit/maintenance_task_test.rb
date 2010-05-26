require 'test_helper'

class MaintenanceTaskTest < ActiveSupport::TestCase
  fixtures :devices,:maintenance_tasks,:runtime_events,:readings

  def test_reviewed_runtime
    task = maintenance_tasks(:one)
    assert_equal nil,task.update_status
    assert_equal (20 * 60),task.reviewed_runtime
    
    task = maintenance_tasks(:two)
    assert_equal nil,task.update_status
    assert_equal (10 * 60),task.reviewed_runtime
    
    task = maintenance_tasks(:three)
    assert_equal nil,task.update_status(task.established_at.advance(:hours => 1))
    assert_equal (10 * 60),task.reviewed_runtime
    
    task = maintenance_tasks(:four)
    assert_equal nil,task.update_status(task.established_at.advance(:days => 1))
    assert_equal (8 * 60 * 60),task.reviewed_runtime
    
    task = maintenance_tasks(:five)
    assert_equal nil,task.update_status(task.established_at.advance(:hours => 1))
    assert_equal (60 * 60),task.reviewed_runtime
    
    task = maintenance_tasks(:six)
    assert_equal nil, task.update_status
    assert_equal nil, task.reminder_notified
    assert_equal nil, task.pastdue_notified
    
    task = maintenance_tasks(:seven)
    assert task.update_status.include? 'Reminder: Maintenance task '
    assert_not_nil task.reminder_notified
    assert_equal nil, task.pastdue_notified
    
    task = maintenance_tasks(:eight)
    assert task.update_status.include? 'Past Due: Maintenance task '
    assert_equal nil, task.reminder_notified
    assert_not_nil task.pastdue_notified
  end
end
