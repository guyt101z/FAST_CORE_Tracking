class Admin::ReadingsController < ApplicationController
  unloadable # making unloadable per http://dev.rubyonrails.org/ticket/6001
  before_filter :authorize_super_admin
  layout 'admin'
  
  helper :device
  
  def index
    today = Date.today
    thirtyDaysAgo = today - 30    
    
      if params
        if params[:search]          
          if params[:search][:device_id].empty?
            # selected "All" in the device list.
            @readings = Reading.paginate(:per_page=>ResultCount, :page => params[:page], :conditions=>["created_at > ?", thirtyDaysAgo.to_s], :order => "created_at desc")
          else
            # filter by device
            @readings = Reading.paginate(:per_page=>ResultCount, :page => params[:page],:conditions => ["device_id = ? and created_at > ? ", params[:search][:device_id], thirtyDaysAgo.to_s], :order => "created_at desc")
          end  
        else
          @readings = Reading.paginate(:per_page=>ResultCount, :page => params[:page], :conditions=>["created_at > ?", thirtyDaysAgo.to_s], :order => "created_at desc")
        end                  
      else  
        @readings = Reading.paginate(:per_page=>ResultCount, :page => params[:page], :conditions=>["created_at > ?", thirtyDaysAgo.to_s], :order => "created_at desc")
      end    
  end
 end
