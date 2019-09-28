import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'OneTimeLocation.dart';

import "package:firebase_database/firebase_database.dart";

final databaseReference = FirebaseDatabase.instance.reference();

void hopsitalLockSend() {
  print("HOSPITAL LOCKING");
  databaseReference.child("BINID_66716").set({
    'weight': '223.89',//Arduino
    'volume': '25000.00',//Arduino
    'source_id': '12324',//App auth
    'destination_id': '97820',//Entered in App
    'geo_fence_loc': {'x': '12.98', 'y': '89.01'},//From App
    'geo_fence_radius': '5.00'//Default
  });
}

void hopsitalUnlockSend() {
  print("HOSPITAL UNOCKING");
  databaseReference.child("BINID_66716").set({
    'weight': 'null',
    'volume': 'null',
    'source_id': 'null',
    'destination_id': 'null',
    'geo_fence_loc': 'null',
    'geo_fence_radius': 'null'
  });
}

void facilityLockSend() {
  print("FACILITY LOCKING");
  databaseReference.child("BINID_66716").set({
    'weight': 'null',
    'volume': 'null',
    'source_id': 'null',
    'destination_id': 'null',
    'geo_fence_loc': 'null',
    'geo_fence_radius': 'null'
  });
}

void facilityUnlockSend() {
  print("FACILITY UNLOCKING");
  databaseReference.child("BINID_66716").set({
    'weight': '223.89',//Arduino
    'volume': '25000.00',//Arduino
    'source_id': '12324',//Arduino
    'destination_id': '97820',//Arduino
    'geo_fence_loc': {'x': '12.98', 'y': '89.01'},//Arduino
    'geo_fence_radius': '5.00'//Default
  });
}

class ControlPage extends StatefulWidget {
  final BluetoothDevice server;
  final String deviceAddress;

  const ControlPage({this.server, this.deviceAddress});

  @override
  _ControlPageState createState() => _ControlPageState();
}

class _Message {
  int whom;
  String text;

  _Message(this.whom, this.text);
}

class _ControlPageState extends State<ControlPage> {
  static var latLong =[-33.852, 151.211];
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
  //for bluetooth communication
  static final clientID = 0;
  static final maxMessageLength = 4096 - 3;
  BluetoothConnection connection;
  bool isConnecting = true;
  bool get isConnected => connection != null && connection.isConnected;
  bool isDisconnecting = false;
  List<_Message> messages = List<_Message>();
  String _messageBuffer = '';

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

  @override
  void initState() {
    super.initState();
    //set up the bluetooth connection
    BluetoothConnection.toAddress(widget.bserver.address).then((_connection) {
      print('Connected to the device');
      connection = _connection;
      setState(() {
        isConnecting = false;
        isDisconnecting = false;
      });

      connection.input.listen(_onDataReceived).onDone(() {
        if (isDisconnecting) {
          print('Disconnecting locally!');
        } else {
          print('Disconnected remotely!');
        }
        if (this.mounted) {
          setState(() {});
        }
      });
    }).catchError((error) {
      print('Cannot connect, exception occured');
      print(error);
    });
    //Passing the device address to arduino for verification
    // _sendMessage(widget.deviceAddress); // problem: at this stage, bluetooth is not connected. wait for isconnected maybe?
    getcurrentLoc();
  }

  @override
  void dispose() {
    // Avoid memory leak (`setState` after dispose) and disconnect
    if (isConnected) {
      isDisconnecting = true;
      connection.dispose();
      connection = null;
    }

    super.dispose();
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
      markers[MarkerId('0')] = Marker(
          markerId: MarkerId('0'), position: LatLng(latLong[0], latLong[1]));
    });

    print("recieved coordinates: ${latLong[0]}, ${latLong[1]}");
  }

  Widget identityWidget(String name,
      {Color backColor = Colors.green, Color textColor = Colors.white}) {
    return RaisedButton(
      child: Text(
        name,
        style: TextStyle(fontSize: 12),
      ),
      onPressed: null,
      shape: RoundedRectangleBorder(
        borderRadius: new BorderRadius.circular(30.0),
      ),
      disabledColor: backColor,
      disabledTextColor: textColor,
    );
    // return Text("hi");
  }

  Widget latLongWidget() {
    if (latLong == null) {
      return Row(
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

  var toggle = 1;
  Widget toggleLight() {
    // assign the actual function if it is connected
    var function = isConnecting
        ? null
        : isConnected
            ? () {
                if (toggle == 1) {
                  _sendMessage("1");
                  toggle = 0;
                } else {
                  _sendMessage("0");
                  toggle = 1;
                }
              }
            : null;

    return RaisedButton(
      child: Text("Toggle light"),
      onPressed: function,
    );
  }

  Widget subActionBoard(
      String action1, action2, var onPressAction1, onPressAction2,
      {var optionalDescr = false}) {
    double width = MediaQuery.of(context).size.width;
    return Card(
      child: Container(
        padding: EdgeInsets.all(5.0),
        width: width / 2 - 10, // 10px less than device width
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            optionalDescr
                ? identityWidget("Geofence")
                : identityWidget("Unlocking", backColor: Colors.teal),
            RaisedButton(
              padding: EdgeInsets.all(10),
              child: Text(
                action1,
                overflow: TextOverflow.ellipsis,
                maxLines: 3,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: new BorderRadius.circular(10.0),
              ),
              onPressed: onPressAction1,
            ),
            RaisedButton(
              padding: EdgeInsets.all(10),
              child: Text(
                action2,
                overflow: TextOverflow.ellipsis,
                maxLines: 3,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: new BorderRadius.circular(10.0),
              ),
              onPressed: onPressAction2,
            ),
            RaisedButton(
                child: Text(
                  "Send to DB",
                  overflow: TextOverflow.ellipsis,
                  maxLines: 3,
                ),
              onPressed: (){
                print("CREATING RECORD");
                hopsitalLockSend();//DEBUG
              }
            )
          ],
        ),
      ),
    );
  }

  Widget actionBoard() {
    int facilityID = 0,
        transporterID = 0,
        hospitalID = 0; //TODO: id just identifies phone
    int nextTransporterId = 5; //TODO: get this from firebase
    var sampleGeofence = [
      latLong[0], //x
      latLong[1], //y
      30 // radius
    ]; //TODO: get this from firebase

    var hospitalLock = isConnecting
        ? null
        : isConnected
            ? () async {
                //hospital locks and sets geofence
                hopsitalLockSend();
                await _sendMessage(
                    "FLOCK#${0}_${latLong[0]}_${latLong[1]}_${sampleGeofence[0]}_${sampleGeofence[1]}_${sampleGeofence[2]}_${facilityID}");
                // TODO get volume and weight from arduino, upload to firebase
                // await _sendMessage("distance");
                var L = await _mostRecentArduinoMessages();
                L.forEach((element) => print(element.text));
                print("in here");
              }
            : null;
    var hospitalUnlock = isConnecting
        ? null
        : isConnected
            ? () async {
                hopsitalUnlockSend();
                //hospital unlocks and verifies it's position
                await _sendMessage("FUNLOCK#${0}_${latLong[0]}_${latLong[1]}");
                //nothing happens here, as bin is empty when it comes back to hospital
              }
            : null;
    var facilityLock = isConnecting
        ? null
        : isConnected
            ? () async {
                //hospital locks and sets geofence
                facilityLockSend();
                await _sendMessage(
                    "FLOCK#${0}_${latLong[0]}_${latLong[1]}_${sampleGeofence[0]}_${sampleGeofence[1]}_${sampleGeofence[2]}_${hospitalID}");
                //nothing happens here as they will send back an empty bin, unless it's a midway stop in some other facility
                // TODO : should we check for midway stops or just do nothing here?
              }
            : null;
    var facilityUnlock = isConnecting
        ? null
        : isConnected
            ? () async {
      facilityUnlockSend();
                //facility unlocks and verifies it's position
                await _sendMessage("FUNLOCK#${0}_${latLong[0]}_${latLong[1]}");
                //TODO : get weight, vol from arduino. get previous weight, vol from firebase. compare the two and allow some error margin
              }
            : null;
    var transporterUnlock = isConnecting
        ? null
        : isConnected
            ? () async {
                //facility unlocks and verifies it's position
                await _sendMessage("TUNLOCK#${0}_${latLong[0]}_${latLong[1]}");
                //TODO : get weight, vol from arduino. get previous weight, vol from firebase. compare the two and allow some error margin
              }
            : null;
    var transporterLock = isConnecting
        ? null
        : isConnected
            ? () async {
                //facility unlocks and verifies it's position
                _sendMessage("TLOCK#${0}_${latLong[0]}_${latLong[1]}");
                //TODO : get weight, vol from arduino. get previous weight, vol from firebase. compare the two and allow some error margin
              }
            : null;

    return Container(
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              subActionBoard("Hospital lock", "Transport lock", hospitalLock,
                  transporterLock,
                  optionalDescr: true),
              subActionBoard("Facility unlock", "Transport unlock",
                  facilityUnlock, transporterUnlock),
            ],
          ),
          Row(
            children: <Widget>[
              subActionBoard("Facility lock", "Transport lock", facilityLock,
                  transporterLock,
                  optionalDescr: true),
              subActionBoard("Hospital unlock", "Transport unlock",
                  hospitalUnlock, transporterUnlock),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final GoogleMap googleMap = GoogleMap(
      onMapCreated: onMapCreated,
      initialCameraPosition: _kInitialPosition,
      compassEnabled: _compassEnabled,
      //mapToolbarEnabled: _mapToolbarEnabled,
      cameraTargetBounds: _cameraTargetBounds,
      minMaxZoomPreference: _minMaxZoomPreference,
      mapType: _mapType,
      rotateGesturesEnabled: _rotateGesturesEnabled,
      scrollGesturesEnabled: _scrollGesturesEnabled,
      tiltGesturesEnabled: _tiltGesturesEnabled,
      zoomGesturesEnabled: _zoomGesturesEnabled,
      //indoorViewEnabled: _indoorViewEnabled,
      myLocationEnabled: _myLocationEnabled,
      myLocationButtonEnabled: _myLocationButtonEnabled,
      onCameraMove: _updateCameraPosition,
      markers: Set<Marker>.of(markers.values),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text("Control Page"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // identityWidget("Facility Manager"),
            latLongWidget(),
            SizedBox(
              width: 300.0,
              height: 200.0,
              child: googleMap,
            ),
            // toggleLight()
            actionBoard(),
          ],
        ),
      ),
    );
  }

  _mostRecentArduinoMessages() async {
    var _recentMessages = () {
      List<_Message> newArduinoMessages = [];
      for (int i = messages.length - 1; i >= 0; i--) {
        var item = messages[i];
        if (item.whom != 1) {
          break;
        }
        item.text = item.text.trim();
        newArduinoMessages.insert(0, item);
      }
      return newArduinoMessages;
    };
    var L;
    await Future.delayed(const Duration(milliseconds: 2000), () {
      //TODO: tweak the delay if input takes too much time
      L = _recentMessages();
    });
    return (L);
  }

  void _onDataReceived(Uint8List data) {
    // Allocate buffer for parsed data
    int backspacesCounter = 0;
    data.forEach((byte) {
      if (byte == 8 || byte == 127) {
        backspacesCounter++;
      }
    });
    Uint8List buffer = Uint8List(data.length - backspacesCounter);
    int bufferIndex = buffer.length;

    // Apply backspace control character
    backspacesCounter = 0;
    for (int i = data.length - 1; i >= 0; i--) {
      if (data[i] == 8 || data[i] == 127) {
        backspacesCounter++;
      } else {
        if (backspacesCounter > 0) {
          backspacesCounter--;
        } else {
          buffer[--bufferIndex] = data[i];
        }
      }
    }

    // Create message if there is new line character
    String dataString = String.fromCharCodes(buffer);
    int index = buffer.indexOf(13);
    if (~index != 0) {
      // \r\n
      setState(() {
        messages.add(_Message(
            1,
            backspacesCounter > 0
                ? _messageBuffer.substring(
                    0, _messageBuffer.length - backspacesCounter)
                : _messageBuffer + dataString.substring(0, index)));
        _messageBuffer = dataString.substring(index);
      });
    } else {
      _messageBuffer = (backspacesCounter > 0
          ? _messageBuffer.substring(
              0, _messageBuffer.length - backspacesCounter)
          : _messageBuffer + dataString);
    }
  }

  void _sendMessage(String text) async {
    text = text.trim();
    // textEditingController.clear();

    if (text.length > 0) {
      try {
        connection.output.add(utf8.encode(text + "\r\n"));
        await connection.output.allSent;

        setState(() {
          messages.add(_Message(clientID, text));
          print("Sending $text, clientId is $clientID");
        });

        // Future.delayed(Duration(milliseconds: 333)).then((_) {
        //   listScrollController.animateTo(listScrollController.position.maxScrollExtent, duration: Duration(milliseconds: 333), curve: Curves.easeOut);
        // });
      } catch (e) {
        // Ignore error, but notify state
        setState(() {});
      }
    }
  }
}
