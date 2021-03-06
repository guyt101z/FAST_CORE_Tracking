require 'test_helper'

class DatabaseProcTest < ActiveSupport::TestCase
  
  fixtures :devices, :stop_events, :idle_events, :runtime_events
  
  def setup
    file = File.new(File.dirname(__FILE__) + "/../../db_procs.sql")
    file.readline
    file.readline  #skip 1st two lines of file
    sql = file.read
    sql.strip!
    statements = sql.split(';;')
    
    statements.each  {|stmt| 
      ActiveRecord::Base.connection.execute(stmt)
    }
    setup_fixtures
  end
  
  def test_stop_insert
    StopEvent.delete_all
    now = Time.now
    latitude = BigDecimal('123.0000000001')
    longitude = BigDecimal('246.0000000001')
    insert_stop(latitude,longitude, now, devices(:device1).imei, 1)
    stops = StopEvent.find(:all)
    assert_equal(1, stops.size, "should have been one stop")
    assert_equal(latitude, stops[0].latitude)
    assert_equal(longitude, stops[0].longitude)
    
    insert_stop(latitude,longitude, now+60, devices(:device1).imei, 2)
    stops = StopEvent.find(:all)
    assert_equal(1, stops.size, "should have ignored duplicate stop")
    
    insert_stop(latitude,longitude, now, devices(:device1).imei, 3)
    stops = StopEvent.find(:all)
    assert_equal(1, stops.size, "should have ignored duplicate stop w/same timestamp")
    
    insert_stop(latitude+1,longitude, now+70, devices(:device1).imei, 4)
    stops = StopEvent.find(:all)
    assert_equal(2, stops.size, "should have allowed far away duplicate stop")
    
    insert_stop(latitude,longitude, now+80, devices(:device2).imei, 5)
    stops = StopEvent.find(:all)
    assert_equal(3, stops.size, "should have allowed stop on different device")
    
    insert_stop(latitude,longitude, now-200, devices(:device1).imei, 6)
    stops = StopEvent.find(:all)
    assert_equal(4, stops.size, "should allowed stop in the past")
  end

  def test_duplicate_stops
    StopEvent.delete_all
    now = Time.now
    insert_stop(1.2,2.3, now, devices(:device1).imei, 7)
    stops = StopEvent.find(:all)
    assert_equal(1, stops.size, "should have been one stop")
    stops[0].duration=10
    stops[0].save

    insert_stop(1.2,2.3, now, devices(:device1).imei, 7)
    stops = StopEvent.find(:all)
    assert_equal(1, stops.size, "should have been one stop")
  end
  
  def test_idle_insert
    IdleEvent.delete_all
    now = Time.zone.now
    latitude = BigDecimal('123.0000000001')
    longitude = BigDecimal('246.0000000001')
    insert_idle(latitude, longitude, now, devices(:device1).imei)
    idle_events = IdleEvent.find :all
    assert_equal(1, idle_events.size, "should have been one idle event")
    assert_equal latitude, idle_events[0].latitude
    assert_equal longitude, idle_events[0].longitude
    
    insert_idle(latitude, longitude, now+60, devices(:device1).imei)
    idle_events = IdleEvent.find :all
    assert_equal(1, idle_events.size, "should have ignored duplicate idle event")
    
    insert_idle(latitude, longitude, now, devices(:device1).imei)
    idle_events = IdleEvent.find :all
    assert_equal(1, idle_events.size, "should have ignored duplicate idle event w/same timestamp")
    
    insert_idle(latitude+1, longitude, now+70, devices(:device1).imei)
    idle_events = IdleEvent.find :all
    assert_equal(2, idle_events.size, "should have allowed far away duplicate idle event")
    
    insert_idle(latitude, longitude, now+80, devices(:device2).imei)
    idle_events = IdleEvent.find :all
    assert_equal(3, idle_events.size, "should have allowed idle event on different device")

    ActiveRecord::Base.connection.execute("CALL insert_reading(2.2,2.3,3,10,5,#{devices(:device1).imei},'#{(now-100).strftime("%Y-%m-%d %H:%M:%S")}', '' )")
    insert_idle(latitude, longitude, now-200, devices(:device1).imei)
    idle_events = IdleEvent.find :all
    assert_equal(4, idle_events.size, "should allowed idle event in the past with non-idle reading since")

    now = Time.zone.now
    IdleEvent.delete_all
    Reading.delete_all
    insert_idle(latitude, longitude, now, devices(:device1).imei)
    insert_idle(latitude, longitude, now-100, devices(:device1).imei) #insert out of order duplicate event
    idle_events = IdleEvent.find :all
    assert_equal(1, idle_events.size, "should have only created one idle event")
    assert_equal((now-100).to_s, idle_events[0].created_at.to_s, "should have moved created_at to earlier event")


  end
  
  def test_runtime_insert
    RuntimeEvent.delete_all
    now = Time.now
    latitude = BigDecimal('123.0000000001')
    longitude = BigDecimal('246.0000000001')
    insert_runtime(latitude, longitude, now, devices(:device1).imei)
    runtime_events = RuntimeEvent.find :all
    assert_equal(1, runtime_events.size, "should have been one runtime event")
    assert_equal latitude, runtime_events[0].latitude
    assert_equal longitude, runtime_events[0].longitude
    
    insert_runtime(1.2, 2.3, now+60, devices(:device1).imei)
    runtime_events = RuntimeEvent.find :all
    assert_equal(1, runtime_events.size, "should have ignored duplicate runtime event")
    
    insert_runtime(1.2, 2.3, now, devices(:device1).imei)
    runtime_events = RuntimeEvent.find :all
    assert_equal(1, runtime_events.size, "should have ignored duplicate runtime event w/same timestamp")
    
    insert_runtime(2.2, 2.3, now+80, devices(:device2).imei)
    runtime_events = RuntimeEvent.find :all
    assert_equal(2, runtime_events.size, "should have allowed runtime event on different device")
    
    insert_runtime(2.2,2.3, now-200, devices(:device1).imei)
    runtime_events = RuntimeEvent.find :all
    assert_equal(3, runtime_events.size, "should allowed runtime event in the past")
  end
  
  def test_reading_insert
    Reading.delete_all
    now = Time.zone.now
    #latitude, longitude, altitude, speed, heading, event_type, created_at
    latitude = BigDecimal('123.0000000001')
    longitude = BigDecimal('246.0000000001')
    ActiveRecord::Base.connection.execute("CALL insert_reading(#{latitude},#{longitude},3,4,5,#{devices(:device1).imei},'#{now.strftime("%Y-%m-%d %H:%M:%S")}', '' )")
    readings = Reading.find(:all)
    assert_equal 1, readings.size, "there should be only one reading"
    assert_equal latitude, readings[0].latitude
    assert_equal longitude, readings[0].longitude
    assert_equal 3, readings[0].altitude
    assert_equal 4, readings[0].speed
    assert_equal 5, readings[0].direction
    assert_equal now.to_s, readings[0].created_at.to_s
    assert_equal devices(:device1).id, readings[0].device_id
  end
  
  def test_reading_insert_with_io
    Reading.delete_all
    now = Time.zone.now
    #latitude, longitude, altitude, speed, heading, event_type, created_at
    latitude = BigDecimal('123.0000000001')
    longitude = BigDecimal('246.0000000001')
    ActiveRecord::Base.connection.execute("CALL insert_reading_with_io(#{latitude},#{longitude},3,4,5,#{devices(:device1).imei},'#{now.strftime("%Y-%m-%d %H:%M:%S")}', '',1,0,1 )")
    readings = Reading.find(:all)
    assert_equal 1, readings.size, "there should be only one reading"
    assert_equal latitude, readings[0].latitude
    assert_equal longitude, readings[0].longitude
    assert_equal 3, readings[0].altitude
    assert_equal 4, readings[0].speed
    assert_equal 5, readings[0].direction
    assert_equal now.to_s, readings[0].created_at.to_s
    assert_equal devices(:device1).id, readings[0].device_id
    assert_equal true, readings[0].ignition
    assert_equal false, readings[0].gpio1
    assert_equal true, readings[0].gpio2
  end

  def test_reading_with_io_missing_device
    Reading.delete_all
    Device.delete_all
    Account.delete_all
    now = Time.zone.now
    @device = Factory(:device, :imei => '314159')
    #insert good reading
    ActiveRecord::Base.connection.execute("CALL insert_reading_with_io(1,2,3,4,5,#{@device.imei},'#{now.strftime("%Y-%m-%d %H:%M:%S")}', '',1,0,1 )")
    #insert reading for nonexistant device
    ActiveRecord::Base.connection.execute("CALL insert_reading_with_io(1,2,3,4,5,271828,'#{now.strftime("%Y-%m-%d %H:%M:%S")}', '',1,0,1 )")
    @device.reload
    assert_equal 1, @device.readings.size, "there should be only one reading since second reading was for non-existant device"
  end
  
  def test_reading_insert_with_io_retval
    Reading.delete_all
    now = Time.zone.now
    #latitude, longitude, altitude, speed, heading, event_type, created_at
    ActiveRecord::Base.connection.execute("CALL insert_reading_with_io_returnval(1,2,3,4,5,#{devices(:device1).imei},'#{now.strftime("%Y-%m-%d %H:%M:%S")}', '',1,0,1, @id )")
    readings = Reading.find(:all)
    assert_equal 1, readings.size, "there should be only one reading"
    assert_equal 1, readings[0].latitude
    assert_equal 2, readings[0].longitude
    assert_equal 3, readings[0].altitude
    assert_equal 4, readings[0].speed
    assert_equal 5, readings[0].direction
    assert_equal now.to_s, readings[0].created_at.to_s
    assert_equal devices(:device1).id, readings[0].device_id
    assert_equal true, readings[0].ignition
    assert_equal false, readings[0].gpio1
    assert_equal true, readings[0].gpio2
  end
  
  def test_process_runtimes
    Reading.delete_all
    assert_equal 20, runtime_events(:one).duration
    assert_nil runtime_events(:two).duration
    assert_nil runtime_events(:three).duration
    assert_nil runtime_events(:four).duration
    
    Reading.new(:latitude => "4.5", :longitude => "5.6", :device_id => devices(:device1).id, :created_at => "2008-07-01 15:20:00", :speed => 10, :ignition => 0).save
    Reading.new(:latitude => "8.5", :longitude => "5.614", :device_id => devices(:device1).id, :created_at => "2008-07-01 16:25:00", :speed => 10, :ignition => 0).save
    ActiveRecord::Base.connection.execute("call process_runtime_events()")
    
    runtime_events(:two).reload
    runtime_events(:three).reload
    runtime_events(:four).reload
    
    assert_equal 20, runtime_events(:one).duration
    assert_equal 20, runtime_events(:two).duration
    assert_equal 25, runtime_events(:three).duration
    assert_nil runtime_events(:four).duration
  end
  
  def insert_stop(lat, lng, created, imei, readingID)
    ActiveRecord::Base.connection.execute("CALL insert_stop_event(#{lat},#{lng},'#{imei}','#{created.strftime("%Y-%m-%d %H:%M:%S")}', #{readingID})")
  end
  
  def insert_idle(lat, lng, created, imei)
    ActiveRecord::Base.connection.execute("CALL insert_idle_event(#{lat},#{lng},'#{imei}','#{created.strftime("%Y-%m-%d %H:%M:%S")}', 42)")
  end
  
  def insert_engine_off(lat, lng, created, imei)
    ActiveRecord::Base.connection.execute("CALL insert_engine_off_event(#{lat},#{lng},'#{imei}','#{created.strftime("%Y-%m-%d %H:%M:%S")}', 42)")
  end
  
  def insert_runtime(lat, lng, created, imei)
    ActiveRecord::Base.connection.execute("CALL insert_runtime_event(#{lat},#{lng},'#{imei}','#{created.strftime("%Y-%m-%d %H:%M:%S")}', 42)")
  end
  
  
  end