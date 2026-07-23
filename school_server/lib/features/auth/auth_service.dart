import 'dart:convert';

import 'package:bcrypt/bcrypt.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:shelf/shelf.dart';

import '../../app/dependencies.dart';
import '../../auth_middleware.dart';
import '../../../services/password_reset_email_service.dart';
import '../../../services/real_email_service.dart';

/// Application service for authentication use cases.
class AuthService {
  AuthService(this.dependencies);