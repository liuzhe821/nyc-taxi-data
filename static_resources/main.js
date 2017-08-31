let geoJSON; // Global geoJSON variable for easy map repainting
let p_d; // Global variable representing whether pickups (0), dropoffs (1), or imbalance (2) is selected
let dow; // Global variable representing selected day of week (0=all days, 1-7= Mon-Sun)
let data; // Global var representing data matrix holding the geoJSONS

var map = L.map('map').setView([40.75, -73.88], 12);
var colorScheme = ['#ffffb2','#fed976','#feb24c','#fd8d3c','#fc4e2a','#e31a1c','#b10026'];
var colorRamp= ['#FBFCBD', '#FCE3A7', '#FFCD8F', '#FFB57D','#FF9C6B','#FA815F', '#F5695F', '#E85462', '#D6456B', '#C23C76', '#AB337D', '#942B7F', '#802482', '#6A1C80', '#55157D', '#401073', '#291057', '#160D38', '#0A081F', '#000005'];

var imbal = [-5000, -4000, -1000, -500, -250, 0, 250, 500, 1000, 5000, 8000];
var imbalRamp = ['#FF0707', '#FF3838', '#FF6A6A','#FF9B9B', '#FFCDCD', '#FFFFFF', '#D6EAFF', '#ADD6FF','#84C1FF', '#5BADFF', '#3399FF'];


L.tileLayer('https://api.tiles.mapbox.com/v4/{id}/{z}/{x}/{y}.png?access_token=pk.eyJ1IjoibWFwYm94IiwiYSI6ImNpejY4NXVycTA2emYycXBndHRqcmZ3N3gifQ.rJcFIG214AriISLbB6B5aw', {
	maxZoom: 18,
	attribution: 'Map data &copy; <a href="http://openstreetmap.org">OpenStreetMap</a> contributors, ' +
		'<a href="http://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>, ' +
		'Imagery © <a href="http://mapbox.com">Mapbox</a>',
	id: 'mapbox.light'
}).addTo(map);

google.charts.load('current', {packages: ['corechart', 'bar']});
google.charts.setOnLoadCallback(drawChart);


// Format the intraday pickups/dropoffs into a single formatted array for chart creation
function makeRows(arr1, arr2, imbal) {
	let result = [];
	for (i = 0; i<24; i++) {
		if (imbal) {result[i] = [{v: [i,0,0], f: i + ':00'}, arr2[i] - arr1[i]];}
		else { result[i] = [{v: [i,0,0], f: i + ':00'}, arr1[i], arr2[i]]; }
	}
	return result;
}

// Given a div id (elem) and intraday arrays (pickups, dropoffs), draws a Google Chart and 
// places it in the div with the given id. Draws a double column chart with the two data sets.
function drawChart(elem, pickups, dropoffs) {
      var data = new google.visualization.DataTable();
      data.addColumn('timeofday', 'Time of Day');
      data.addColumn('number', 'Pickups');
      data.addColumn('number', 'Dropoffs');

      data.addRows(makeRows(pickups, dropoffs, false));

      var options = {
        title: 'Intraday Pickups/Dropoffs',
        colors: ['#bc84b7', '#70cca8'],
        hAxis: {
          title: 'Time of Day',
          format: 'h:mm a',
          viewWindow: {
            min: [0, 0, 0],
            max: [24, 0, 0]
          },
          textStyle: { fontSize: 8}
        },
        vAxis: { title: 'Average # Trips', textStyle: { fontSize: 8} },
        chartArea: { left: "18%", width: "64%", height: "70%"}, 
        legend: { textStyle: { fontSize: 8  }}
      };

      var container = document.getElementById(elem);
      var chart = new google.visualization.ColumnChart(container);
      chart.draw(data, options);
    }

// Given a div id (elem) and intraday arrays (pickups, dropoffs), draws a Google Chart and 
// places it in the div with the given id. Instead of double data sets, subtracts pickups 
// from dropoffs and graphs this difference.
function drawImbalChart(elem, pickups, dropoffs) {
    var data = new google.visualization.DataTable();
    data.addColumn('timeofday', 'Time of Day');
    data.addColumn('number', 'D-P');

    data.addRows(makeRows(pickups, dropoffs, true));

      var options = {
        title: 'Intraday Trip Imbalance',
        colors: ['#9575cd'],
        hAxis: {
          title: 'Time of Day',
          format: 'h:mm a',
          viewWindow: {
            min: [0, 0, 0],
            max: [24, 0, 0]
          },
          textStyle: { fontSize: 8}
        },
        vAxis: { title: 'Average # Trips', textStyle: { fontSize: 8}  },
        chartArea: { left: "18%", width: "64%", height: "70%"}, 
        legend: { textStyle: { fontSize: 8  }}
      };

      var container = document.getElementById(elem);
      var chart = new google.visualization.ColumnChart(container);
      chart.draw(data, options);
    }

// Code here executes for each NTA when it is clicked. Builds a popup with relevant trip information
// And the onclick function draws a Google Chart, calling drawChart or drawImbalChart, specific to the NTA.
function onEachNeighbor(feature, layer) {
	//let intraday = feature.properties.intraday.split(","); //direct this array into google graphs, expect len 24
	//put the google graphs into the popup.
	let popupId = feature.properties.ntacode;
	let chartId = "chart" + popupId;
	let trips_label = "";

	if (p_d == 0) {
		trips_label += "</h3><p>Pickups: " + feature.properties.pickups;
		trips_label += "</br>Pickups per sqrm: " + feature.properties.pickups_per_sqm;
	} else if (p_d == 1) {
		trips_label += "</h3><p>Dropoffs: " + feature.properties.dropoffs;
		trips_label += "</br>Dropoffs per sqrm: " + feature.properties.dropoffs_per_sqm;
	} else {
		trips_label += "</h3><p>Trip imbalance: " + feature.properties.imbalance;
	}

	let popupContent = "<h3>" +
			feature.properties.ntaname + trips_label + 
			 "<div id=\"" + chartId + "\"></div>" + "</p>" ;

	layer.bindPopup(popupContent, {
		minWidth : 400
	});

	layer.on('click', function(e) {
		if (p_d == 2) {
			drawImbalChart(chartId, feature.properties.intraday_pickups, feature.properties.intraday_dropoffs);
		} else {
			drawChart(chartId, feature.properties.intraday_pickups, feature.properties.intraday_dropoffs);
		}
	})
}

// Given a GeoJSON, paints a new layer on the map according to global state variables
function getJson(fed_data) {
	// Gets geoJSON, assigns to global var geoJSON, adds geoJSON to map
	geoJSON = L.geoJSON(fed_data,{
		style: function(feature){
			let colorFeature;
			if (p_d == 2) { // User has selected imbalance heatmap: Dropoffs - Pickups
				let imbalance = feature.properties.imbalance;
				if (imbalance < imbal[0]) { colorFeature = imbalRamp[0] }
				else if (imbalance < imbal[1]) { colorFeature = imbalRamp[1] }
				else if (imbalance < imbal[2]) { colorFeature = imbalRamp[2] }
				else if (imbalance < imbal[3]) { colorFeature = imbalRamp[3] }
				else if (imbalance < imbal[4]) { colorFeature = imbalRamp[4] }
				else if (imbalance < imbal[5]) { colorFeature = imbalRamp[5] }
				else if (imbalance < imbal[6]) { colorFeature = imbalRamp[6] }
				else if (imbalance < imbal[7]) { colorFeature = imbalRamp[7] }
				else if (imbalance < imbal[8]) { colorFeature = imbalRamp[8] }
				else if (imbalance < imbal[9]) { colorFeature = imbalRamp[9] }
				else { colorFeature = imbalRamp[10] };

			} else { // User has selected pickup or dropoff heatmap: Dropoffs - Pickups
				if (p_d == 0) {
					var trips_per_sqm_k = feature.properties.pickups_per_sqm/1000;
					var trips_per_sqm = feature.properties.pickups_per_sqm;
				} else {
					var trips_per_sqm_k = feature.properties.dropoffs_per_sqm/1000;
					var trips_per_sqm = feature.properties.dropoffs_per_sqm;
				}

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
				else { colorFeature = colorRamp[0] };
			}
			return {color: colorFeature, weight: 1, fillOpacity: 0.5}
		},
		onEachFeature: onEachNeighbor
	});
	geoJSON.addTo(map);
}

// Removes the old GeoJSON layer and adds a new one by calling getJon
function updateMap() {
	map.removeLayer(geoJSON);
	getJson(data[dow])
}

$(document).ready(function() { 
	// Initial map condition is set to pickups, all days
	// Global variables are initialized here
	p_d = 0;
	dow = 0;

	getJson(overall_data);
	drawChart("overall-graph", all_city_p, all_city_d);

	data = [overall_data, mon_data, tue_data, wed_data, thu_data, fri_data, sat_data, sun_data];

	// Event listeners for dropdown changes. If change, calls updateMap()
	$("#dropdown").change(function () {
		p_d = $("#dropdown").val();
		updateMap();
		if (p_d == 2) {
			drawImbalChart("overall-graph", city_graph[0][dow], city_graph[1][dow]);
		} else {
			drawChart("overall-graph", city_graph[0][dow], city_graph[1][dow])
		}
	});

	$("#dow-dropdown").change(function () {
		dow = $("#dow-dropdown").val();
		updateMap();
		if (p_d == 2) {
			drawImbalChart("overall-graph", city_graph[0][dow], city_graph[1][dow]);
		} else {
			drawChart("overall-graph", city_graph[0][dow], city_graph[1][dow])
		}
	});

	// Overall chart button click listener to hide and show the overall chart
	$("#og-button").click(function() {
        if($(this).hasClass("clicked")){
            $(this).removeClass("clicked");
            $("#overall-graph").animate({bottom: "0px"});
            $("#og-button").animate({bottom: "245px"});
            $("#button-icon").html("keyboard_arrow_down");
        }else{
            $(this).addClass("clicked");
            $("#overall-graph").animate({bottom: "-269px"});
            $("#og-button").animate({bottom: "35px"});
            $("#button-icon").html("keyboard_arrow_up");
        }
        
    });

	// Resize listener so map resizes proportionally to window
    $(window).on("resize", function () { $("#map").height($(window).height() - 80); map.invalidateSize(); }).trigger("resize");

});
