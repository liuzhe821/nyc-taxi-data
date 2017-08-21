let geoJSON; // Global geoJSON variable for easy map repainting
let p_d; // Global variable representing whether pickups or dropoffs is selected
let dow; // Global variable representing selected day of week
let data; // Global var representing data matrix

var map = L.map('map').setView([40.75, -73.88], 12);
var colorScheme = ['#ffffb2','#fed976','#feb24c','#fd8d3c','#fc4e2a','#e31a1c','#b10026'];
var colorRamp= ['#FBFCBD', '#FCE3A7', '#FFCD8F', '#FFB57D','#FF9C6B','#FA815F', '#F5695F', '#E85462', '#D6456B', '#C23C76', '#AB337D', '#942B7F', '#802482', '#6A1C80', '#55157D', '#401073', '#291057', '#160D38', '#0A081F', '#000005'];


L.tileLayer('https://api.tiles.mapbox.com/v4/{id}/{z}/{x}/{y}.png?access_token=pk.eyJ1IjoibWFwYm94IiwiYSI6ImNpejY4NXVycTA2emYycXBndHRqcmZ3N3gifQ.rJcFIG214AriISLbB6B5aw', {
	maxZoom: 18,
	attribution: 'Map data &copy; <a href="http://openstreetmap.org">OpenStreetMap</a> contributors, ' +
		'<a href="http://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>, ' +
		'Imagery © <a href="http://mapbox.com">Mapbox</a>',
	id: 'mapbox.light'
}).addTo(map);


function onEachNeighbor(feature, layer) {
	var popupContent = "<h3>" +
			feature.properties.ntaname + "</h3><p>Trips: " +
			feature.properties.trips + "</br>Trips per sqrm: " +
			feature.properties.trips_per_sqm + "</p>" ;
	layer.bindPopup(popupContent);
}


function getJson(data) {
	// Gets geoJSON, assigns to global var geoJSON, adds geoJSON to map
	geoJSON = L.geoJSON(data,{
		style: function(feature){
			var trips_per_sqm_k = feature.properties.trips_per_sqm/1000;
			var trips_per_sqm = feature.properties.trips_per_sqm;
			var colorFeature;

			if (trips_per_sqm >= 50000) { colorFeature = colorRamp[14] }
			else if (trips_per_sqm >= 10000) { colorFeature = colorRamp[Math.floor(trips_per_sqm/10000)+9] }
			else if (trips_per_sqm >= 5000) { colorFeature = colorRamp[9] }
			else if (trips_per_sqm >= 2000) { colorFeature = colorRamp[8] }
			else if (trips_per_sqm >= 1000) { colorFeature = colorRamp[7] }
			else if (trips_per_sqm >= 500) { colorFeature = colorRamp[6] }
			else if (trips_per_sqm >= 250) { colorFeature = colorRamp[5] }
			else if (trips_per_sqm >= 100) { colorFeature = colorRamp[4] }
			else if (trips_per_sqm >= 50) { colorFeature = colorRamp[3] }
			else if (trips_per_sqm >= 25) { colorFeature = colorRamp[2] }
			else if (trips_per_sqm >= 10) { colorFeature = colorRamp[1] }
			else { colorFeature = colorRamp[0] }
			return {color: colorFeature, weight: 1, fillOpacity: 0.5}
		},
		onEachFeature: onEachNeighbor
	});
	geoJSON.addTo(map);
}


function updateMap() {
	// Removes old geoJSON layer and adds a new one by calling getJSON
	map.removeLayer(geoJSON);
	getJson(data[p_d][dow])
}


$(document).ready(function() { 
	// Initial map condition is set to pickups, all days
	p_d = 0;
	dow = 0;
	getJson(daily_pickups);

	// 2d array holding all static GeoJSONs for easy access
	data = [
		[daily_pickups, mon_pickups, tue_pickups, wed_pickups, thu_pickups, fri_pickups, sat_pickups, sun_pickups],
		[daily_dropoffs, mon_dropoffs, tue_dropoffs, wed_dropoffs, thu_dropoffs, fri_dropoffs, sat_dropoffs, sun_dropoffs]
	];

	// Event listener for dropdown changes. If change, calls updateMap()
	$("#dropdown").change(function () {
		p_d = $("#dropdown").val();
		updateMap();
	});

	$("#dow-dropdown").change(function () {
		dow = $("#dow-dropdown").val();
		updateMap();
	});
});
