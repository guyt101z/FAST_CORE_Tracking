function Map(mapEngine, mapControlId)
{
    this.mapEngine = mapEngine;

    if(mapControlId == null)
    {
        mapControlId = 'map';
    }
    this.mapControlId = mapControlId;

    switch(this.mapEngine)
    {
        case "openlayers":
            var mapOptions =
            {
                controls:
                [
                    new OpenLayers.Control.Navigation(),
                    new OpenLayers.Control.PanZoomBar(),
                    new OpenLayers.Control.Attribution(),
                    new OpenLayers.Control.MousePosition(),
                    new OpenLayers.Control.KeyboardDefaults(),
                    new OpenLayers.Control.ScaleLine(),
                    new OpenLayers.Control.LayerSwitcher()
                ],
                projection: new OpenLayers.Projection("EPSG:900913"),
                displayProjection: new OpenLayers.Projection("EPSG:4326"),
                units: "m",
                maxResolution: 156543.0339,
                maxExtent: new OpenLayers.Bounds(-20037508.34, -20037508.34, 20037508.34, 20037508.34)
            };

            this.olMap = new OpenLayers.Map(this.mapControlId, mapOptions);
            this.olMap.mapContainer = this;

            this.olLayerMapnik = new OpenLayers.Layer.OSM.Mapnik("OpenStreetMap (Mapnik)");
            this.olMap.addLayer(this.olLayerMapnik);

            this.olLayerGeofences = new OpenLayers.Layer.Vector("Geofences");
            this.olMap.addLayer(this.olLayerGeofences);

            this.olLayerMarkers = new OpenLayers.Layer.Markers("Devices");
            this.olMap.addLayer(this.olLayerMarkers);
            break;
        case "google":
            if(GBrowserIsCompatible())
            {
                this.gMap = new GMap2(document.getElementById(this.mapControlId));
                this.gMap.mapContainer = this;

                this.gMap.addControl(new GLargeMapControl());
                this.gMap.addControl(new GMapTypeControl());
                this.gMap.enableScrollWheelZoom();
                
                this.gIconAll = new GIcon();
                
                // this.gIconAll.image = "/icons/ublip_marker.png";
                this.gIconAll.shadow = "/images/ublip_marker_shadow.png";
                this.gIconAll.iconSize = new GSize(23, 34);
                this.gIconAll.iconAnchor = new GPoint(11, 34);
                this.gIconAll.infoWindowAnchor = new GPoint(11, 34);
            }
            break;
        default:
            alert("Unable to initialize map. Invalid map engine: " + this.mapEngine);
            return;
            break;
    }
}

Map.prototype.addEventListener = function(eventType, listenerFunction)
{
    switch(eventType)
    {
        case 'bubble_closed':
            switch(this.mapEngine)
            {
                case "openlayers":
                    break;
                case "google":
                    var infoWin = this.gMap.getInfoWindow();
                    GEvent.addListener(infoWin, "closeclick", listenerFunction);
                    break;
            }
            break;
        case 'view_changed':
            switch(this.mapEngine)
            {
                case "openlayers":
                    this.olMap.events.register('moveend', this.olMap, listenerFunction);
                    break;
                case "google":
                    GEvent.addListener(this.gMap, "moveend", listenerFunction);
                    GEvent.addListener(this.gMap, "dragend", listenerFunction);
                    GEvent.addListener(this.gMap, "zoomend", listenerFunction);
                    break;
            }
            break;
        case 'marker_clicked':
            Map.prototype.markerClicked = listenerFunction;
            switch(this.mapEngine)
            {
                case "openlayers":
                    // for openlayers, the listener is defined on the marker
                    break;
                case "google":
                    // for google, the listener for a marker click is defined on the map
                    GEvent.addListener(this.gMap, "click", function(overlay, latLng)
                    {                        
                        if(overlay && overlay instanceof GMarker)
                        {
                            // a marker was clicked, not just a point on the map (they use the same listener)
                            var marker = overlay;

                            // no scope here -- use the marker to get a reference to the map (injected when the marker was created)
                            var map = marker.mapContainer;
                            var point = new LatLon(marker.getLatLng());

                            map.markerClicked(marker.id, point, marker.infoHTML);
                        }
                    });          
                    break;
            }
            break;
        case 'map_clicked':
            Map.prototype.mapClicked = listenerFunction;
            switch(this.mapEngine)
            {
                case "openlayers":
                    this.olMap.events.register("click", this.olMap, function(event)
                    {
                        var map = this.mapContainer;
                        var point = new LatLon(map.olMap.getLonLatFromViewPortPx(event.xy));

                        map.mapClicked(point);
                    });
                    break;
                case "google":
                    GEvent.addListener(this.gMap, "click", function(overlay, latLng)
                    {                        
                        if(latLng)
                        {
                            // no scope here -- use gmap to get a reference to the map (injected when the gmap was created)
                            var map = this.mapContainer;

                            var point = new LatLon(latLng);

                            map.mapClicked(point);
                        }
                    });          
                    break;
            }
            break;
        default:
            alert('Invalid map event type: ' + eventType);
            break;
    }
};

// addEventListener will override this with the passed in function
Map.prototype.markerClicked = function(markerId, point, infoHTML)
{
};

// addEventListener will override this with the passed in function
Map.prototype.mapClicked = function(point)
{
};


Map.prototype.setCenter = function(point, zoom)
{
    switch(this.mapEngine)
    {
        case "openlayers":
            var newCenter = point.toLonLat();
            this.olMap.setCenter(newCenter, zoom);
            break;
        case "google":
            this.gMap.setCenter(point.toGLatLng(), zoom);
            break;
    }
};

Map.prototype.getCenter = function()
{
    switch(this.mapEngine)
    {
        case "google":
            return new LatLon(this.gMap.getCenter());
            break;
        case "openlayers":
            return new LatLon(this.olMap.getCenter());
            break;
    }
};

Map.prototype.panTo = function(point)
{
    switch(this.mapEngine)
    {
        case "openlayers":
            var newCenter = point.toLonLat();
            this.olMap.panTo(newCenter);
            break;
        case "google":
            this.gMap.panTo(point.toGLatLng());
            break;
    }
};

Map.prototype.setZoom = function(zoom)
{
    switch(this.mapEngine)
    {
        case "openlayers":
            this.olMap.zoomTo(zoom);
            break;
        case "google":
            this.gMap.setZoom(zoom);
            break;
    }
};

Map.prototype.getZoom = function()
{
    switch(this.mapEngine)
    {
        case "openlayers":
            return this.olMap.getZoom();
            break;
        case "google":
            return this.gMap.getZoom();
            break;
    }
};

Map.prototype.getBoundsZoomLevel = function(bounds)
{
    switch(this.mapEngine)
    {
        case "openlayers":
            return this.olMap.getZoomForExtent(bounds.toOLBounds());
            break;
        case "google":
            return this.gMap.getBoundsZoomLevel(bounds.toGLatLngBounds());
            break;
    }
};

Map.prototype.showBubble = function(point, html)
{
    switch(this.mapEngine)
    {
        case "openlayers":
            var lonLat = point.toLonLat();

            if(this.olPopup && this.olPopup.blocks != null)
            {
                // old popup exists - we only want one at a time - destory old one.
                this.olPopup.destroy();
            }

            this.olPopup = new OpenLayers.Popup.FramedCloud("device_bubble", lonLat, new OpenLayers.Size(200, 150), html, null, true, function(event)
            {
                map.olPopup.destroy();
                map.bubbleClosed(event);
            });
            this.olMap.addPopup(this.olPopup);
            break;
        case "google":
            this.gMap.openInfoWindowHtml(point.toGLatLng(), html);
            break;
    }
};

Map.prototype.bubbleClosed = function(event)
{
    selectedDeviceId = false;
    if(prevSelectedRow)
    {
        highlightRow(0);
    }
};

Map.prototype.checkResize = function()
{
    switch(this.mapEngine)
    {
        case "openlayers":
            break;
        case "google":
            this.gMap.checkResize();
            break;
    }
};

Map.prototype.addMarker = function(marker)
{
    switch(this.mapEngine)
    {
        case "openlayers":
            this.olLayerMarkers.addMarker(marker);
            break;
        case "google":
            this.gMap.addOverlay(marker);
            break;
    }
};

// create a marker with custom icon and html
Map.prototype.createMarker = function(id, point, iconURL, html)
{
    switch(this.mapEngine)
    {
        case "openlayers":
            var size = new OpenLayers.Size(23, 34);
            var offset = new OpenLayers.Pixel(-(size.w / 2), -size.h);
            var icon = new OpenLayers.Icon(iconURL, size, offset);

            var lonLat = point.toLonLat();

            var marker = new OpenLayers.Marker(lonLat, icon);
            marker.id = id;
            marker.mapContainer = this;
            marker.infoHTML = html;

            // add the event listener to the marker itself for openlayers
            marker.events.register("click", "marker", function(event)
            {
                var marker = event.object;

                // no scope here -- use the event to get a reference to the map
                var map = marker.mapContainer;

                var point = new LatLon(marker.lonlat);

                map.markerClicked(marker.id, point, marker.infoHTML);
            });

            this.olLayerMarkers.addMarker(marker);
            break;
        case "google":
            this.gIconAll.image = iconURL;
            var marker = new GMarker(point.toGLatLng(), this.gIconAll);
            marker.id = id; // Assign a unique id to the marker
            marker.mapContainer = this;
            marker.infoHTML = html;

            // the listener for clicks is defined on the map for google -- see addEventListener function above

            this.gMap.addOverlay(marker);
            break;
    }
};

Map.prototype.clearOverlays = function()
{
    switch(this.mapEngine)
    {
        case "openlayers":
            this.olLayerMarkers.clearMarkers();
            this.olLayerGeofences.destroyFeatures();
            break;
        case "google":
            this.gMap.clearOverlays();
            break;
    }
};

Map.prototype.drawGeofence = function(point, radius)
{
	var cColor = "#0066FF";
	var cWidth = 5;
	var Cradius = radius;   
 	var d2r = Math.PI / 180; 
 	var r2d = 180 / Math.PI; 
 	var Clat = (Cradius / 3963) * r2d; 
	var Clng = Clat / Math.cos(point.lat * d2r); 
	var Cpoints = []; 
	
	for(var i = 0; i < 33; i++)
	{ 
    	var theta = Math.PI * (i / 16); 
    	var CPlng = point.lon + (Clng * Math.cos(theta)); 
    	var CPlat = point.lat + (Clat * Math.sin(theta)); 

    	var P = new LatLon(CPlat, CPlng);

        switch(this.mapEngine)
        {
            case "openlayers":
                Cpoints.push(P.toPoint());
                break;
            case "google":
                Cpoints.push(P.toGLatLng());
                break;
        }
  	}
  
    switch(this.mapEngine)
    {
        case "openlayers":
            this.olLayerGeofences.addFeatures([new OpenLayers.Feature.Vector(new OpenLayers.Geometry.LineString(Cpoints), null, {strokeColor: cColor, strokeWidth: cWidth, strokeOpacity: 0.5})]);
            break;
        case "google":
            this.gMap.addOverlay(new GPolyline(Cpoints, cColor, cWidth)); 
            break;
    }
};
