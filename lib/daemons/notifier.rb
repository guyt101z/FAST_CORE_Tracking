#!/usr/bin/env ruby

# Load EngineYard config
if File.exist?("/data/ublip/shared/config/mongrel_cluster.yml")
  mongrel_cluster = "/data/ublip/shared/config/mongrel_cluster.yml"
else
  mongrel_cluster = "/opt/ublip/rails/shared/config/mongrel_cluster.yml"
  Dir.chdir("/opt/ublip/rails/current") # For Rails 2.3.2 compat
end

# Load the env from mongrel_cluster
settings = YAML::load_file(mongrel_cluster)
ENV['RAILS_ENV'] = settings['environment']

require File.dirname(__FILE__) + "/../../config/environment"

$running,$sleeping = true,false
Signal.trap("TERM") do 
  exit if $sleeping
  $running = false
end

logger = TaskUtil.get_log_and_check_running('notifier',$0,ARGV)

begin
  while($running) do

    logger.info("The Notification and Spanning-Event-Hit (#{SpanningEventHit.count}) daemon is still running at #{Time.now}.\n")

    TripEvent.identify_suspect_events(logger)
    IdleEvent.identify_suspect_events(logger)
    StopEvent.identify_suspect_events(logger) # not currently needed, but keeping up just in case...
    SpanningEventHit.process_queue(true) # NOTE: if performance becomes an issue having these two logical processes together, put this in another daemon

    NotificationState.instance.begin_reading_bounds

    if NotificationState.instance.any_readings?
      [ :send_geofence_notifications,
        :send_device_offline_notifications,
        :send_gpio_notifications,
        :send_speed_notifications].each do | send_notifications_method |
        begin
          Notifier.send(send_notifications_method,logger)
        rescue
          logger.info "Fatal error in #{send_notifications_method} at #{Time.now.inspect}, error: #{$!}"
          $!.backtrace.each {|line| logger.info line}
        end
      end
    end 

    NotificationState.instance.end_reading_bounds

    #doesn't depend on readings, so doesn't belong inside NotificationState block
    Notifier.send_maintenance_notifications(logger)

    $sleeping = true
    sleep 60 if $running
    $sleeping = false

  end
rescue
  logger.info("ERROR: #{$!}")
  $!.backtrace.each {|line| logger.info line}
end