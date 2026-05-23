class User {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final String role;
  final String createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatarUrl,
    required this.role,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      role: json['role'] as String,
      createdAt: json['createdAt'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'role': role,
      'createdAt': createdAt,
    };
  }
}

class Category {
  final int id;
  final String name;
  final String icon;
  final int? salonCount;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    this.salonCount,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int,
      name: json['name'] as String,
      icon: json['icon'] as String,
      salonCount: json['salonCount'] as int?,
    );
  }
}

class Salon {
  final int id;
  final String name;
  final String? description;
  final int ownerId;
  final String address;
  final String city;
  final String? state;
  final double? lat;
  final double? lng;
  final String? phone;
  final String? imageUrl;
  final List<String> images;
  final double avgRating;
  final int totalReviews;
  final bool isActive;
  final bool isVerified;
  final String? openTime;
  final String? closeTime;
  final double? distanceKm;
  final bool? isFavorited;
  final int? totalSeats;
  final String createdAt;

  Salon({
    required this.id,
    required this.name,
    this.description,
    required this.ownerId,
    required this.address,
    required this.city,
    this.state,
    this.lat,
    this.lng,
    this.phone,
    this.imageUrl,
    required this.images,
    required this.avgRating,
    required this.totalReviews,
    required this.isActive,
    required this.isVerified,
    this.openTime,
    this.closeTime,
    this.distanceKm,
    this.isFavorited,
    this.totalSeats,
    required this.createdAt,
  });

  factory Salon.fromJson(Map<String, dynamic> json) {
    var rawImages = json['images'];
    List<String> listImages = [];
    if (rawImages is List) {
      listImages = rawImages.map((e) => e.toString()).toList();
    }
    return Salon(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      ownerId: json['ownerId'] as int,
      address: json['address'] as String,
      city: json['city'] as String,
      state: json['state'] as String?,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      phone: json['phone'] as String?,
      imageUrl: json['imageUrl'] as String?,
      images: listImages,
      avgRating: (json['avgRating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: json['totalReviews'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      isVerified: json['isVerified'] as bool? ?? false,
      openTime: json['openTime'] as String?,
      closeTime: json['closeTime'] as String?,
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      isFavorited: json['isFavorited'] as bool?,
      totalSeats: json['totalSeats'] as int?,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }
}

class Service {
  final int id;
  final int salonId;
  final String name;
  final String? description;
  final double price;
  final int durationMinutes;
  final String? category;
  final String? imageUrl;
  final bool isActive;
  final double? discountPercent;
  final String createdAt;

  Service({
    required this.id,
    required this.salonId,
    required this.name,
    this.description,
    required this.price,
    required this.durationMinutes,
    this.category,
    this.imageUrl,
    required this.isActive,
    this.discountPercent,
    required this.createdAt,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'] as int,
      salonId: json['salonId'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toDouble(),
      durationMinutes: json['durationMinutes'] as int,
      category: json['category'] as String?,
      imageUrl: json['imageUrl'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      discountPercent: (json['discountPercent'] as num?)?.toDouble(),
      createdAt: json['createdAt'] as String? ?? '',
    );
  }
}

class StaffMember {
  final int id;
  final int salonId;
  final String name;
  final String? role;
  final String? specialization;
  final String? avatarUrl;
  final bool isAvailable;
  final String createdAt;

  StaffMember({
    required this.id,
    required this.salonId,
    required this.name,
    this.role,
    this.specialization,
    this.avatarUrl,
    required this.isAvailable,
    required this.createdAt,
  });

  factory StaffMember.fromJson(Map<String, dynamic> json) {
    return StaffMember(
      id: json['id'] as int,
      salonId: json['salonId'] as int,
      name: json['name'] as String,
      role: json['role'] as String?,
      specialization: json['specialization'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      isAvailable: json['isAvailable'] as bool? ?? true,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }
}

class Review {
  final int id;
  final int userId;
  final int salonId;
  final int? bookingId;
  final int rating;
  final String? comment;
  final User? user;
  final String createdAt;

  Review({
    required this.id,
    required this.userId,
    required this.salonId,
    this.bookingId,
    required this.rating,
    this.comment,
    this.user,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as int,
      userId: json['userId'] as int,
      salonId: json['salonId'] as int,
      bookingId: json['bookingId'] as int?,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      user: json['user'] != null ? User.fromJson(json['user'] as Map<String, dynamic>) : null,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }
}

class Booking {
  final int id;
  final int userId;
  final int salonId;
  final int serviceId;
  final int? staffId;
  final String bookingDate;
  final String startTime;
  final String? endTime;
  final String status;
  final double totalPrice;
  final String? notes;
  final Salon? salon;
  final Service? service;
  final StaffMember? staff;
  final User? user;
  final String createdAt;

  Booking({
    required this.id,
    required this.userId,
    required this.salonId,
    required this.serviceId,
    this.staffId,
    required this.bookingDate,
    required this.startTime,
    this.endTime,
    required this.status,
    required this.totalPrice,
    this.notes,
    this.salon,
    this.service,
    this.staff,
    this.user,
    required this.createdAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as int,
      userId: json['userId'] as int,
      salonId: json['salonId'] as int,
      serviceId: json['serviceId'] as int,
      staffId: json['staffId'] as int?,
      bookingDate: json['bookingDate'] as String,
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String?,
      status: json['status'] as String,
      totalPrice: (json['totalPrice'] as num).toDouble(),
      notes: json['notes'] as String?,
      salon: json['salon'] != null ? Salon.fromJson(json['salon'] as Map<String, dynamic>) : null,
      service: json['service'] != null ? Service.fromJson(json['service'] as Map<String, dynamic>) : null,
      staff: json['staff'] != null ? StaffMember.fromJson(json['staff'] as Map<String, dynamic>) : null,
      user: json['user'] != null ? User.fromJson(json['user'] as Map<String, dynamic>) : null,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }
}

class TimeSlot {
  final String time;
  final bool available;
  final int? staffId;

  TimeSlot({
    required this.time,
    required this.available,
    this.staffId,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      time: json['time'] as String,
      available: json['available'] as bool,
      staffId: json['staffId'] as int?,
    );
  }
}

class SalonStats {
  final int totalBookings;
  final double totalRevenue;
  final int activeCustomers;
  final double avgRating;
  final int totalReviews;
  final int thisMonthBookings;
  final double thisMonthRevenue;
  final Map<String, int> bookingsByStatus;

  SalonStats({
    required this.totalBookings,
    required this.totalRevenue,
    required this.activeCustomers,
    required this.avgRating,
    required this.totalReviews,
    required this.thisMonthBookings,
    required this.thisMonthRevenue,
    required this.bookingsByStatus,
  });

  factory SalonStats.fromJson(Map<String, dynamic> json) {
    var rawByStatus = json['bookingsByStatus'] as Map<String, dynamic>? ?? {};
    Map<String, int> statsMap = {};
    rawByStatus.forEach((key, value) {
      statsMap[key] = value as int;
    });
    return SalonStats(
      totalBookings: json['totalBookings'] as int? ?? 0,
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      activeCustomers: json['activeCustomers'] as int? ?? 0,
      avgRating: (json['avgRating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: json['totalReviews'] as int? ?? 0,
      thisMonthBookings: json['thisMonthBookings'] as int? ?? 0,
      thisMonthRevenue: (json['thisMonthRevenue'] as num?)?.toDouble() ?? 0.0,
      bookingsByStatus: statsMap,
    );
  }
}
