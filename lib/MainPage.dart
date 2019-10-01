import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:waste_management/ControlPage.dart';

import './SelectBondedDevicePage.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPage createState() => new _MainPage();
}

class _MainPage extends State<MainPage> {
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;

  String _address = "...";
  String _name = "...";

  Timer _discoverableTimeoutTimer;
  int _discoverableTimeoutSecondsLeft = 0;


  bool _autoAcceptPairingRequests = false;

  @override
  void initState() {
    super.initState();
    
    // Get current state
    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() { _bluetoothState = state; });
    });

    Future.doWhile(() async {
      // Wait if adapter not enabled
      if (await FlutterBluetoothSerial.instance.isEnabled) {
        return false;
      }
      await Future.delayed(Duration(milliseconds: 0xDD));
      return true;
    }).then((_) {
      // Update the address field
      FlutterBluetoothSerial.instance.address.then((address) {
        setState(() { _address = address; });
      });
    });

    FlutterBluetoothSerial.instance.name.then((name) {
      setState(() { _name = name; });
    });

    // Listen for futher state changes
    FlutterBluetoothSerial.instance.onStateChanged().listen((BluetoothState state) {
      setState(() {
        _bluetoothState = state;

        // Discoverable mode is disabled when Bluetooth gets disabled
        _discoverableTimeoutTimer = null;
        _discoverableTimeoutSecondsLeft = 0;
      });
    });
  }

  @override
  void dispose() {
    FlutterBluetoothSerial.instance.setPairingRequestHandler(null);
    _discoverableTimeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Bluetooth Serial',),
      ),
      body: Container(
        child: ListView(
          children: <Widget>[
            SwitchListTile(
              title: const Text('Enable Bluetooth'),
              value: _bluetoothState.isEnabled,
              onChanged: (bool value) {
                // Do the request and update with the true value then
                future() async { // async lambda seems to not working
                  if (value)
                    await FlutterBluetoothSerial.instance.requestEnable();
                  else
                    await FlutterBluetoothSerial.instance.requestDisable();
                }
                future().then((_) {
                  setState(() {});
                });
              },
            ),
            ListTile(
              title: const Text('Bluetooth status'),
              subtitle: Text(_bluetoothState.toString()),
              trailing: RaisedButton(
                child: const Text('Settings'),
                onPressed: () { 
                  FlutterBluetoothSerial.instance.openSettings();
                },
              ),
            ),
            ListTile(
              title: const Text('Local adapter address'),
              subtitle: Text(_address),
            ),
            ListTile(
              title: RaisedButton(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: const Text('Log in as Hospital', style: TextStyle(fontSize: 25),),
                ),
                onPressed: () async {
                  final BluetoothDevice selectedDevice = await Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) { return SelectBondedDevicePage(checkAvailability: false); })
                  );

                  if (selectedDevice != null) {
                    print('Connect -> selected ' + selectedDevice.address);
                    _startChat(context, selectedDevice, true);
                  }
                  else {
                    print('Connect -> no device selected');
                  }
                },
                shape: RoundedRectangleBorder(
                borderRadius: new BorderRadius.circular(30.0),
                ),
                color: Colors.green,
              ),
            ),
            ListTile(
              title: RaisedButton(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: const Text('Log in as Facility', style: TextStyle(fontSize: 25),),
                ),
                onPressed: () async {
                  final BluetoothDevice selectedDevice = await Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) { return SelectBondedDevicePage(checkAvailability: false); })
                  );

                  if (selectedDevice != null) {
                    print('Connect -> selected ' + selectedDevice.address);
                    _startChat(context, selectedDevice, false);
                  }
                  else {
                    print('Connect -> no device selected');
                  }
                },
                shape: RoundedRectangleBorder(
                borderRadius: new BorderRadius.circular(30.0),
                ),
                color: Colors.green,
              ),
            ),
            ListTile(
              title: RaisedButton(
                child: Text('Control page'),
                onPressed: (){
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) {return ControlPage();})
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  void _startChat(BuildContext context, BluetoothDevice server, bool isHospital) {
    String persona = isHospital? "hospital":"facility";
    Navigator.of(context).push(MaterialPageRoute(builder: (context) { return ControlPage(server: server, deviceAddress: _address, persona: persona,); })); // change to chat page for testing terminal commands
  }

  
}
