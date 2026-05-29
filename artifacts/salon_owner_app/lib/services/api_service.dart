import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as _http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class ApiService {
  static const String baseUrl = 'https://glowbook-luq7.onrender.com/api';
  
  static String? _token;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  static Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  static String? get token => _token;

  static Map<String, String> _headers() {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // --- HEALTH ---
  static Future<bool> checkHealth() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/healthz'));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // --- AUTH ---
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers(),
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token'] as String;
      final user = User.fromJson(data['user']);
      await saveToken(token);
      return {'token': token, 'user': user};
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['error'] ?? 'Login failed');
    }
  }

  static Future<Map<String, dynamic>> register(String name, String email, String password, String? phone, String role) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _headers(),
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        'role': role,
      }),
    );
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final token = data['token'] as String;
      final user = User.fromJson(data['user']);
      await saveToken(token);
      return {'token': token, 'user': user};
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['error'] ?? 'Registration failed');
    }
  }

  static Future<User> getMe() async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: _headers(),
    );
    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load profile');
    }
  }

  // --- USERS & PROFILE ---
  static Future<User> updateProfile(String name, String? phone) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/users/profile'),
      headers: _headers(),
      body: jsonEncode({
        'name': name,
        'phone': phone,
      }),
    );
    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['error'] ?? 'Failed to update profile');
    }
  }

  static Future<List<Salon>> getFavorites() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/favorites'),
      headers: _headers(),
    );
    if (response.statusCode == 200) {
      final List raw = jsonDecode(response.body);
      return raw.map((item) => Salon.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch favorites');
    }
  }

  static Future<void> addFavorite(int salonId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/favorites/$salonId'),
      headers: _headers(),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to add favorite');
    }
  }

  static Future<void> removeFavorite(int salonId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/users/favorites/$salonId'),
      headers: _headers(),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to remove favorite');
    }
  }

  // --- CATEGORIES ---
  static Future<List<Category>> getCategories() async {
    final response = await http.get(
      Uri.parse('$baseUrl/categories'),
      headers: _headers(),
    );
    if (response.statusCode == 200) {
      final List raw = jsonDecode(response.body);
      return raw.map((item) => Category.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch categories');
    }
  }

  // --- SALONS ---
  static Future<List<Salon>> getSalons({String? search, String? category}) async {
    final queryParams = <String, String>{};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (category != null && category.isNotEmpty) queryParams['category'] = category;
    
    final uri = Uri.parse('$baseUrl/salons').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers());
    if (response.statusCode == 200) {
      final raw = jsonDecode(response.body);
      final List list = raw['salons'] ?? [];
      return list.map((item) => Salon.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch salons');
    }
  }

  static Future<Map<String, List<Salon>>> getFeaturedSalons() async {
    final response = await http.get(
      Uri.parse('$baseUrl/salons/featured'),
      headers: _headers(),
    );
    if (response.statusCode == 200) {
      final raw = jsonDecode(response.body);
      final List trendingList = raw['trending'] ?? [];
      final List topRatedList = raw['topRated'] ?? [];
      final List nearbyList = raw['nearby'] ?? [];

      return {
        'trending': trendingList.map((item) => Salon.fromJson(item)).toList(),
        'topRated': topRatedList.map((item) => Salon.fromJson(item)).toList(),
        'nearby': nearbyList.map((item) => Salon.fromJson(item)).toList(),
      };
    } else {
      throw Exception('Failed to fetch featured salons');
    }
  }

  static Future<Salon> getSalon(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/salons/$id'),
      headers: _headers(),
    );
    if (response.statusCode == 200) {
      return Salon.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to fetch salon detail');
    }
  }

  static Future<List<Service>> getSalonServices(int salonId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/salons/$salonId/services'),
      headers: _headers(),
    );
    if (response.statusCode == 200) {
      final List raw = jsonDecode(response.body);
      return raw.map((item) => Service.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch services');
    }
  }

  static Future<List<StaffMember>> getSalonStaff(int salonId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/salons/$salonId/staff'),
      headers: _headers(),
    );
    if (response.statusCode == 200) {
      final List raw = jsonDecode(response.body);
      return raw.map((item) => StaffMember.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch staff list');
    }
  }

  static Future<List<Review>> getSalonReviews(int salonId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/salons/$salonId/reviews'),
      headers: _headers(),
    );
    if (response.statusCode == 200) {
      final raw = jsonDecode(response.body);
      final List reviewsList = raw['reviews'] ?? [];
      return reviewsList.map((item) => Review.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch reviews');
    }
  }

  static Future<List<TimeSlot>> getSalonAvailability(int salonId, String date, int? serviceId) async {
    final queryParams = <String, String>{'date': date};
    if (serviceId != null) queryParams['serviceId'] = serviceId.toString();

    final uri = Uri.parse('$baseUrl/salons/$salonId/availability').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers());
    if (response.statusCode == 200) {
      final List raw = jsonDecode(response.body);
      return raw.map((item) => TimeSlot.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch availability');
    }
  }

  // --- BOOKINGS ---
  static Future<List<Booking>> getBookings({String? status, String? role}) async {
    final queryParams = <String, String>{};
    if (status != null) queryParams['status'] = status;
    if (role != null) queryParams['role'] = role;

    final uri = Uri.parse('$baseUrl/bookings').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers());
    if (response.statusCode == 200) {
      final List raw = jsonDecode(response.body);
      return raw.map((item) => Booking.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch bookings');
    }
  }

  static Future<Booking> createBooking(int salonId, int serviceId, int? staffId, String bookingDate, String startTime, String? notes) async {
    final response = await http.post(
      Uri.parse('$baseUrl/bookings'),
      headers: _headers(),
      body: jsonEncode({
        'salonId': salonId,
        'serviceId': serviceId,
        if (staffId != null) 'staffId': staffId,
        'bookingDate': bookingDate,
        'startTime': startTime,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      }),
    );
    if (response.statusCode == 201) {
      return Booking.fromJson(jsonDecode(response.body));
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['error'] ?? 'Booking failed');
    }
  }

  static Future<Booking> getBooking(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/bookings/$id'),
      headers: _headers(),
    );
    if (response.statusCode == 200) {
      return Booking.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load booking details');
    }
  }

  static Future<Booking> updateBookingStatus(int id, String status) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/bookings/$id/status'),
      headers: _headers(),
      body: jsonEncode({'status': status}),
    );
    if (response.statusCode == 200) {
      return Booking.fromJson(jsonDecode(response.body));
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['error'] ?? 'Failed to update status');
    }
  }

  // --- OWNER OPERATIONS ---
  static Future<List<Salon>> getMySalons() async {
    final response = await http.get(
      Uri.parse('$baseUrl/salons/my'),
      headers: _headers(),
    );
    if (response.statusCode == 200) {
      final List raw = jsonDecode(response.body);
      return raw.map((item) => Salon.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load your salons');
    }
  }

  static Future<SalonStats> getSalonStats(int salonId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/salons/$salonId/stats'),
      headers: _headers(),
    );
    if (response.statusCode == 200) {
      return SalonStats.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to fetch salon metrics');
    }
  }

  static Future<Salon> createSalon(String name, String address, String city, String? description, String? phone, String? imageUrl, String? openTime, String? closeTime) async {
    final response = await http.post(
      Uri.parse('$baseUrl/salons'),
      headers: _headers(),
      body: jsonEncode({
        'name': name,
        'address': address,
        'city': city,
        if (description != null) 'description': description,
        if (phone != null) 'phone': phone,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (openTime != null) 'openTime': openTime,
        if (closeTime != null) 'closeTime': closeTime,
      }),
    );
    if (response.statusCode == 201) {
      return Salon.fromJson(jsonDecode(response.body));
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['error'] ?? 'Failed to create salon');
    }
  }

  static Future<Salon> updateSalon(int id, {String? name, String? address, String? city, String? description, String? phone, String? imageUrl, String? openTime, String? closeTime}) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/salons/$id'),
      headers: _headers(),
      body: jsonEncode({
        if (name != null) 'name': name,
        if (address != null) 'address': address,
        if (city != null) 'city': city,
        if (description != null) 'description': description,
        if (phone != null) 'phone': phone,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (openTime != null) 'openTime': openTime,
        if (closeTime != null) 'closeTime': closeTime,
      }),
    );
    if (response.statusCode == 200) {
      return Salon.fromJson(jsonDecode(response.body));
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['error'] ?? 'Failed to update salon');
    }
  }

  static Future<Service> createService(int salonId, String name, double price, int durationMinutes, String? category, String? description) async {
    final response = await http.post(
      Uri.parse('$baseUrl/salons/$salonId/services'),
      headers: _headers(),
      body: jsonEncode({
        'name': name,
        'price': price,
        'durationMinutes': durationMinutes,
        if (category != null) 'category': category,
        if (description != null) 'description': description,
      }),
    );
    if (response.statusCode == 201) {
      return Service.fromJson(jsonDecode(response.body));
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['error'] ?? 'Failed to create service');
    }
  }

  static Future<Service> updateService(int salonId, int serviceId, {String? name, double? price, int? durationMinutes, String? category, String? description, bool? isActive}) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/salons/$salonId/services/$serviceId'),
      headers: _headers(),
      body: jsonEncode({
        if (name != null) 'name': name,
        if (price != null) 'price': price,
        if (durationMinutes != null) 'durationMinutes': durationMinutes,
        if (category != null) 'category': category,
        if (description != null) 'description': description,
        if (isActive != null) 'isActive': isActive,
      }),
    );
    if (response.statusCode == 200) {
      return Service.fromJson(jsonDecode(response.body));
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['error'] ?? 'Failed to update service');
    }
  }

  static Future<void> deleteService(int salonId, int serviceId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/salons/$salonId/services/$serviceId'),
      headers: _headers(),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete service');
    }
  }

  static Future<StaffMember> createStaff(int salonId, String name, String? role, String? specialization, String? avatarUrl) async {
    final response = await http.post(
      Uri.parse('$baseUrl/salons/$salonId/staff'),
      headers: _headers(),
      body: jsonEncode({
        'name': name,
        if (role != null) 'role': role,
        if (specialization != null) 'specialization': specialization,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
      }),
    );
    if (response.statusCode == 201) {
      return StaffMember.fromJson(jsonDecode(response.body));
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['error'] ?? 'Failed to add staff member');
    }
  }
}

class http {
  static Future<_http.Response> _wrap(Future<_http.Response> Function() req) async {
    try {
      return await req().timeout(const Duration(seconds: 90));
    } on TimeoutException {
      throw Exception('Connection timed out. The server is spinning up. Please try again in a few seconds.');
    }
  }

  static Future<_http.Response> get(Uri url, {Map<String, String>? headers}) {
    return _wrap(() => _http.get(url, headers: headers));
  }

  static Future<_http.Response> post(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) {
    return _wrap(() => _http.post(url, headers: headers, body: body, encoding: encoding));
  }

  static Future<_http.Response> patch(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) {
    return _wrap(() => _http.patch(url, headers: headers, body: body, encoding: encoding));
  }

  static Future<_http.Response> delete(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) {
    return _wrap(() => _http.delete(url, headers: headers, body: body, encoding: encoding));
  }

  static Future<_http.Response> put(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) {
    return _wrap(() => _http.put(url, headers: headers, body: body, encoding: encoding));
  }
}
