import 'dart:convert';
import 'subscription_model.dart';

class School {
  final int id;
  final String name;
  final String? address;
  final String? phone;
  final String? email;
  final String classification;
  final bool selfRegistrationEnabled;
  final String? logoUrl;
  final String? website;
  final String? motto;
  final String? country;
  final String? mission;
  final String? vision;
  final String? anthem;
  final String? uniformDetails;
  final List<String>? classLevels;
  final Map<String, List<String>>? streams;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Subscription? subscription;
  final List<dynamic>? staff;
  final DateTime? nextTermBeginsOn;
  final String? paidStampColor;

  School({
    required this.id,
    required this.name,
    this.address,
    this.phone,
    this.email,
    required this.classification,
    required this.selfRegistrationEnabled,
    this.logoUrl,
    this.website,
    this.motto,
    this.country,
    this.mission,
    this.vision,
    this.anthem,
    this.uniformDetails,
    this.classLevels,
    this.streams,
    required this.createdAt,
    required this.updatedAt,
    this.subscription,
    this.staff,
    this.nextTermBeginsOn,
    this.paidStampColor,
  });

  factory School.fromMap(Map<String, dynamic> map) {
    return School(
      id: map['id'] as int,
      name: map['name'] as String,
      address: map['address'] as String?,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      classification: map['classification'] as String,
      selfRegistrationEnabled: (map['self_registration_enabled'] as int) == 1,
      logoUrl: map['logo_url'] as String?,
      website: map['website'] as String?,
      motto: map['motto'] as String?,
      country: map['country'] as String?,
      mission: map['mission'] as String?,
      vision: map['vision'] as String?,
      anthem: map['anthem'] as String?,
      uniformDetails: map['uniform_details'] as String?,
      classLevels: map['class_levels'] != null
          ? List<String>.from(jsonDecode(map['class_levels']))
          : null,
      streams: map['streams'] != null
          ? (jsonDecode(map['streams']) as Map<String, dynamic>).map(
              (key, value) => MapEntry(key, List<String>.from(value)),
            )
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'classification': classification,
      'self_registration_enabled': selfRegistrationEnabled ? 1 : 0,
      'logo_url': logoUrl,
      'website': website,
      'motto': motto,
      'country': country,
      'mission': mission,
      'vision': vision,
      'anthem': anthem,
      'uniform_details': uniformDetails,
      'class_levels': classLevels != null ? jsonEncode(classLevels) : null,
      'streams': streams != null ? jsonEncode(streams) : null,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  List<String> get allClassNamesWithStreams {
    final classes = <String>[];
    if (classLevels != null) {
      classes.addAll(classLevels!);
    }
    if (streams != null) {
      for (final entry in streams!.entries) {
        for (final stream in entry.value) {
          classes.add('${entry.key} $stream');
        }
      }
    }
    return classes;
  }

  int get totalClasses => allClassNamesWithStreams.length;

  String? get contact {
    if (phone != null && email != null) {
      return '$phone, $email';
    } else if (phone != null) {
      return phone;
    } else if (email != null) {
      return email;
    }
    return null;
  }
}
