// generic LatLon class for use with either map type
// constructor takes (lat, lon) or (GLatLng) or (LonLat)
function LatLon(latOrPoint, lonOrNull)
{
    switch(typeof(latOrPoint))
    {
        case "number":
        case "string":
            this.lat = latOrPoint;
            this.lon = lonOrNull;
            break;
        case "object":
            switch(typeof(latOrPoint.lat))
            {
                case "function":
                    // GLatLng
                    this.lat = latOrPoint.lat();
                    this.lon = latOrPoint.lng();
                    break;
                case "number":
                    // LonLat
                    // need to reproject to lat/lon coords (EPSG:4326) since map is spherical mercator (EPSG:900913)
                    var newLonLat = new OpenLayers.LonLat(latOrPoint.lon, latOrPoint.lat);
                    newLonLat.transform(new OpenLayers.Projection(map.olMap.projection), new OpenLayers.Projection("EPSG:4326"));
                    this.lat = newLonLat.lat;
                    this.lon = newLonLat.lon;
                    break;
                default:
                    alert("Unknown input to LatLon constructor");
                    break;
            }
            break;
        default:
            alert(typeof(latOrPoint));
            break;
    }
}

LatLon.prototype.toString = function()
{
    return ("(" + this.lat + ", " + this.lon + ")");
};

LatLon.prototype.toGLatLng = function()
{
    return new GLatLng(this.lat, this.lon);
};

LatLon.prototype.toLonLat = function()
{
    var lonLat = new OpenLayers.LonLat(this.lon, this.lat);
    lonLat.transform(new OpenLayers.Projection("EPSG:4326"), new OpenLayers.Projection(map.olMap.projection));
    return lonLat;
};

LatLon.prototype.toPoint = function()
{
    var lonLat = this.toLonLat();
    var point = new OpenLayers.Geometry.Point(lonLat.lon, lonLat.lat);
    return point;
};
