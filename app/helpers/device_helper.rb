module DeviceHelper
  
  def select_device(search_params)
    label_tag('search[device_id]', '<strong>Filter by device:</strong>') + ' ' + 
      select_tag('search[device_id]', build_device_options(search_params))     
  end

private
  def build_device_options(search_params)
    selected_id = search_params.nil? ? '' : search_params[:device_id]
    returning "" do |options|
      options << options_for_select([['All', '']], selected_id)
      options << '<option disabled="disabled">--------------</option>'
      options << options_from_collection_for_select(Device.all(:order => "name"), :id, :name, selected_id.to_i)
    end
  end
end
