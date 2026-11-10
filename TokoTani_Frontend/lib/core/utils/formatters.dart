/// Format angka rupiah: 12000 -> "Rp 12.000".
String formatRupiah(num value) {
  final negative = value < 0;
  final digits = value.abs().round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return '${negative ? '-' : ''}Rp $buffer';
}

const List<String> _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

DateTime? _parse(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final parsed = DateTime.tryParse(raw.trim());
  if (parsed == null) return null;
  return parsed.isUtc ? parsed.toLocal() : parsed;
}

String _two(int v) => v.toString().padLeft(2, '0');

/// "2026-11-09" atau ISO-8601 -> "9 Nov 2026". Nilai tak terbaca dikembalikan apa adanya.
String formatDate(String? raw) {
  final date = _parse(raw);
  if (date == null) return (raw == null || raw.isEmpty) ? '-' : raw;
  return '${date.day} ${_months[date.month - 1]} ${date.year}';
}

/// ISO-8601 -> "9 Nov 2026, 17:49".
String formatDateTime(String? raw) {
  final date = _parse(raw);
  if (date == null) return (raw == null || raw.isEmpty) ? '-' : raw;
  return '${date.day} ${_months[date.month - 1]} ${date.year}, '
      '${_two(date.hour)}:${_two(date.minute)}';
}

/// DateTime -> "yyyy-MM-dd" untuk dikirim ke API.
String toApiDate(DateTime date) =>
    '${date.year}-${_two(date.month)}-${_two(date.day)}';
