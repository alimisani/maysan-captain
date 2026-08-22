import 'package:flutter_test/flutter_test.dart';
import 'package:maysan_captain/core/constants/app_constants.dart';
import 'package:maysan_captain/core/services/location_service.dart';

void main() {
  test('Maysan locations and distance calculation test', () {
    expect(AppConstants.maysanLocations.isNotEmpty, true);
    final distance = LocationService.calculateDistance(
      AppConstants.maysanLocations[0].coordinates,
      AppConstants.maysanLocations[1].coordinates,
    );
    expect(distance > 0, true);
  });
}
