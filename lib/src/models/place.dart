class Place {
  final String id;
  final String name;
  final String address;
  final String? category;
  final String? categoryName;
  final String? mention;
  final String? imageUrl;
  final List<String>? imageUrls;
  final double? rating;
  final String? openHours;
  final String? phone;
  final int? priceLevel;
  final String? website;
  final double? lat;
  final double? lng;
  final String? searchUrl;

  Place({
    required this.id,
    required this.name,
    required this.address,
    this.category,
    this.categoryName,
    this.mention,
    this.imageUrl,
    this.imageUrls,
    this.rating,
    this.openHours,
    this.phone,
    this.priceLevel,
    this.website,
    this.lat,
    this.lng,
    this.searchUrl,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    final imageUrls = (json['imageUrls'] as List?)?.map((e) => e as String).toList() ?? [];
    print('Place: ${json['name']} - imageUrls count: ${imageUrls.length}, urls: $imageUrls');
    return Place(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      category: json['category'],
      categoryName: json['categoryName'],
      mention: json['mention'],
      imageUrl: json['imageUrl'],
      imageUrls: imageUrls,
      searchUrl: json['searchUrl'],
      rating: (json['rating'] is num)
          ? (json['rating'] as num).toDouble()
          : null,
      openHours: json['openHours'],
      phone: json['phone']?.toString(),
      priceLevel: _toInt(json['priceLevel']),
      website: json['website'],
      lat: _toDouble(json['lat']),
      lng: _toDouble(json['lng']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'imageUrl': imageUrl,
      'imageUrls': imageUrls,
      'lat': lat,
      'lng': lng,
      'categoryName': categoryName,
      'openHours': openHours,
      'rating': rating,
      'phone': phone,
      'searchUrl': searchUrl,
    };
  }

  static double? _toDouble(dynamic val) {
    if (val == null) return null;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    if (val is String) return double.tryParse(val);
    return null;
  }

  static int? _toInt(dynamic val) {
    if (val == null) return null;
    if (val is int) return val;
    if (val is double) return val.toInt();
    if (val is String) return int.tryParse(val);
    return null;
  }
}
