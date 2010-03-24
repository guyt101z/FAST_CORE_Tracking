class SpanningEventState

  MIN_STOP_IDLE_MINUTES = 3
  MIN_STOP_IDLE_SECONDS = MIN_STOP_IDLE_MINUTES * 60
  MAX_MISSING_SECONDS = 60 * 60 * 2 # 2 hours
  MAX_EXPIRED_SECONDS = 60 * 60 * 3 # 3 hours

  @@state_cache = nil

  def self.close_expired_trips
    devices = Device.find_by_sql("
           SELECT d.id, d.recent_reading_id 
             FROM trip_events t
        LEFT JOIN devices d ON t.device_id = d.id 
        LEFT JOIN readings r ON d.recent_reading_id = r.id
            WHERE t.duration IS NULL 
              AND (t.suspect = 0 OR t.suspect IS NULL) 
              AND r.created_at < DATE_SUB(NOW(), INTERVAL #{MAX_EXPIRED_SECONDS} SECOND)")
    for device in devices
      state = get_by_device_id(device.id)
      state.set_current_reading(device.latest_reading)
      state.end_open_trip
    end
  end

  def self.get_by_reading(reading)
    get_by_device_id(reading.device_id)
  end
  
  def self.get_by_device_id(device_id)
    state_cache[device_id] || new(device_id)
  end
  
  def self.reset_cache
    state_cache.values.each {| state | state.force_open_stop_and_idle}
    @state_cache = nil
  end
  
  def self.state_cache
    @@state_cache ||= {}
  end
  
  def initialize(device_id)
    SpanningEventState.state_cache[@device_id = device_id] = self
  end
  
  def consider_reading(reading)
    return unless reading.created_at

    if (trip = find_last_open_trip) and (@current_reading ||= find_previous_reading(reading)) and reading.created_at - @current_reading.created_at > MAX_MISSING_SECONDS
      if !(previous_reading = find_previous_trip_on_reading(trip,reading))
        end_open_trip
      elsif previous_reading and (reading.created_at - previous_reading.created_at) > MAX_MISSING_SECONDS
        @current_reading = previous_reading
        end_open_trip
      end
    end

    @current_reading = reading
    case @current_reading.event_type
      when 'GPS Lock'
        @current_reading.ignition ? begin_new_trip : end_open_trip(true)
      when 'engine on'
        begin_new_trip
      when 'engine off'
        end_open_trip
      when 'idle'
        ensure_open_idle
      else
        #NOTE: fix the occasional non-report of "ignition" by things like "Direction Change"
        @current_reading.update_attribute(:ignition, true) if @current_reading.ignition.nil? and @current_reading.speed and @current_reading.speed.to_f > 0
        if @current_reading.ignition.nil?
          # NOTE: do nothing -- may be a Heartbeat or other event that does NOT report ignition
        elsif (trip = find_last_open_trip).nil?
          begin_new_trip if @current_reading.ignition
        elsif not @current_reading.ignition
          end_open_trip
        elsif @current_reading.speed
          @current_reading.speed > 0 ? end_open_stop_and_idle(trip,@current_reading) : ensure_open_stop_and_idle
        end
    end
  end
  
#private

  def force_open_stop_and_idle
    @last_open_stop.save! if find_last_open_stop
    @last_open_idle.save! if find_last_open_idle
    @last_open_stop,@last_open_idle = nil,nil
  end

  def ensure_open_stop_and_idle
    ensure_open_stop
    ensure_open_idle
  end

  def ensure_open_idle
    @last_open_idle = ensure_open_event(IdleEvent,find_last_open_idle) || :nil
  end
  
  def ensure_open_stop
    @last_open_stop = ensure_open_event(StopEvent,find_last_open_stop) || :nil
  end
  
  def ensure_open_event(klass,open_event)
    return klass.new(:device_id => @device_id,:reading_id => @current_reading.id,:created_at => @current_reading.created_at,:latitude => @current_reading.latitude,:longitude => @current_reading.longitude) unless open_event

    open_event.save! if @current_reading.created_at - open_event.created_at > MIN_STOP_IDLE_SECONDS
    
    open_event
  end
  
  def begin_new_trip
    end_open_trip(true) if find_last_open_trip
    
    end_open_idle(nil,nil) # just to be sure...
    
    @last_open_trip = TripEvent.create!(:device_id => @device_id,:reading_start_id => @current_reading.id,:created_at => @current_reading.created_at)
    
    ensure_open_idle if @current_reading.speed == 0
    end_open_stop(@last_open_trip,@current_reading) if @current_reading.speed > 0
  end

  def end_open_trip(use_previous = false)
    return end_open_idle(nil,nil) unless trip = find_last_open_trip

    closing_reading = use_previous ? find_previous_trip_on_reading(trip,@current_reading) : @current_reading
    
    duration = ((closing_reading.created_at - trip.created_at) / 60).round if closing_reading
    trip.update_attributes!(:reading_stop_id => (closing_reading ? closing_reading.id : 0),:duration => duration,:suspect => (duration.nil? || duration <= 0))
    
    end_open_idle(trip,closing_reading)
    ensure_open_stop if @current_reading.speed == 0
    
    @last_open_trip = :nil
  end
  
  def end_open_stop_and_idle(trip,closing_reading)
    end_open_stop(trip,closing_reading) if find_last_open_stop
    end_open_idle(trip,closing_reading) if find_last_open_idle
  end
  
  def end_open_idle(enclosing_trip,closing_reading)
    return unless idle = find_last_open_idle

    end_open_event(idle,enclosing_trip,closing_reading)
    
    @last_open_idle = :nil
  end
  
  def end_open_stop(enclosing_trip,closing_reading)
    return unless stop = find_last_open_stop

    end_open_event(stop,enclosing_trip,closing_reading)
    
    @last_open_stop = :nil
  end
  
  def end_open_event(open_event,enclosing_trip,closing_reading)
    if enclosing_trip.nil?
      open_event.update_attributes!(:suspect => true) unless open_event.new_record?
    else
      closing_reading ||= enclosing_trip.reading_stop
      duration = ((closing_reading.created_at - open_event.created_at) / 60).round if closing_reading
      suspect = duration.nil? || duration < MIN_STOP_IDLE_MINUTES
      open_event.update_attributes!(:duration => duration,:suspect => suspect) unless open_event.new_record? and suspect 
    end
  end
  
  def find_last_open_idle
    @last_open_idle = find_last_open_event(IdleEvent,@last_open_idle)
    @last_open_idle unless @last_open_idle == :nil
  end
  
  def find_last_open_stop
    @last_open_stop = find_last_open_event(StopEvent,@last_open_stop)
    @last_open_stop unless @last_open_stop == :nil
  end
  
  def find_last_open_trip
    @last_open_trip = find_last_open_event(TripEvent,@last_open_trip)
    @last_open_trip unless @last_open_trip == :nil
  end
  
  def find_last_open_event(klass,previous)
    return previous if previous
    
    results = klass.all(:conditions => ['device_id = ? and created_at is not null and duration is null and (suspect = 0 or suspect is null)',@device_id],:order => 'created_at desc')
    results.pop.update_attributes!(:suspect => true) while results.size > 1 # NOTE: fix suspects NOW!

    results[0] || :nil
  end
  
  def find_previous_reading(reading)
    first_minimal_reading(:conditions => ['device_id = ? and id < ? and created_at <= ?',@device_id,reading.id,reading.created_at],:order => 'created_at desc')
  end
  
  def find_previous_trip_on_reading(trip,reading)
    first_minimal_reading(:conditions => ['device_id = ? and created_at between ? and ? and ignition = 1',@device_id,trip.created_at,reading.created_at.advance(:seconds => -1)],:order => 'created_at desc') if trip
  end
  
  def first_minimal_reading(options)
    Reading.first({:select => SpanningEventHit::MINIMAL_READING_COLUMNS,:readonly => true}.update(options))
  end

  def set_current_reading(reading)
    @current_reading = reading
  end
end