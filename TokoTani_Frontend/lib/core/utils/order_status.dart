/// Nada visual untuk lencana status.
enum StatusTone { success, warning, info, danger, neutral }

/// Satu langkah pada lini masa pesanan.
class TimelineStep {
  final String title;
  final String hint;
  final bool done;
  final bool current;
  final bool failed;

  const TimelineStep({
    required this.title,
    required this.hint,
    this.done = false,
    this.current = false,
    this.failed = false,
  });
}

/// Pemetaan status pesanan dari Laravel ke label, warna, dan lini masa.
class OrderStatus {
  const OrderStatus._();

  static const String waitingPayment = 'menunggu_pembayaran';
  static const String waitingConfirmation = 'menunggu_konfirmasi';
  static const String paid = 'dibayar';
  static const String processing = 'diproses';
  static const String shipping = 'dikirim';
  static const String arrived = 'tiba';
  static const String completed = 'selesai';
  static const String cancelled = 'dibatalkan';

  static String normalize(String raw) => raw.trim().toLowerCase();

  static String label(String raw) {
    switch (normalize(raw)) {
      case waitingPayment:
        return 'Menunggu Pembayaran';
      case waitingConfirmation:
        return 'Menunggu Verifikasi';
      case paid:
        return 'Sudah Dibayar';
      case processing:
        return 'Sedang Diproses';
      case shipping:
        return 'Dalam Pengiriman';
      case arrived:
        return 'Pesanan Tiba';
      case completed:
        return 'Selesai';
      case cancelled:
        return 'Dibatalkan';
      default:
        return raw.trim().isEmpty ? 'Status tidak diketahui' : raw;
    }
  }

  static StatusTone tone(String raw) {
    switch (normalize(raw)) {
      case paid:
      case completed:
        return StatusTone.success;
      case waitingPayment:
      case waitingConfirmation:
        return StatusTone.warning;
      case processing:
      case shipping:
      case arrived:
        return StatusTone.info;
      case cancelled:
        return StatusTone.danger;
      default:
        return StatusTone.neutral;
    }
  }

  /// Urutan alur normal pesanan. -1 untuk dibatalkan / tidak dikenal.
  static int rank(String raw) {
    switch (normalize(raw)) {
      case waitingPayment:
        return 0;
      case waitingConfirmation:
        return 1;
      case paid:
        return 2;
      case processing:
        return 3;
      case shipping:
        return 4;
      case arrived:
        return 5;
      case completed:
        return 6;
      default:
        return -1;
    }
  }

  static bool canPay(String raw) => normalize(raw) == waitingPayment;
  static bool canComplete(String raw) {
    final status = normalize(raw);
    return status == shipping || status == arrived;
  }

  /// Empat tahap seperti pada desain: Dibuat, Diproses, Dikirim, Selesai.
  /// Tidak ada cap waktu karena API tidak menyediakannya.
  static List<TimelineStep> stepper(String raw) {
    final status = normalize(raw);
    final r = rank(status);

    if (status == cancelled) {
      return const [
        TimelineStep(title: 'Pesanan Dibuat', hint: '', done: true),
        TimelineStep(title: 'Dibatalkan', hint: '', failed: true),
      ];
    }
    final safe = r < 0 ? 0 : r;

    TimelineStep step(String title, int doneFrom, int currentFrom) =>
        TimelineStep(
          title: title,
          hint: '',
          done: safe >= doneFrom,
          current: safe < doneFrom && safe >= currentFrom,
        );

    return [
      const TimelineStep(title: 'Pesanan Dibuat', hint: '', done: true),
      step('Diproses', 4, 0),
      step('Dikirim', 5, 4),
      step('Selesai', 6, 5),
    ];
  }

  /// Kelompok filter pada daftar pesanan.
  static String group(String raw) {
    switch (normalize(raw)) {
      case waitingPayment:
      case waitingConfirmation:
      case paid:
      case processing:
        return 'diproses';
      case shipping:
      case arrived:
        return 'dikirim';
      case completed:
        return 'selesai';
      default:
        return 'lainnya';
    }
  }
}
