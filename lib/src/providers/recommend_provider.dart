import 'package:flutter/foundation.dart';
import '../models/place.dart';

class RecommendProvider extends ChangeNotifier {
  Place? _todayPlace;

  Place? get todayPlace => _todayPlace;

  void setTodayPlace(Place place) {
    _todayPlace = place;
    notifyListeners();
  }

  void clear() {
    _todayPlace = null;
    notifyListeners();
  }
}
