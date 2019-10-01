import 'package:geolocator/geolocator.dart';

class OneTimeLocation {
  double latitude;
  double longitude;

  Future getCurrentLocation() async {
    try {
      Position position = await Geolocator()
          .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      latitude = position.latitude;
      longitude = position.longitude;
    } catch (exception) {
      print("Oh no!");
      print(exception);
    }
    return [latitude, longitude];
  }
}