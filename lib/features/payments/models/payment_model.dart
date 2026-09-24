/// 🌟 মডেল: পেমেন্ট ট্রানজ্যাকশন আইটেম (ওয়েবের PaymentsView এর অনুরূপ)
class PaymentItem {
  final String id;
  final String bookingId;
  final String transactionId;
  final double amount;
  final String status; // PAID, PENDING, FAILED
  final String createdAt;
  final String? updatedAt;
  final String bookingStatus;
  final String? bookingDate;
  final String? slot;
  final String customerName;
  final String customerEmail;
  final String technicianName;
  final String technicianEmail;

  PaymentItem({
    required this.id,
    required this.bookingId,
    required this.transactionId,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    required this.bookingStatus,
    this.bookingDate,
    this.slot,
    required this.customerName,
    required this.customerEmail,
    required this.technicianName,
    required this.technicianEmail,
  });

  factory PaymentItem.fromJson(Map<String, dynamic> json) {
    final booking = json['booking'] as Map<String, dynamic>?;
    final customer = booking?['customer'] as Map<String, dynamic>?;
    final techProfile = booking?['technicianProfile'] as Map<String, dynamic>?;
    final techUser = techProfile?['user'] as Map<String, dynamic>?;

    double pAmount = 0.0;
    if (json['amount'] != null) {
      pAmount = (json['amount'] as num).toDouble();
    } else if (booking?['price'] != null) {
      pAmount = (booking!['price'] as num).toDouble();
    }

    return PaymentItem(
      id: json['id'] ?? '',
      bookingId: json['bookingId'] ?? booking?['id'] ?? '',
      transactionId: json['transactionId'] ?? 'N/A',
      amount: pAmount,
      status: (json['status'] ?? 'PENDING').toString().toUpperCase(),
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString(),
      bookingStatus: (booking?['status'] ?? 'ACCEPTED').toString().toUpperCase(),
      bookingDate: booking?['bookingDate']?.toString(),
      slot: booking?['slot']?.toString(),
      customerName: customer?['name'] ?? 'FixItNow Customer',
      customerEmail: customer?['email'] ?? 'customer@fixitnow.com',
      technicianName: techUser?['name'] ?? 'Professional Technician',
      technicianEmail: techUser?['email'] ?? 'technician@fixitnow.com',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookingId': bookingId,
      'transactionId': transactionId,
      'amount': amount,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'booking': {
        'id': bookingId,
        'status': bookingStatus,
        'bookingDate': bookingDate,
        'slot': slot,
        'customer': {
          'name': customerName,
          'email': customerEmail,
        },
        'technicianProfile': {
          'user': {
            'name': technicianName,
            'email': technicianEmail,
          },
        },
      },
    };
  }
}
