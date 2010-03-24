require 'test_helper'

class ReadingTest < ActiveSupport::TestCase


  def setup
    Reading.delete_all
    Device.delete_all
    Account.delete_all
  end
  
  def test_address
    reading5 = Factory(:reading, :place_name => 'Bigfork', :admin_name1 => 'MT')
    assert_equal "Bigfork, MT", reading5.short_address

    reading1 = Factory(:reading, :street => 'Big Springs Dr', :street_number => '6762', :place_name => 'Arlington', :admin_name1 => 'TX')
    assert_equal "6762 Big Springs Dr, Arlington, TX", reading1.short_address

    reading2 = Factory(:reading, :place_name => 'Farmers Branch', :street => 'Inwood Rd', :admin_name1 => 'TX')
    assert_equal "Inwood Rd, Farmers Branch, TX", reading2.short_address

    reading3 = Factory(:reading)
    assert_equal "1.2, 2.3", reading3.short_address
  end
  
  def test_speed_round
    reading1 = Factory(:reading, :speed => 28.5)
    reading2 = Factory(:reading, :speed => 39.4)
    assert_equal 29, reading1.speed
    assert_equal 39, reading2.speed
  end
  
  def test_null_speed
    reading1 = Factory(:reading, :speed => nil)
    reading2 = Factory(:reading, :speed => 55)
    assert_equal nil, reading1.speed
    assert_not_equal nil, reading2.speed
  end
  
  def test_distance
    reading1 = Reading.new
    reading1.latitude=32.6782
    reading1.longitude=-97.0449
    
    reading2 = Reading.new
    reading2.latitude=32.6782
    reading2.longitude=-97.0446
    
    reading3 = Reading.new
    reading3.latitude=32.6752
    reading3.longitude=-97.0425
    
#    puts reading1.distance_to(reading2)*1000
#    puts reading1.distance_to(reading3)*1000
  end
   
  def test_fence_name
    reading_no_fence = Factory(:reading)
    geofence = Factory(:geofence)
    reading_with_fence = Factory(:reading, :geofence => geofence)
    assert_nil reading_no_fence.get_fence_name
    assert_equal "Garth", reading_with_fence.get_fence_name
    
    reading = Factory(:reading)
    reading.geofence_id = 1234 #bad geofence ID
    assert_nil reading.get_fence_name()
  end

  end
