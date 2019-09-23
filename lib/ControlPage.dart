import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'OneTimeLocation.dart';

class ControlPage extends StatefulWidget {
  @override
  _ControlPageState createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> {
  static var latLong;
  //maps
  static final CameraPosition _kInitialPosition = const CameraPosition(
    target: LatLng(-33.852, 151.211),
    zoom: 11.0,
  );

  CameraPosition _position = _kInitialPosition;
  bool _isMapCreated = false;
  bool _compassEnabled = true;
  bool _mapToolbarEnabled = true;
  CameraTargetBounds _cameraTargetBounds = CameraTargetBounds.unbounded;
  MinMaxZoomPreference _minMaxZoomPreference = MinMaxZoomPreference.unbounded;
  MapType _mapType = MapType.normal;
  bool _rotateGesturesEnabled = true;
  bool _scrollGesturesEnabled = true;
  bool _tiltGesturesEnabled = true;
  bool _zoomGesturesEnabled = true;
  bool _indoorViewEnabled = true;
  bool _myLocationEnabled = true;
  bool _myLocationButtonEnabled = true;
  GoogleMapController _controller;
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};

  void onMapCreated(GoogleMapController controller) {
    setState(() {
      _controller = controller;
      _isMapCreated = true;
    });
  }

  void _updateCameraPosition(CameraPosition position) {
    setState(() {
      _position = position;
    });
  }
  // end of fns, vars for google maps
  @override
  void initState() {
    super.initState();
    getcurrentLoc();
  }

  void getcurrentLoc() async {
    var otl = OneTimeLocation();
    var currentLatLong = await otl.getCurrentLocation();
    setState(() {
      latLong = currentLatLong;
    });
    //move camera
    _controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(
        bearing: 270.0,
        target: LatLng(latLong[0], latLong[1]),
        tilt: 30.0,
        zoom: 17.0,
      ),
    ));
    //place marker
    setState(() {
      markers[MarkerId('0')] = Marker(markerId:MarkerId('0'), position: LatLng(latLong[0], latLong[1]));
    });

    print("recieved coordinates: ${latLong[0]}, ${latLong[1]}");
  }

  Widget identityWidget(String name) {
    return RaisedButton(
      child: Text(name),
      onPressed: null,
      shape: RoundedRectangleBorder(
        borderRadius: new BorderRadius.circular(30.0),
      ),
      disabledColor: Colors.green,
      disabledTextColor: Colors.white,
    );
    // return Text("hi");
  }

  Widget latLongWidget() {
    if (latLong == null) {
      return Column(
        children: <Widget>[
          Text("Waiting for location:"),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () async {
              getcurrentLoc();
            },
          )
        ],
      );
    } else {
      return Text("Your location ${latLong[0]}, ${latLong[1]}");
    }
  }

  Widget toggleLight(){
    
  }

  @override
  Widget build(BuildContext context) {
    final GoogleMap googleMap = GoogleMap(
      onMapCreated: onMapCreated,
      initialCameraPosition: _kInitialPosition,
      compassEnabled: _compassEnabled,
      mapToolbarEnabled: _mapToolbarEnabled,
      cameraTargetBounds: _cameraTargetBounds,
      minMaxZoomPreference: _minMaxZoomPreference,
      mapType: _mapType,
      rotateGesturesEnabled: _rotateGesturesEnabled,
      scrollGesturesEnabled: _scrollGesturesEnabled,
      tiltGesturesEnabled: _tiltGesturesEnabled,
      zoomGesturesEnabled: _zoomGesturesEnabled,
      indoorViewEnabled: _indoorViewEnabled,
      myLocationEnabled: _myLocationEnabled,
      myLocationButtonEnabled: _myLocationButtonEnabled,
      onCameraMove: _updateCameraPosition,
      markers: Set<Marker>.of(markers.values),
    );

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            identityWidget("Facility Manager"),
            latLongWidget(),
            SizedBox(
              width: 300.0,
              height: 200.0,
              child: googleMap,
            ),
          ],
        ),
      ),
    );
  }
}
