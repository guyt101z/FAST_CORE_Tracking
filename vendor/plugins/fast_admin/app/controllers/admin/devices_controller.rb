class Admin::DevicesController < ApplicationController
  unloadable # making unloadable per http://dev.rubyonrails.org/ticket/6001
  before_filter :authorize_super_admin
  layout 'admin'
  
  helper_method :device_imei_or_link
  
  def device_imei_or_link(logical_device)
    gateway = Gateway.find(logical_device.gateway_name)
    return logical_device.imei unless gateway and logical_device.gateway_device
    %(<a href="#{gateway.device_uri}/#{logical_device.gateway_device.id}">#{logical_device.imei}</a>)
  end
  
  def index
      @devices = Device.search_for_devices(params[:search], params[:page])
      Account.active.by_company
  end
  
  def search
    @keyword_search = params[:keyword_search] || ""
    @devices = Device.name_or_imei_like(params[:keyword_search]).paginate(:per_page=>ResultCount, :page => params[:page], :order => "name asc")      
    Account.active.by_company
    render :action => :index
  end

  def show
    @device = Device.find(params[:id])
  end

  def new
   @device = Device.new
   @accounts = Account.find(:all, :order => "company", :conditions => "is_deleted=0")
  end

  def edit
    @device = Device.find(params[:id])
    @accounts = Account.find(:all, :order => "company", :conditions => "is_deleted=0")
  end

  def create
    if request.post?
      device = Device.new(params[:device])
      
      params[:device][:is_public] == '1' ? device.is_public = true : device.is_public = false
  
      if device.save
        redirect_to :action => 'index' and return
        flash[:success] = "#{device.name} created successfully"
      else
        error_msg = ''
        device.errors.each_full do |error|
          error_msg += error + "<br />"
        end
        flash[:error] = error_msg
        redirect_to :action => "new" and return
      end
    end
  end

  def update
    if request.post?
      device = Device.find(params[:id])
      params[:device][:is_public].nil? ? device.is_public = false : device.is_public = true
      
      # Let's determine if the device is being moved between accounts. If so, we need to nil the group_id
      if device.account_id.to_s != params[:device][:account_id]
        params[:device][:group_id] = nil
      end
      
      success = device.update_attributes(params[:device])
      
      if success
        flash[:success] = "#{device.name} updated successfully"
        if params[:account_id]
          redirect_to :action => 'index', :id => params[:account_id]
        else
          redirect_to :action => 'index'
        end
      else # Error updating device
        error_msg = 'Please fix the following errors:<br />'
        
        device.errors.each{ |field, msg|
          error_msg += '- ' + field + ' ' + msg + '<br />'
        }
        
        flash[:error] = error_msg
        redirect_to :action => 'edit', :id => params[:id]
      end
    end
  end

  def destroy
    if request.post?
      device = Device.find(params[:id])
      device.update_attribute(:provision_status_id, 2)
      device.update_attribute(:name, "-") if device.name == "" || device.name.nil?
      device.save!
      flash[:success] = "#{device.name} deleted successfully"
    end  
    
    if params[:account_id]
      redirect_to :action => 'index', :id => params[:account_id].to_s
    else
      redirect_to :action => 'index'
    end
    
  end
  
  # User can asynchronously get MSISDN for device by clicking on link in device admin
  def get_msisdn
    remoteURL = "http://deploymanager.ublip.com:8000/gsm_devices.json?key=#{params[:key]}";
    response = Net::HTTP.get_response(URI.parse(remoteURL)).body
    render :json => response
  end
  
end
