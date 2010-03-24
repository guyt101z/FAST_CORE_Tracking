var zoom = 3;
var iconURL = "/icons/ublip_marker.png";
var form;
var geofences = [];
var currSelectedDeviceId;
var currSelectedGeofenceId;
var gf_index;

var map;

function loadMap(mapEngine, mapDiv)
{
    map = new Map(mapEngine, mapDiv);

    map.setCenter(new LatLon(37.0625, -95.677068), zoom);
		
    // Form when editing or adding geofence
    form = document.getElementById("geofence_form");

    if(remove_listener == 'false')
    { //added
        map.addEventListener('map_clicked', function(point)
        {
            document.getElementById('address').value = point.lat + ',' + point.lon;

            var r = document.getElementById("radius")[document.getElementById("radius").selectedIndex].value;

            map.clearOverlays();
            map.drawGeofence(point, r);
            setZoomFromRadius(r);
            map.setZoom(zoom);
            map.panTo(point);
        });
    }

    //displayGeofence(0);
    if(device_flag == 1)
    {
        displayGeofence(gf_index);                
        currSelectedGeofenceId = geofences[0].id;
        var point = new LatLon(device.lat, device.lng);
        map.createMarker(currSelectedGeofenceId, point, iconURL);
    }
}

// Convert address to lat/lng
function geocode(address)
{
	var geocoder = new GClientGeocoder();
	geocoder.getLatLng
    (
    	address,
		function(point)
        {
      		if(!point)
            {
        		alert("We're sorry, this address cannot be located");
      		}
            else
            {
                // convert to our generic point class
                point = new LatLon(point);

				map.clearOverlays();
				// Draw the fence
				var r = document.getElementById("radius")[document.getElementById("radius").selectedIndex].value;
				map.drawGeofence(point, r);
				setZoomFromRadius(r);
				map.setZoom(zoom);
                map.panTo(point);

				// Populate the bounds field
				form.bounds.value = point.lat + ',' + point.lon + ',' + r;            

				// Display the last location for the device                
                if(device != 'false')
                {
				    var devicePoint = new LatLon(device.lat, device.lng);
				    map.createMarker(devicePoint, point, iconURL);  
                }
      		}
    	}
  	);
}

function setZoomFromRadius(r)
{
    if(parseInt(r) > 25)
    {
        zoom = 5;
    }
    else if(parseInt(r) > 5)
    {
        zoom = 7;
    }
    else if(parseInt(r) >= 1)
    {
        zoom = 10;
    }
    else
    {
        zoom = 14;
    }
}

// Validation for geofence creation form
function validate()
{
    form = document.getElementById('geofence_form');  
	if(form.name.value == '')
    {
		alert('Please specify a name for your geofence');
		return false;	
	}
	
	if(form.bounds.value == '')
    {
		alert('Please preview your geofence before saving');
		return false;
	}
	
	return true;
}


// Display a geofence when selected from the view list
function displayGeofence(index)
{  
	var bounds = geofences[index].bounds.split(",");    
	var point = new LatLon(parseFloat(bounds[0]), parseFloat(bounds[1]));    
	var radius = parseFloat(bounds[2]);
	map.clearOverlays();
	map.drawGeofence(point, radius);
	currSelectedGeofenceId = geofences[index].id;
	
	if(radius > 1)
    {
		zoom = 9;
    }
	else
    {
		zoom = 14;
    }
	
	map.setCenter(point, zoom);
}

function go(url)
{
	document.location.href = url + '?geofence_id=' + currSelectedGeofenceId;
}

function enableDevice(id)
{
	if(document.getElementById("all").value == '1' && document.getElementById("all").checked == true)
    {
		document.getElementById("device").disabled = true;
	}
    else
    {         
		document.getElementById("device").disabled = false;
	}
}
