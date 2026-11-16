import 'package:flutter_test/flutter_test.dart';
import 'package:tokotani/models/delivery_location.dart';

void main() {
  test('delivery location accepts only valid address and coordinates', () {
    expect(
      const DeliveryLocation(
        address: 'Alamat terpilih',
        latitude: -90,
        longitude: 180,
      ).isValid,
      isTrue,
    );
    expect(
      const DeliveryLocation(
        address: 'Alamat terpilih',
        latitude: -90.01,
        longitude: 180,
      ).isValid,
      isFalse,
    );
    expect(
      const DeliveryLocation(address: '', latitude: 0, longitude: 0).isValid,
      isFalse,
    );
    expect(
      const DeliveryLocation(
        address: 'Alamat terpilih',
        latitude: 0,
        longitude: 0,
        accuracy: -1,
      ).isValid,
      isFalse,
    );
  });
}
