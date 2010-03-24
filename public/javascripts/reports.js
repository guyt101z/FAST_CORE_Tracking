// Switch between devices on reports view but keep the timeframe, if it exists
function changeDevice(device_id, report_type, start_date, end_date)
{
	var url = '/reports/' + report_type + '/' + device_id;
	
    url += "?end_date=" + end_date + "&start_date=" + start_date;	
     
	document.location.href = url;
}

function displayTripOverview(trip_id, marker)
{	
	// Handle the initial display of the map with the first trip
	if(trip_id == undefined)
    {
		trip_id = readings[0].id;
    }

	map.clearOverlays();
	
	highlightRow(trip_id);
	
	var bounds = new Bounds();

	var count = 0; // Use count to limit looping. Just grab the start/stop address for the trip and stop looping
	for(i = 0; i < readings.length && count <= 1; i++)
    {
		var reading = readings[i];
		var point = new LatLon(reading.lat, reading.lng);
		if(reading.id == trip_id)
        {
			if(reading.start)
            {
                map.createMarker(trip_id, point, getBreadcrumbMarkerImageURL(count, reading), createTripHTML(reading));
				bounds.extend(point);

				count++;
			}
            else if(reading.stop)
            {
				map.createMarker(trip_id, point, getBreadcrumbMarkerImageURL(count, reading), createTripHTML(reading));
				bounds.extend(point);

				count++;
			}
		}
	}
	
	map.setCenter(bounds.getCenter(), (map.getBoundsZoomLevel(bounds) - 1));
}

// Create html for selected reading
function createTripHTML(reading)
{
	var html = '<div class="dark_grey"><span class="blue_bold">' + reading.address + '<br />' + reading.dt + '</span><br />';
	html += '<br /><a href="/reports/trip_detail/' + reading.id + '">View trip details</a>'
	return html;
}
