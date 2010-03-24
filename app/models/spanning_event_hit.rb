class SpanningEventHit < ActiveRecord::Base
  
  DELAY_FOR_OUT_OF_ORDER_VOLATILITY = 60 * 5 # 5 minutes
  MINIMAL_READING_COLUMNS = "#{column_names.join(',')},latitude,longitude"
  
  belongs_to :device
  belongs_to :reading, :foreign_key => :id, :select => MINIMAL_READING_COLUMNS
  
  def self.process_queue(system_is_current = false)
    true while process_next_queue_chunk
    SpanningEventState.close_expired_trips if system_is_current
  ensure
    SpanningEventState.reset_cache
  end
  
  def consider_and_discard
#puts "CONSIDER #{event_type} @ #{created_at}"    
    if event_type == 'delayed'
      reading.update_attributes!(:note => event_type, :event_type => "delayed #{reading.event_type}")
    else
      reading.update_attributes!(:note => event_type)
      SpanningEventState.get_by_reading(reading).consider_reading(reading)
    end
    destroy
  end
  
private
  
  def self.process_next_queue_chunk
#    hits = all(:conditions => "created_at < adddate(now(),interval -#{DELAY_FOR_OUT_OF_ORDER_VOLATILITY} second)",:order => 'created_at,id',:limit => 100).each {| hit | hit.consider_and_discard}
    hits = all(:order => 'created_at,id',:limit => 100).each {| hit | hit.consider_and_discard}
    hits.any?
  end
end
