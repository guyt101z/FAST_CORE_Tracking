require 'test_helper'

class GroupNotificationTest < ActionMailer::TestCase
  fixtures :group_notifications

  def setup
      @logger = ActiveRecord::Base.logger
      @logger.auto_flushing = true
      @logger.info("This notification daemon is still running at #{Time.now}.\n")    
      NotificationState.instance.begin_reading_bounds
  end
  
  def test_send_device_offline_notifications
      devices_to_notify = Notifier.send_device_offline_notifications(@logger)
      assert_equal 3, (devices_to_notify[0] ? devices_to_notify[0].id : 'none notified')
  end    
    
  def test_send_gpio_notifications #TODO:  this doesn't actually test sending any gpio notifications
      devices_to_notify = Notifier.send_gpio_notifications(@logger)
      assert_equal 0, devices_to_notify.length
  end
    
  def test_send_speed_notifications
      devices_to_notify = Notifier.send_speed_notifications(@logger)
      assert_equal 5, devices_to_notify.length
  end    
end
