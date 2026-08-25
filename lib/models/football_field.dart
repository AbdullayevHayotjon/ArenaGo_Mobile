class LocalizedText {
  const LocalizedText({required this.uz, required this.ru});

  factory LocalizedText.fromJson(Object? json) {
    final data = json is Map<String, dynamic>
        ? json
        : const <String, dynamic>{};
    return LocalizedText(
      uz: data['uz']?.toString() ?? '',
      ru: data['ru']?.toString() ?? '',
    );
  }

  final String uz;
  final String ru;

  String value(String language) {
    final selected = language == 'ru' ? ru : uz;
    if (selected.trim().isNotEmpty) return selected.trim();
    return (language == 'ru' ? uz : ru).trim();
  }
}

class FootballFieldLocation {
  const FootballFieldLocation({
    required this.latitude,
    required this.longitude,
  });

  factory FootballFieldLocation.fromJson(Object? json) {
    final data = json is Map<String, dynamic>
        ? json
        : const <String, dynamic>{};
    return FootballFieldLocation(
      latitude: _asDouble(data['latitude']),
      longitude: _asDouble(data['longitude']),
    );
  }

  final double latitude;
  final double longitude;
}

class FootballFieldMapLocation {
  const FootballFieldMapLocation({
    required this.id,
    required this.latitude,
    required this.longitude,
  });

  factory FootballFieldMapLocation.fromJson(Map<String, dynamic> json) {
    return FootballFieldMapLocation(
      id: json['id']?.toString() ?? '',
      latitude: _asDouble(json['latitude']),
      longitude: _asDouble(json['longitude']),
    );
  }

  final String id;
  final double latitude;
  final double longitude;

  bool get hasValidCoordinates =>
      id.isNotEmpty &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180 &&
      (latitude != 0 || longitude != 0);
}

class FootballFieldImage {
  const FootballFieldImage({required this.id, required this.url});

  factory FootballFieldImage.fromJson(Map<String, dynamic> json) {
    return FootballFieldImage(
      id: json['id']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
    );
  }

  final String id;
  final String url;
}

class FootballField {
  const FootballField({
    required this.id,
    required this.ownerAdminId,
    required this.name,
    required this.description,
    required this.address,
    required this.location,
    required this.phoneNumber,
    required this.opensAt,
    required this.closesAt,
    required this.hourlyPrice,
    required this.prepaymentPercent,
    required this.prepaymentAmount,
    required this.currency,
    required this.image,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.isFavorite,
  });

  factory FootballField.fromJson(Map<String, dynamic> json) {
    final imageJson = json['image'];
    return FootballField(
      id: json['id']?.toString() ?? '',
      ownerAdminId: json['ownerAdminId']?.toString() ?? '',
      name: LocalizedText.fromJson(json['name']),
      description: LocalizedText.fromJson(json['description']),
      address: LocalizedText.fromJson(json['address']),
      location: FootballFieldLocation.fromJson(json['location']),
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      opensAt: json['opensAt']?.toString() ?? '',
      closesAt: json['closesAt']?.toString() ?? '',
      hourlyPrice: _asDouble(json['hourlyPrice']),
      prepaymentPercent: _asDouble(json['prepaymentPercent']),
      prepaymentAmount: _asDouble(json['prepaymentAmount']),
      currency: json['currency']?.toString() ?? '',
      image: imageJson is Map<String, dynamic>
          ? FootballFieldImage.fromJson(imageJson)
          : null,
      isActive: json['isActive'] == true,
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
      isFavorite: json['isFavorite'] == true,
    );
  }

  final String id;
  final String ownerAdminId;
  final LocalizedText name;
  final LocalizedText description;
  final LocalizedText address;
  final FootballFieldLocation location;
  final String phoneNumber;
  final String opensAt;
  final String closesAt;
  final double hourlyPrice;
  final double prepaymentPercent;
  final double prepaymentAmount;
  final String currency;
  final FootballFieldImage? image;
  final bool isActive;
  final String createdAt;
  final String updatedAt;
  final bool isFavorite;

  FootballField copyWith({bool? isFavorite}) {
    return FootballField(
      id: id,
      ownerAdminId: ownerAdminId,
      name: name,
      description: description,
      address: address,
      location: location,
      phoneNumber: phoneNumber,
      opensAt: opensAt,
      closesAt: closesAt,
      hourlyPrice: hourlyPrice,
      prepaymentPercent: prepaymentPercent,
      prepaymentAmount: prepaymentAmount,
      currency: currency,
      image: image,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

class FootballFieldPage {
  const FootballFieldPage({
    required this.items,
    required this.pageNumber,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
    required this.hasPreviousPage,
    required this.hasNextPage,
  });

  factory FootballFieldPage.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    return FootballFieldPage(
      items: rawItems is List
          ? rawItems
                .whereType<Map<String, dynamic>>()
                .map(FootballField.fromJson)
                .toList(growable: false)
          : const [],
      pageNumber: _asInt(json['pageNumber'], fallback: 1),
      pageSize: _asInt(json['pageSize'], fallback: 20),
      totalCount: _asInt(json['totalCount']),
      totalPages: _asInt(json['totalPages']),
      hasPreviousPage: json['hasPreviousPage'] == true,
      hasNextPage: json['hasNextPage'] == true,
    );
  }

  final List<FootballField> items;
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

int _asInt(Object? value, {int fallback = 0}) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}
