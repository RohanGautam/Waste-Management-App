import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'AfterLockReport.dart';
import 'OneTimeLocation.dart';
import "package:firebase_database/firebase_database.dart";
var firebaseCounter=0; // incrementing this after each firebase upload, so the binID is unique every time.
final databaseReference = FirebaseDatabase.instance.reference();
//this is a function, with optional parameters which have default values. In this hackathon, this is so that even if we didn't recieve proper data, we could still get some believable output. Bad practice :( but it be like that sometimes
void hospitalLockSend({weight='223.89', volume = '25000.00', tId='123432', sId='12321', dID = '97820', gf_x ='12.98', gf_y = '89.01', gf_rad = '5.00'}) async {
  print("HOSPITAL LOCKING");
  databaseReference.child('BIN_STATUS').child("ON_JOB").child("BINID_667_${firebaseCounter}").update({
    'weight': '$weight',//Arduino
    'volume': '$volume',//Arduino
    'transporter_id': '$tId',//OwnerID from Arduino
    'source_id': '$sId',//App auth
    'destination_id': '$dID',//Entered in App
    'geo_fence_loc': {'x': '$gf_x', 'y': '$gf_y'},//From App
    'geo_fence_radius': '$gf_rad'//Default
  });
  firebaseCounter+=1;
}

void hospitalUnlockSend() {
  print("HOSPITAL UNLOCKING");
  databaseReference.child('BIN_STATUS').child("ON_JOB").child("BINID_667_${firebaseCounter}").update({
    'weight': 'null',//Arduino
    'volume': 'null',//Arduino
    'transporter_id': 'null',
    'source_id': 'null',//Arduino
    'destination_id': 'null',//Arduino
    'geo_fence_loc': 'null',//Arduino
    'geo_fence_radius': 'null'//Default
  });
  firebaseCounter+=1;
}

void facilityLockSend({tId='123432'}) {
  print("FACILITY LOCKING");
  databaseReference.child('BIN_STATUS').child("ON_JOB").child("BINID_667_${firebaseCounter}").update({
    'weight': 'null',//Arduino
    'volume': 'null',//Arduino
    'transporter_id': '$tId',//Arduino
    'source_id': 'null',//Arduino
    'destination_id': 'null',//Arduino
    'geo_fence_loc': 'null',//Arduino
    'geo_fence_radius': 'null'//Default
  });
  firebaseCounter+=1;
}

void facilityUnlockSend({weight='223.89', volume = '25000.00', tId='123432', sId='12321', dID = '97820', gf_x ='12.98', gf_y = '89.01', gf_rad = '5.00'}) {
  print("FACILITY UNLOCKING");
  databaseReference.child('BIN_STATUS').child("EMPTY").child("BINID_667_${firebaseCounter}").update({
    'weight': '$weight',//Arduino
    'volume': '$volume',//Arduino
    'transporter_id': '$tId',//OwnerID from Arduino
    'source_id': '$sId',//App auth
    'destination_id': '$dID',//Entered in App
    'geo_fence_loc': {'x': '$gf_x', 'y': '$gf_y'},//From App
    'geo_fence_radius': '$gf_rad'//Default
  });
  firebaseCounter+=1;
}


class ControlPage extends StatefulWidget {
  final BluetoothDevice server;
  final String deviceAddress;
  String persona = "hospital";

  ControlPage({this.server, this.deviceAddress, this.persona});

  @override
  _ControlPageState createState() => _ControlPageState();
}

class _Message {
  int whom;
  String text;

  _Message(this.whom, this.text);
}

class _ControlPageState extends State<ControlPage> {
  static var latLong = [-33.852, 151.211];
  //maps
  static final CameraPosition _kInitialPosition = const CameraPosition(
    target: LatLng(-33.852, 151.211), //default location on map render is in australia
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
    BluetoothConnection.toAddress(widget.server.address).then((_connection) {
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

  Widget customButton(String name,
      {Color backColor = Colors.green,
      Color textColor = Colors.white,
      var func = null}) {
    return RaisedButton(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          name,
          style: TextStyle(fontSize: 25),
        ),
      ),
      onPressed: func,
      shape: RoundedRectangleBorder(
        borderRadius: new BorderRadius.circular(30.0),
      ),
      color: backColor,
      textColor: textColor,
    );
  }

  Widget putInWastePrompt() {
    if (widget.persona == "hospital") {
      return Text(
        "Put in the Waste 🤖",
        style: TextStyle(fontSize: 30),
      );
    } else {
      return Container();
    }
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
      setState(() {});
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

 
  static List<String> options = [
    "Location 1",
    "Location 2",
    "Location 3",
  ];

  var optionLocations = [
    LatLng(12.8915799, 80.2322393),
    LatLng(12.7915799, 80.2322393),
    LatLng(12.6915799, 80.2322393),
  ];

  var _dropdownvalue = options[0];
  Widget dropDownWidget() {
    //when the dropdown widget is being built, add the markers of the locations too
    setState(() {
      for (int i = 0; i < optionLocations.length; i++) {
        var option = optionLocations[i];
        markers[MarkerId('${i+1}')] = Marker(
          markerId: MarkerId('${i+1}'),
          position: option,
          infoWindow: InfoWindow(title: "Location ${i + 1}", snippet: 'Location of falility ${i + 1}'),
        );
      }
    });
    //return the dropdown widget (scaled 1.5x)
    return Transform.scale(
      scale: 1.5,
      child: Container(
        child: DropdownButton<String>(
          value: _dropdownvalue,
          items: options.map((String value) {
            return new DropdownMenuItem<String>(
              value: value,
              child: new Text(value),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _dropdownvalue = value;
            });
          },
        ),
      ),
    );
  }

  Widget reportButton(){
    var fnToSend = recievedHospitalLock? onReportPressed : null;
    return customButton("Get Report", func:fnToSend, backColor: Colors.blue);
  }

  var hospitalLockedParsedData;
  void onReportPressed(){
    setState(() {
     recievedHospitalLock= false; 
    });
    var temp = hospitalLockedParsedData;
    Navigator.of(context).push(MaterialPageRoute(builder: (context) { return AfterLockReport(weight: temp['weight'], volume: temp['volume'], destination: _dropdownvalue,src: "Hospital #232", latlng: LatLng(double.parse(temp['loc_x']), double.parse(temp['loc_y']))); })); // change to chat page for testing terminal commands
  }

  bool lock = true;
  bool recievedHospitalLock = false;
  @override
  Widget build(BuildContext context) {
    int facilityID = 0,
        transporterID = 0,
        hospitalID = 0; //TODO: id just identifies phone, setting default to 0. Make this something unique to the device.
    int nextTransporterId = 5; //TODO: get this from firebase
    var sampleGeofence = [
      latLong[0], //x
      latLong[1], //y
      30 // radius
    ]; //TODO: get destination required geofences from firebase

  // in this app, where both hospital, facility, and transporter can be controlled, the transporter has to lock/unlock last, as that's when the data is parsed.
    var hospitalLock = isConnecting
        ? null
        : isConnected
            ? () async {
                //hospital locks and sets geofence
                // Flock refers to facility lock, We're treating the hospital and waste disposal place both as as 'facility'
                await _sendMessage(
                    "FLOCK#${0}_${latLong[0]}_${latLong[1]}_${sampleGeofence[0]}_${sampleGeofence[1]}_${sampleGeofence[2]}_${facilityID}");
                var L = await _mostRecentArduinoMessages();
              }
            : null;
    var hospitalUnlock = isConnecting
        ? null
        : isConnected
            ? () async {
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
                await _sendMessage(
                    "FLOCK#${0}_${latLong[0]}_${latLong[1]}_${sampleGeofence[0]}_${sampleGeofence[1]}_${sampleGeofence[2]}_${hospitalID}");
                //nothing happens here as they will send back an empty bin, unless it's a midway stop in some other facility
                // TODO: maybe recieve messages here also, if there are midway stops
              }
            : null;
    var facilityUnlock = isConnecting
        ? null
        : isConnected
            ? () async {
                //facility unlocks and verifies it's position
                await _sendMessage("FUNLOCK#${0}_${latLong[0]}_${latLong[1]}");
                //weight, vol from arduino gotten in transporter unlock. 
              }
            : null;
    var transporterUnlock = isConnecting
        ? null
        : isConnected
            ? () async {
                //facility unlocks and verifies it's position
                await _sendMessage("TUNLOCK#${0}_${latLong[0]}_${latLong[1]}");
                var L = await _mostRecentArduinoMessages();
                var parsedData = parseDataRecieved(L[0].text);
                print(parsedData);
                setState(() {
                 recievedHospitalLock= true;  // to activate the get report button
                 hospitalLockedParsedData = parsedData;
                });
                if(widget.persona == 'hospital'){
                  hospitalUnlockSend();
                  print("SENT TO FIREBASE");
                }
                else{
                  facilityUnlockSend();
                  print("SENT TO FIREBASE");
                }                
              }
            : null;
    var transporterLock = isConnecting
        ? null
        : isConnected
            ? () async {
                //facility unlocks and verifies it's position
                _sendMessage("TLOCK#${0}_${latLong[0]}_${latLong[1]}");
                var L = await _mostRecentArduinoMessages();
                var parsedData = parseDataRecieved(L[0].text);
                print(parsedData);
                setState(() {
                 recievedHospitalLock= true; 
                 hospitalLockedParsedData = parsedData;
                });

                if(widget.persona == 'hospital'){
                  hospitalLockSend(weight:parsedData['weight'], volume: parsedData['volume'], gf_x: parsedData['loc_x'], gf_y: parsedData['loc_y'], gf_rad: parsedData['radius']);
                  print("SENT TO FIREBASE");
                }
                else{
                  facilityLockSend();
                  print("SENT TO FIREBASE");
                }
              }
            : null;
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
      appBar: AppBar(
        title: Text("Control Page"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // identityWidget("Facility Manager"),
            putInWastePrompt(),
            latLongWidget(),
            SizedBox(
              width: 300.0,
              height: 200.0,
              child: googleMap,
            ),
            dropDownWidget(),
            Container(height: 20,),
            customButton("${widget.persona} ${lock?"lock":"unlock"}", func:(lock?hospitalLock:hospitalUnlock)),
            customButton("Transporter ${lock?"lock":"unlock"}", func:(lock?transporterLock:transporterUnlock)),
            reportButton(),
            // toggleLight()
            
            // actionBoard(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.refresh),
        onPressed: (){
          setState(() {
           lock = lock? false: true; 
          });
        },
      ),
    );
  }

  parseDataRecieved(String dataRecieved) {
    String type = dataRecieved.substring(0, dataRecieved.indexOf("#"));
    String data = dataRecieved.substring(dataRecieved.indexOf("#")+1, dataRecieved.length);
    if (type == "LOCK") {
      var temp =  data.split("_");
      return {
        "type": "lock",
        "id": temp[0],
        "volume": temp[1],
        "weight": temp[2],
        "loc_x": temp[3],
        "loc_y": temp[4],
        "radius": temp[5],
      };
    } else if (type == "UNLOCK") {
      var temp =  data.split("_");
      return {
        "type": "unlock",
        "id": temp[0],
        "volume": temp[1],
        "weight": temp[2],
      };
    }
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
    // look for recieved messages after a particular duration
    await Future.delayed(const Duration(milliseconds: 4000), () {
      //TODO: tweak the delay above if input is large (or if you dont get anything from this function)
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
