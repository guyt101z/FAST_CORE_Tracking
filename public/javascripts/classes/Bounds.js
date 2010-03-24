function Bounds()
{
    this.topRight = new LatLon(-90, -180);
    this.bottomLeft = new LatLon(90, 180);
}

Bounds.prototype.toString = function()
{
    return ("(" + this.topRight.toString() + ", " + this.bottomLeft.toString() + ")");
};

Bounds.prototype.extend = function(latLon)
{
    this.topRight.lat = Math.max(this.topRight.lat, latLon.lat);
    this.topRight.lon = Math.max(this.topRight.lon, latLon.lon);
    this.bottomLeft.lat = Math.min(this.bottomLeft.lat, latLon.lat);
    this.bottomLeft.lon = Math.min(this.bottomLeft.lon, latLon.lon);
};

Bounds.prototype.toGLatLngBounds = function()
{
    return new GLatLngBounds(this.bottomLeft.toGLatLng(), this.topRight.toGLatLng());
};

Bounds.prototype.toOLBounds = function()
{
    var topRightLonLat = this.topRight.toLonLat();
    var bottomLeftLonLat = this.bottomLeft.toLonLat();

    return new OpenLayers.Bounds(bottomLeftLonLat.lon, bottomLeftLonLat.lat, topRightLonLat.lon, topRightLonLat.lat);
};

Bounds.prototype.getCenter = function()
{
    var lat = (this.topRight.lat + this.bottomLeft.lat) / 2;
    var lon = (this.topRight.lon + this.bottomLeft.lon) / 2;

    return new LatLon(lat, lon);
};
