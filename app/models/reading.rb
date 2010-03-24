require 'net/http'
require "rexml/document"

class Reading < ActiveRecord::Base
  belongs_to :device
  has_one :stop_event
  belongs_to :geofence
  include ApplicationHelper
  
  acts_as_mappable  :lat_column_name => :latitude,:lng_column_name => :longitude
  
  
  def self.per_page
    25
  end
  
  def speed
    read_attribute(:speed).round if read_attribute(:speed)
  end

  
  def get_fence_name
    return nil if self.geofence_id.zero? || self.geofence_id.blank?
    @fence_name ||= self.geofence.nil? ? nil : self.geofence.name
  end
  
  def fence_description
    return '' if self.geofence_id.zero? || self.geofence_id.blank?
    @fence_description ||= self.geofence_event_type + 'ing ' + (get_fence_name() || 'geofence')
  end
     
  def short_address
    if(admin_name1.nil?)
      latitude.to_s + ", " + longitude.to_s
    else
      begin
        addressParts = Array.new
        if(!street.nil?)
          if(!street_number.nil?) 
            streetAddress = [street_number, street]
            streetAddress.delete("")
            addressParts << streetAddress.join(' ')
          else 
            addressParts << street
          end
        end
        addressParts << place_name
        addressParts << admin_name1
        addressString = addressParts.join(', ')
        addressString.empty? ? latitude.to_s + ", " + longitude.to_s : addressString
      rescue
        latitude.to_s + ", " + longitude.to_s
      end
    end
  end
  
end
