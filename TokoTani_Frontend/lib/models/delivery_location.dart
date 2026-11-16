class DeliveryLocation {
  const DeliveryLocation({
    required this.address,
    required this.latitude,
    required this.longitude,
    this.accuracy,
  });

  final String address;
  final double latitude;
  final double longitude;
  final double? accuracy;

  bool get isValid =>
      address.trim().isNotEmpty &&
      latitude.isFinite &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude.isFinite &&
      longitude >= -180 &&
      longitude <= 180 &&
      (accuracy == null || (accuracy!.isFinite && accuracy! >= 0));
}
