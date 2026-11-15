import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationProvider extends ChangeNotifier {
  double? _latitude;
  double? _longitude;
  String _currentAddress = '내 위치 불러오는 중...';

  double? get latitude => _latitude;
  double? get longitude => _longitude;
  String get currentAddress => _currentAddress;

  Future<void> loadCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _currentAddress = '위치 권한 허용 필요';
        notifyListeners();
        return;
      }
      Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      _latitude = pos.latitude;
      _longitude = pos.longitude;

      List<Placemark> placemarks = await placemarkFromCoordinates(_latitude!, _longitude!);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        _currentAddress = '${p.locality ?? ''} ${p.subLocality ?? ''}'.trim();
      } else {
        _currentAddress = '${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}';
      }
      notifyListeners();
    } catch (e) {
      _currentAddress = '위치 불러오기 실패';
      notifyListeners();
    }
  }
}
