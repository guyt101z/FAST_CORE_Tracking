module HomeHelper

  def decide_action 
     content=""  
     if @from_reports
         content << %(select_action(this,'from_reports'))
     elsif @from_statistics
         content << %(select_action(this,'from_statistics'))
     elsif @from_maintenance
         content << %(select_action(this,'from_maintenance'))
     elsif @from_devices || @from_search
         content << %(select_action(this,'from_devices'))
     else    
         content << %(select_action(this,'from_home'))
     end
     content
 end
 
  def show_device(device)
    content = ""
    content << %(<tr class="#{cycle('dark_row', 'light_row')}" id="row#{device.id}"> <td>)
    if device.latest_gps_reading
      if device.latest_gps_reading.short_address == ', '
        content << %(#{device.name})
      else
        content << %(<a href="javascript:centerMapOnDevice(#{device.id});highlightRow(#{device.id});" title="Center map on this device" class="link-all1">#{device.name}</a>)
      end
    else
      content << %(#{device.name})
    end      
    content << %(</td>)

    content << %(<td>)
    if device.latest_gps_reading
      if device.latest_gps_reading.short_address == ', '
        content << %(GPS Not Available)
      else
        content << %(#{device.latest_gps_reading.short_address})
      end
    else
      content << %(N/A)
    end
    content << %(</td>)

    content << %(<td>)
    content << latest_status_html(device)
    content << %(</td>)

    content << %(<td>)
    if device.latest_gps_reading
      content << %(#{time_ago_in_words device.latest_gps_reading.created_at} ago)
    else
      content << %(N/A)
    end
    content << %(</td>)
    content << %(</tr>)

    content
  end

  def add_device_js(device, override = {})
    return "" if device.latest_gps_reading.nil? || device.latest_gps_reading.short_address == ', '

    self.class.send(:include, ActionView::Helpers::DateHelper) #for time_ago_in_words
    attributes = {
      :id => device.id,
      :name => device.name,
      :lat => device.latest_gps_reading.latitude,
      :lng => device.latest_gps_reading.longitude,
      :address => device.latest_gps_reading.short_address,
      :dt => time_ago_in_words(device.latest_gps_reading.created_at) + ' ago',
      :note => escape_javascript(device.latest_gps_reading.note),
      :status => latest_status_html(device),
      :direction => device.latest_gps_reading.direction,
      :icon_id => device.icon_id,
      :group_id => device.group_id,
      :geofence => device.latest_gps_reading.fence_description
    }
    
    attributes.update(override)

    "<script>devices.push(#{attributes.to_json});</script>"
  end

  def show_statistics(device)
    # TODO replace with real data
    @stop_total ||= 1
    @idle_total ||= 2.0
    @runtime_total ||= 40.0
    idle_percentage = sprintf("%2.2f",@idle_total/@runtime_total * 100)
    runtime_percentage = sprintf("%2.2f",@runtime_total/(7 * 24) * 100)

    content = ""
    content << %(<tr class="#{cycle('dark_row', 'light_row')}" id="row#{device.id}"> <td>)
    if device.latest_gps_reading
      content << %(<a href="javascript:centerMapOnDevice(#{device.id});highlightRow(#{device.id});" title="Center map on this device" class="link-all1">#{device.name}</a>)
    else
      content << %(#{device.name})
    end
    content << %(</td>
    <td style="font-size:11px;">
      <a href="/reports/all/#{device.id}" title="View device details" class="link-all1">details</a>
    </td>
    <td style="text-align:right;">#{@stop_total}<td style="text-align:right;">#{@idle_total}<td style="text-align:right;">#{idle_percentage}<td style="text-align:right;">#{@runtime_total}<td style="text-align:right;">#{runtime_percentage})

    @stop_total += 1
    @idle_total += 2
    @runtime_total -= 2

    content
  end

  def show_maintenance(device)
    content = ""
    content << %(<tr class="#{cycle('dark_row', 'light_row')}" id="row#{device.id}">)

    if device.latest_gps_reading
      content << %(<td><a href="javascript:centerMapOnDevice(#{device.id});highlightRow(#{device.id});" title="Center map on this device" class="link-all1">#{device.name}</a></td>)
    else
      content << %(<td>#{device.name}</td>)
    end      

    next_task = device.pending_tasks[0]
    if next_task.nil?
      content << %(<td><a title="Add a new maintenance task." href="/maintenance/new/#{device.id}">None</td><td>-</td><td>-</td>)
    else
      content << %(<td><a title="Review maintenance history." href="/reports/maintenance/#{device.id}">#{next_task.description}</td>)

      if next_task.is_runtime?
        remaining_runtime = next_task.target_runtime - next_task.reviewed_runtime
        if remaining_runtime > 0
          content << %(<td>in about #{(remaining_runtime / 60 / 60).round} runtime hours</td>)
        else
          content << %(<td>about #{-(remaining_runtime / 60 / 60).round} runtime hours ago</td>)
        end
      elsif next_task.is_runtime?
        if next_task.target_at > Time.now
          content << %(<td>in #{time_ago_in_words(next_task.target_at)}</td>)
        else
          content << %(<td>#{time_ago_in_words(next_task.target_at)} ago</td>)
        end
      elsif next_task.is_mileage?
        remaining_miles = next_task.target_mileage - device.total_mileage
        if remaining_miles > 0
          content << %(<td>in #{remaining_miles.round(1)} miles</td>)
        else remaining_miles > 0
          content << %(<td>#{-1 * remaining_miles.round(1)} miles ago</td>)
        end
      end
  
      if next_task.pastdue_notified
        content << %(<td style='text-align:center;color:white;background-color:red;'>PAST&nbsp;DUE</td>)
      elsif next_task.reminder_notified
        content << %(<td style='text-align:center;background-color:yellow;'>PENDING</td>)
      else
        content << %(<td style='text-align:center;color:white;background-color:green;'>OK</td>)
      end
    end

    content << %(</tr>)

    content
  end

end
