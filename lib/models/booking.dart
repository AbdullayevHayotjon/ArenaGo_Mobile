import 'football_field.dart';

class BookingFieldSummary {
  const BookingFieldSummary({
    required this.id,
    required this.name,
    required this.address,
    required this.image,
  });

  factory BookingFieldSummary.fromJson(Object? json) {
    final data = json is Map<String, dynamic>
        ? json
        : const <String, dynamic>{};
    final imageJson = data['image'];
    return BookingFieldSummary(
      id: data['id']?.toString() ?? '',
      name: LocalizedText.fromJson(data['name']),
      address: LocalizedText.fromJson(data['address']),
      image: imageJson is Map<String, dynamic>
          ? FootballFieldImage.fromJson(imageJson)
          : null,
    );
  }

  final String id;
  final LocalizedText name;
  final LocalizedText address;
  final FootballFieldImage? image;
}

class Booking {
  const Booking({
    required this.id,
    required this.bookingNumber,
    required this.footballFieldId,
    required this.ownerAdminId,
    required this.customerId,
    required this.source,
    required this.customerName,
    required this.customerPhoneNumber,
    required this.bookingDate,
    required this.startsAt,
    required this.endsAt,
    required this.status,
    required this.totalAmount,
    required this.prepaymentAmount,
    required this.collectedAmount,
    required this.currency,
    required this.expiresAt,
    required this.createdAt,
    required this.field,
    required this.remainingAmount,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id']?.toString() ?? '',
      bookingNumber: json['bookingNumber']?.toString() ?? '',
      footballFieldId: json['footballFieldId']?.toString() ?? '',
      ownerAdminId: json['ownerAdminId']?.toString() ?? '',
      customerId: json['customerId']?.toString() ?? '',
      source: json['source']?.toString() ?? '',
      customerName: json['customerName']?.toString() ?? '',
      customerPhoneNumber: json['customerPhoneNumber']?.toString() ?? '',
      bookingDate: json['bookingDate']?.toString() ?? '',
      startsAt: json['startsAt']?.toString() ?? '',
      endsAt: json['endsAt']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      totalAmount: _asDouble(json['totalAmount']),
      prepaymentAmount: _asDouble(json['prepaymentAmount']),
      collectedAmount: _asDouble(json['collectedAmount']),
      currency: json['currency']?.toString() ?? '',
      expiresAt: _asDateTime(json['expiresAt']),
      createdAt: _asDateTime(json['createdAt']),
      field: BookingFieldSummary.fromJson(json['field']),
      remainingAmount: _asDouble(json['remainingAmount']),
    );
  }

  final String id;
  final String bookingNumber;
  final String footballFieldId;
  final String ownerAdminId;
  final String customerId;
  final String source;
  final String customerName;
  final String customerPhoneNumber;
  final String bookingDate;
  final String startsAt;
  final String endsAt;
  final String status;
  final double totalAmount;
  final double prepaymentAmount;
  final double collectedAmount;
  final String currency;
  final DateTime expiresAt;
  final DateTime createdAt;
  final BookingFieldSummary field;
  final double remainingAmount;
}

class BookingPage {
  const BookingPage({
    required this.items,
    required this.pageNumber,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
    required this.hasPreviousPage,
    required this.hasNextPage,
  });

  factory BookingPage.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    return BookingPage(
      items: rawItems is List
          ? rawItems
                .whereType<Map<String, dynamic>>()
                .map(Booking.fromJson)
                .toList(growable: false)
          : const [],
      pageNumber: _asInt(json['pageNumber'], 1),
      pageSize: _asInt(json['pageSize'], 20),
      totalCount: _asInt(json['totalCount'], 0),
      totalPages: _asInt(json['totalPages'], 0),
      hasPreviousPage: json['hasPreviousPage'] == true,
      hasNextPage: json['hasNextPage'] == true,
    );
  }

  final List<Booking> items;
  final int pageNumber;
  final int pageSize;
  final int totalCount;
  final int totalPages;
  final bool hasPreviousPage;
  final bool hasNextPage;
}

double _asDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _asInt(Object? value, int fallback) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

DateTime _asDateTime(Object? value) {
  return DateTime.tryParse(value?.toString() ?? '') ??
      DateTime.fromMillisecondsSinceEpoch(0);
}
