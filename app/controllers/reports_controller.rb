require 'fastercsv'

class ReportsController < ApplicationController
  before_filter :authorize
  before_filter :authorize_device, :except => ['index','trip_detail']
  DayInSeconds = 86400
  NUMBER_OF_DAYS = 7
  MAX_LIMIT = 999 # Max number of results

  def index
    if params[:group_id]
      session[:group_value] = params[:group_id] # To allow groups to be selected on reports index page
    end
    
     @groups=Group.find(:all, :conditions=>['account_id=?',session[:account_id]], :order=>'name')
     if session[:group_value]=="all" 
         @devices = Device.get_devices(session[:account_id]) # Get devices associated with account    
     elsif session[:group_value]=="default"
         @devices = Device.find(:all, :conditions=>['account_id=? and group_id is NULL and provision_status_id=1',session[:account_id]], :order=>'name')                     
     else
         @devices = Device.find(:all, :conditions=>['account_id=? and group_id =? and provision_status_id=1',session[:account_id], session[:group_value]], :order=>'name')
     end    
  end

  def trip
    get_start_and_end_date
    get_devices()
 
    needy_events = TripEvent.find(:all,:conditions => ["device_id = ? AND created_at BETWEEN ? AND ? AND duration IS NOT NULL AND (distance IS NULL OR idle IS NULL)",params[:id],@start_dt_str, @end_dt_str])
    for event in needy_events
      event.update_stats
    end
 
    @trip_events = TripEvent.paginate(:per_page=>ResultCount, :page=>params[:page],
      :conditions => get_device_and_dates_with_duration_conditions(:trip_events),
      :readonly => true,# NOTE: this causes some problems, but would be nice... :include => [:reading_start,:reading_stop],
      :order => "created_at desc")
 
    @readings = @trip_events # TODO -- remove this???
 
    @record_count = TripEvent.count('id', :conditions => get_device_and_dates_with_duration_conditions(:trip_events))
    @actual_record_count = @record_count # this is because currently we are putting  MAX_LIMIT on export data so export and view data going to be diferent in numbers.
    @record_count = MAX_LIMIT if @record_count > MAX_LIMIT
 
    @total_travel_time = TripEvent.sum(:duration,:conditions => ["id in (?)", @trip_events.collect(&:id)])
    @total_idle_time = TripEvent.sum(:idle,:conditions => ["id in (?)", @trip_events.collect(&:id)])
    @total_distance = TripEvent.sum(:distance,:conditions => ["id in (?)", @trip_events.collect(&:id)])
    @max_speed = Reading.maximum(:speed,:conditions => get_device_and_dates_conditions) || 0
  end
  
  def trip_detail
    @trip = TripEvent.find(params[:id])
    @device = @trip.device
    @device_names = Device.get_names(session[:account_id])
    conditions = @trip.reading_stop ? ["device_id = ? and created_at between ? and ?",@trip.device_id,@trip.reading_start.created_at,@trip.reading_stop.created_at] : ["device_id = ? and created_at >= ?",@trip.device_id,@trip.reading_start.created_at]
    @readings = Reading.paginate(:per_page=>ResultCount, :page=>params[:page], :conditions => conditions, :order => "created_at desc")
    @record_count = Reading.count('id', :conditions => conditions)
    @actual_record_count = @record_count # this is because currently we are putting  MAX_LIMIT on export data so export and view data are going to be different in numbers.
    @record_count = MAX_LIMIT if @record_count > MAX_LIMIT
  end

  def all
    get_start_and_end_date
    @device = Device.find(params[:id])    
    @device_names = Device.get_names(session[:account_id])
    conditions = get_device_and_dates_conditions
    @readings = Reading.paginate(:per_page=>ResultCount, :page=>params[:page], :conditions => conditions, :order => "created_at desc")
    @record_count = Reading.count(:conditions => conditions)
    @actual_record_count = @record_count # this is because currently we are putting  MAX_LIMIT on export data so export and view data are going to be different in numbers.
    @record_count = MAX_LIMIT if @record_count > MAX_LIMIT
  rescue
    flash[:error] = $!.to_s
    redirect_to :back
  end

  # TODO consider how to use the word "task" instead of "reading" for these elements
  def maintenance
    @device = Device.find(params[:id])
    @device.update_mileage
    @device_names = Device.get_names(session[:account_id])
    conditions = ["device_id = ?",params[:id]]
    @readings = MaintenanceTask.paginate(:per_page => ResultCount,:page => params[:page],:conditions => conditions,
      :order => "(completed_at is null) desc,completed_at desc,established_at desc")
    @record_count = MaintenanceTask.count(:conditions => conditions)
    @actual_record_count = @record_count # this is because currently we are putting  MAX_LIMIT on export data so export and view data are going to be different in numbers.
    @record_count = MAX_LIMIT if @record_count > MAX_LIMIT
  end
  
  def speeding
    get_start_and_end_date
    @device = Device.find(params[:id])    
    @device_names = Device.get_names(session[:account_id])
    conditions = "#{get_device_and_dates_conditions} and speed > #{(@device.account.max_speed or -1)}"
    @readings=Reading.paginate(:per_page=>ResultCount, :page=>params[:page], :conditions => conditions, :order => "created_at desc")
    @record_count = Reading.count('id', :conditions => conditions)
    @actual_record_count = @record_count # this is because currently we are putting  MAX_LIMIT on export data so export and view data are going to be different in numbers.
    @record_count = MAX_LIMIT if @record_count > MAX_LIMIT
  rescue
    flash[:error] = $!.to_s
    redirect_to :back
  end
  
  def stop
    get_start_and_end_date
    @device = Device.find(params[:id])
    @device_names = Device.get_names(session[:account_id])
    conditions = get_device_and_dates_with_duration_conditions(:stop_events)
    @stop_events = StopEvent.paginate(:per_page=>ResultCount, :page=>params[:page], :conditions => conditions, :order => "created_at desc")
    @readings = @stop_events
    @record_count = StopEvent.count('id', :conditions => conditions)
    @actual_record_count = @record_count # this is because currently we are putting  MAX_LIMIT on export data so export and view data going to be diferent in numbers.
    @record_count = MAX_LIMIT if @record_count > MAX_LIMIT
  rescue
    flash[:error] = $!.to_s
    redirect_to :back
  end

  def idle
    get_start_and_end_date
    @device = Device.find(params[:id])
    @device_names = Device.get_names(session[:account_id])
    conditions = get_device_and_dates_with_duration_conditions(:idle_events)
    @idle_events = IdleEvent.paginate(:per_page=>ResultCount, :page=>params[:page], :conditions => conditions, :order => "created_at desc")
    @readings = @idle_events
    @record_count = IdleEvent.count('id', :conditions => conditions)
    @actual_record_count = @record_count # this is because currently we are putting  MAX_LIMIT on export data so export and view data going to be diferent in numbers.
    @record_count = MAX_LIMIT if @record_count > MAX_LIMIT
  rescue
    flash[:error] = $!.to_s
    redirect_to :back
  end

  def runtime
    get_start_and_end_date
    @device = Device.find(params[:id])
    @device_names = Device.get_names(session[:account_id])
    conditions = get_device_and_dates_with_duration_conditions(:runtime_events,false)
    @runtime_events = RuntimeEvent.paginate(:per_page=>ResultCount, :page=>params[:page],:conditions => conditions,:order => "created_at desc")
    @runtime_total = RuntimeEvent.sum(:duration,:conditions => conditions)
    active_event = RuntimeEvent.find(:first,:conditions => "#{conditions} and duration is null")
    @runtime_total += ((Time.now - active_event.created_at) / 60).to_i if active_event
    @readings = @runtime_events
    @record_count = RuntimeEvent.count('id', :conditions => conditions)
    @actual_record_count = @record_count # this is because currently we are putting  MAX_LIMIT on export data so export and view data going to be diferent in numbers.
    @record_count = MAX_LIMIT if @record_count > MAX_LIMIT
  rescue
    flash[:error] = $!.to_s
    redirect_to :back
  end

  # Display geofence exceptions
  def geofence
    get_start_and_end_date
    @device = Device.find(params[:id])
    @device_names = Device.get_names(session[:account_id])
    @geofences = Device.find(params[:id]).geofences # Geofences to display as overlays
    conditions = "#{get_device_and_dates_conditions} and geofence_id != 0"
    @readings = Reading.paginate(:per_page=>ResultCount, :page=>params[:page], :conditions => conditions, :order => "created_at desc")
    @record_count = Reading.count('id', :conditions => conditions)
    @actual_record_count = @record_count
    @record_count = MAX_LIMIT if @record_count > MAX_LIMIT
  rescue
    flash[:error] = $!.to_s
    redirect_to :back
  end

  # Display gpio1 events
  def gpio1
    get_start_and_end_date
    @device = Device.find(params[:id])
    @device_names = Device.get_names(session[:account_id])
    conditions = "#{get_device_and_dates_conditions} and gpio1 is not null"
    @readings = Reading.paginate(:per_page=>ResultCount, :page=>params[:page], :conditions => conditions, :order => "created_at desc")
    @record_count = Reading.count('id', :conditions => conditions)
    @actual_record_count = @record_count
    @record_count = MAX_LIMIT if @record_count > MAX_LIMIT
  rescue
    flash[:error] = $!.to_s
    redirect_to :back
  end

  # Display gpio2 events
  def gpio2
    get_start_and_end_date
    @device = Device.find(params[:id])
    @device_names = Device.get_names(session[:account_id])
    conditions = "#{get_device_and_dates_conditions} and gpio2 is not null"
    @readings = Reading.paginate(:per_page=>ResultCount, :page=>params[:page], :conditions => conditions, :order => "created_at desc")
    @record_count = Reading.count('id', :conditions => conditions)
    @actual_record_count = @record_count
    @record_count = MAX_LIMIT if @record_count > MAX_LIMIT
  rescue
    flash[:error] = $!.to_s
    redirect_to :back
  end

  def all_events
    get_start_and_end_date
    get_devices()
    @readings = Reading.find_by_sql("SELECT readings.id,readings.created_at,readings.ignition,readings.speed,readings.event_type,t1.id AS trip_start_id,(SELECT t2.id FROM trip_events t2 WHERE t2.reading_stop_id = readings.id) AS trip_stop_id,t1.suspect AS trip_suspect,t1.duration AS trip_duration,i.id AS idle_id,i.duration,i.suspect AS idle_suspect,i.duration AS idle_duration,s.id AS stop_id,s.duration AS stop_duration,s.suspect AS stop_suspect FROM readings LEFT JOIN trip_events t1 ON readings.id = reading_start_id LEFT JOIN idle_events i ON i.reading_id = readings.id LEFT JOIN stop_events s ON s.reading_id = readings.id WHERE #{get_device_and_dates_conditions} ORDER BY readings.created_at,readings.id")
    @record_count = @readings.length
    @actual_record_count = @record_count
  rescue
    flash[:error] = $!.to_s
    @readings,@record_count,@actual_record_count = [],0,0
  end

  # Export report data to CSV
  def export
    params[:page] = 1 unless params[:page]
    get_start_and_end_date
    
    case params[:type]
      when 'stop'
        return export_events(StopEvent.find(:all, {:order => "created_at desc", :conditions => get_device_and_dates_with_duration_conditions(:stop_events)}))
      when 'idle'
        return export_events(IdleEvent.find(:all, {:order => "created_at desc", :conditions => get_device_and_dates_with_duration_conditions(:idle_events)}))
      when 'runtime'
        return export_events(RuntimeEvent.find(:all, {:order => "created_at desc", :conditions => get_device_and_dates_with_duration_conditions(:runtime_events,false)}))
      when 'maintenance'
        return export_maintenance
      when 'trip'
        return export_trips()
    end

    event_type_clause = "AND geofence_id != 0" if params[:type] == 'geofence'
    readings = Reading.find(:all,:order => "created_at desc",:offset => ((params[:page].to_i-1)*ResultCount),:limit=>MAX_LIMIT,
      :conditions => "#{get_device_and_dates_conditions} #{event_type_clause}")

    # Name of the csv file
    @filename = params[:type] + "_" + params[:id] + ".csv"
    csv_string = FasterCSV.generate do |csv|
      csv << ["Location","Speed (mph)","Started","Latitude","Longitude","Event Type"]
      readings.each do |reading|
        local_time = reading.get_local_time(reading.created_at.in_time_zone.inspect)
        csv << [reading.short_address,reading.speed,local_time,reading.latitude,reading.longitude,reading.event_type]
      end
    end

    send_data csv_string,
      :type => 'text/csv; charset=iso-8859-1; header=present',
      :disposition => "attachment; filename=#{@filename}"
  rescue
    flash[:error] = $!.to_s
    redirect_to :back
  end

  def speed
    @readings = Reading.find(:all, :order => "created_at desc", :limit => ResultCount, :conditions => "event_type='speeding_et40' and device_id='#{params[:id]}'")
  end

private

  def export_events(events)
    @filename = params[:type] + "_" + params[:id] + ".csv"

    csv_string = FasterCSV.generate do |csv|
      csv << ["Location","#{params[:type].capitalize} Duration (m)","Started","Latitude","Longitude"]
      events.each do |event|
        local_time = event.get_local_time(event.created_at.in_time_zone.inspect)
        address = event.reading.nil? ? "#{event.latitude};#{event.longitude}" : event.reading.short_address
        csv << [address,((event.duration.to_s.strip.size > 0) ? event.duration : 'Unknown'),local_time, event.latitude,event.longitude]
      end
    end

    send_data csv_string,
      :type => 'text/csv; charset=iso-8859-1; header=present',
      :disposition => "attachment; filename=#{@filename}"
  end
  
  def export_maintenance
    tasks = MaintenanceTask.paginate(:per_page => ResultCount,:page => params[:page],:conditions => ["device_id = ? and completed_at is not null",params[:id]], :order => "completed_at desc")

    @filename = "maintenance_#{params[:id]}.csv"

    csv_string = FasterCSV.generate do |csv|
      csv << ["Maintenance Task","Completed Date","Completed By"]
      tasks.each do |task|
        csv << [task.description,task.completed_at.strftime("%Y-%m-%d"),task.completed_by]
      end
    end

    send_data csv_string,
      :type => 'text/csv; charset=iso-8859-1; header=present',
      :disposition => "attachment; filename=#{@filename}"
  end

  def export_trips
    needy_events = TripEvent.find(:all,:conditions => ["device_id = ? AND created_at BETWEEN ? AND ? AND duration IS NOT NULL AND (distance IS NULL OR idle IS NULL)",params[:id],@start_dt_str, @end_dt_str])
    for event in needy_events
      event.update_stats
    end
  
    @trip_events = TripEvent.find(:all,
      :conditions => ["device_id = ? and created_at between ? and ?",params[:id],@start_dt_str, @end_dt_str],
      :readonly => true,# NOTE: this causes some problems, but would be nice... :include => [:reading_start,:reading_stop],
      :order => "created_at desc")
    csv_string = FasterCSV.generate do |csv|
      csv << ['Start Address', 'Stop Address', 'Duration', 'Miles', 'Started']
      for trip in @trip_events
        row = []
        row << trip.reading_start.short_address
        if trip.reading_stop
          row << trip.reading_stop.short_address
          row << minutes_to_hours(trip.duration)
          row << sprintf('%2.1f',trip.distance || 0.0)
        else
          row << '-'
          start_time = trip.reading_start.created_at.to_i
          end_time = Time.now.to_i
          duration = (end_time-start_time)/60
          row << "In progress: #{minutes_to_hours(duration)}"
          row << '-'
        end
        row << displayLocalDT(trip.created_at)
  
        csv << row
      end
    end
    send_data csv_string, :type => 'text/csv; charset=iso-8859-1; header=present', :disposition => "attachment; filename=trips_for_device_#{params[:id]}.csv"
  end
  
  
    def get_device_and_dates_conditions(table = :readings,optional_clause = nil)
      "#{table}.device_id = #{params[:id]} AND #{table}.created_at BETWEEN '#{@start_dt_str}' AND '#{@end_dt_str}'#{optional_clause}"
    end

    def get_device_and_dates_with_duration_conditions(table = :readings,possible_suspects = true)
      return "device_id = #{params[:id]} AND ((created_at BETWEEN '#{@start_dt_str}' AND '#{@end_dt_str}') OR (duration IS NULL))#{suspect_clause(possible_suspects)}" if Time.now < @end_dt_str.to_time
      get_device_and_dates_conditions(table,suspect_clause(possible_suspects))
    end

    def suspect_clause(possible_suspects)
  #    @suspect_clause ||= current_user.is_super_super_admin? ? "" : " and (suspect = 0 or suspect is null)" if possible_suspects
      @suspect_clause ||= " and (suspect = 0 or suspect is null)" if possible_suspects
    end

    def get_devices
      @device = Device.find(params[:id])    
      @device_names = Device.get_names(session[:account_id])
    end


  def get_start_and_end_date
    if params[:start_date].blank?
      @end_date = Date.today
      @start_date = Date.today - NUMBER_OF_DAYS
    else
      if params[:start_date].class == String
        @end_date = @start_date = params[:start_date].to_date
      else
        @end_date = @start_date = get_date(params[:start_date])
      end
    end
    
    if !params[:end_date].blank?
      if params[:end_date].class == String
        @end_date = params[:end_date].to_date
      else
        @end_date = get_date(params[:end_date])
      end
    end
    
    @start_date,@end_date = @end_date,@start_date if @end_date < @start_date

    offset = Time.now.in_time_zone.utc_offset - SERVER_UTC_OFFSET
    @start_dt_str = (@start_date.to_time - offset).to_s(:db)
    @end_dt_str   = (@end_date.tomorrow.to_time - 1 - offset).to_s(:db)
  end
  
  def displayLocalDT(timestamp) 
    timestamp.in_time_zone.strftime("%a %b %e %Y %l:%M:%S %p")
  end

  def minutes_to_hours(min)
    if min < 60
      (min % 60).to_s + " min"
    else
      hr = min / 60
      hr.to_s + (hr == 1 ? " hr" : " hrs") + ", " + (min % 60).to_s + " min"
    end
  end
  
end
