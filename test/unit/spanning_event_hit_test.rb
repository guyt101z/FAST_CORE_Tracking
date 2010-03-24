require 'test_helper'

class SpanningEventHitTest < ActiveSupport::TestCase
  fixtures :spanning_event_hits, :readings

#  def setup
#    file = File.new("#{RAILS_ROOT}/db_procs.sql")
#    file.readline
#    file.readline  #skip 1st two lines of file
#    sql = file.read
#    sql.strip!
#    statements = sql.split(';;')
#
#    statements.each  {|stmt|
#      ActiveRecord::Base.connection.execute(stmt)
#    }
#  end

  def test_spanning_event_hits
    SpanningEventHit.process_queue(true) 
      
    assert_equal 'delayed', readings(:readings_10000).note
    assert_equal 'delayed normal', readings(:readings_10000).event_type
    assert_equal 'other', readings(:readings_10001).note
    assert_equal 'GPS Lock', readings(:readings_10001).event_type
    assert_equal true, readings(:readings_10002).ignition
    assert_equal nil, readings(:readings_10003).ignition
  end
  
  def test_spanning_event_hit_creation

    Reading.delete_all

    file = File.new("#{RAILS_ROOT}/db_procs.sql")
    file.readline
    file.readline  #skip 1st two lines of file
    sql = file.read
    sql.strip!
    statements = sql.split(';;')

    statements.each  {|stmt|
      ActiveRecord::Base.connection.execute(stmt)
    }

    reading1 = Reading.create(:event_type => 'normal',    :ignition => true, :device_id => 2, :speed => 20.0, :created_at => 10.seconds.ago)
    reading2 = Reading.create(:event_type => 'normal',    :ignition => true, :device_id => 2, :speed => 20.0, :created_at => reading1.created_at)
    reading3 = Reading.create(:event_type => 'engine_on', :ignition => true, :device_id => 2, :speed => 20.0, :created_at => 15.seconds.ago)
    reading4 = Reading.create(:event_type => 'engine_on', :ignition => true, :device_id => 2, :speed => 20.0, :created_at => 500.seconds.ago)
    reading5 = Reading.create(:event_type => 'normal',    :ignition => true, :device_id => 2, :speed => 20.0, :created_at => 9.seconds.ago)
    reading6 = Reading.create(:event_type => 'GPS Lock',  :ignition => true, :device_id => 2, :speed => 20.0, :created_at => 9.seconds.ago)
    reading7 = Reading.create(:event_type => 'normal',    :ignition => true, :device_id => 2, :speed => 20.0, :created_at => 5.seconds.ago)

#This one behaves differently in Dev vs. Test
    assert_equal 'alone', SpanningEventHit.find(reading1.id).event_type
    assert_equal 'duplicate', SpanningEventHit.find(reading2.id).event_type
    assert_equal 'tardy', SpanningEventHit.find(reading3.id).event_type
    assert_equal 'delayed', SpanningEventHit.find(reading4.id).event_type
    assert_nil SpanningEventHit.find_by_id(reading5.id)
    assert_equal 'GPS Lock', SpanningEventHit.find(reading6.id).event_type
    assert_equal 'other', SpanningEventHit.find(reading7).event_type

  end
    
end
