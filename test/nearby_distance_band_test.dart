import 'package:flutter_test/flutter_test.dart';
import 'package:nexora/features/nearby/nearby_distance_band.dart';

void main() {
  test('maps coarse distance bands to Arabic labels', () {
    expect(nearbyDistanceLabel('under_5_km'), 'أقل من 5 كم');
    expect(nearbyDistanceLabel('5_15_km'), '5–15 كم');
    expect(nearbyDistanceLabel('15_25_km'), '15–25 كم');
    expect(nearbyDistanceLabel('unknown'), 'مسافة تقريبية');
  });
}
