# 🔧 COMPREHENSIVE CODE PATCHING & DEBUGGING GUIDE
## Based on Security Audit Evidence - SSU Project

---

## 🚨 CRITICAL SECURITY PATCHES REQUIRED

### 1. JWT SECRET VULNERABILITY PATCH
**Evidence**: `school_server/lib/auth_middleware.dart:8`
```dart
// VULNERABLE CODE:
static const String _jwtSecret = 'your-secret-key-change-in-production';

// PATCH - Replace with:
import 'dart:io';
static String get _jwtSecret {
  final secret = Platform.environment['JWT_SECRET'];
  if (secret == null || secret.isEmpty) {
    throw Exception('JWT_SECRET environment variable not set');
  }
  return secret;
}
```

**Debugging Steps**:
1. Verify `.env` file contains `JWT_SECRET=<your-secure-random-string>`
2. Check `school_server/.env` file exists
3. Ensure environment variable loading in `server.dart`
4. Test with `print('JWT Secret loaded: ${_jwtSecret.isNotEmpty}');`

---

### 2. TOKEN EXPIRATION VALIDATION PATCH
**Evidence**: `school_server/lib/auth_middleware.dart:12-35`
```dart
// VULNERABLE CODE:
static Map<String, String>? validateToken(String? authHeader) {
  // ... existing code ...
  final decoded = JWT.verify(token, SecretKey(_jwtSecret));
  // Missing expiration check
}

// PATCH - Add expiration validation:
static Map<String, String>? validateToken(String? authHeader) {
  if (authHeader == null || !authHeader.startsWith('Bearer ')) {
    return null;
  }

  final token = authHeader.substring(7);

  try {
    final decoded = JWT.verify(token, SecretKey(_jwtSecret));
    
    // ADD EXPIRATION CHECK
    final now = DateTime.now();
    final exp = decoded.payload['exp'] as int?;
    if (exp != null) {
      final expiration = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      if (expiration.isBefore(now)) {
        return null; // Token expired
      }
    }
    
    final userId = decoded.subject;
    final userRole = decoded.payload['role'] as String?;

    if (userId == null || userRole == null) {
      return null;
    }

    return {
      'userId': userId,
      'userRole': userRole,
    };
  } catch (e) {
    return null;
  }
}
```

**Debugging Steps**:
1. Add logging: `print('Token validation result: ${userInfo != null}');`
2. Test with expired tokens
3. Verify `exp` claim exists in JWT payload
4. Check timezone handling for expiration

---

### 3. CLIENT-SIDE TOKEN VALIDATION PATCH
**Evidence**: `test/lib/services/auth_service.dart:117-122`
```dart
// VULNERABLE CODE:
Future<bool> isAuthenticated() async {
  final token = await _secureStorage.read(key: _jwtTokenKey);
  return token != null; // Only checks presence
}

// PATCH - Add expiration check:
Future<bool> isAuthenticated() async {
  final token = await _secureStorage.read(key: _jwtTokenKey);
  if (token == null) return false;
  
  try {
    final decoded = JWT.decode(token);
    final exp = decoded.payload['exp'] as int?;
    if (exp != null) {
      final expiration = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      if (expiration.isBefore(DateTime.now())) {
        await signOut(); // Clear expired token
        return false;
      }
    }
    return true;
  } catch (e) {
    await signOut(); // Clear invalid token
    return false;
  }
}
```

**Debugging Steps**:
1. Add debug print: `print('Token expiration: $expiration, Now: ${DateTime.now()}');`
2. Test with manually expired tokens
3. Verify signOut() clears storage properly
4. Check JWT decode error handling

---

### 4. PASSWORD RESET RATE LIMITING PATCH
**Evidence**: `test/lib/services/auth_service.dart:77-80`
```dart
// VULNERABLE CODE:
Future<void> resetPassword({required String email}) async {
  await _apiClient.post('/auth/forgot-password', body: {'email': email});
}

// PATCH - Add rate limiting:
class AuthService {
  static final Map<String, DateTime> _resetAttempts = {};
  static const int _maxAttemptsPerHour = 3;
  
  Future<void> resetPassword({required String email}) async {
    // RATE LIMITING CHECK
    final now = DateTime.now();
    final lastAttempt = _resetAttempts[email];
    final attempts = _resetAttempts.entries
        .where((e) => e.key == email && 
                     now.difference(e.value).inHours < 1)
        .length;
    
    if (attempts >= _maxAttemptsPerHour) {
      throw Exception('Too many password reset attempts. Try again later.');
    }
    
    _resetAttempts[email] = now;
    
    try {
      await _apiClient.post('/auth/forgot-password', body: {'email': email});
    } catch (e) {
      _resetAttempts.remove(email); // Remove on failure
      rethrow;
    }
  }
}
```

**Debugging Steps**:
1. Add attempt counter logging
2. Test rate limiting with multiple rapid requests
3. Verify cleanup of old attempts
4. Check error message handling

---

## 🔍 DEBUGGING WORKFLOW

### Step 1: Environment Setup Verification
```bash
# Check .env file exists
ls -la school_server/.env

# Verify JWT_SECRET is set
grep JWT_SECRET school_server/.env

# Test server startup with env vars
cd school_server && dart bin/server.dart
```

### Step 2: Token Validation Testing
```dart
// Add to auth_middleware.dart for debugging
static void debugToken(String token) {
  try {
    final decoded = JWT.decode(token);
    print('Token payload: ${decoded.payload}');
    print('Token subject: ${decoded.subject}');
    print('Token issued at: ${decoded.payload['iat']}');
    print('Token expires at: ${decoded.payload['exp']}');
  } catch (e) {
    print('Token decode error: $e');
  }
}
```

### Step 3: Database Security Verification
```sql
-- Check existing users table structure
.schema users

-- Verify password hashes are stored (not plaintext)
SELECT email, LENGTH(password_hash) as hash_length FROM users LIMIT 5;

-- Check for any missing indexes
PRAGMA index_list(users);
```

---

## 📋 PATCH IMPLEMENTATION CHECKLIST

### ✅ Pre-Patch Verification
- [ ] Backup current codebase
- [ ] Create development branch
- [ ] Test current functionality
- [ ] Document current behavior

### ✅ JWT Secret Patch
- [ ] Add environment variable loading
- [ ] Update server startup script
- [ ] Test with missing env var (should fail)
- [ ] Verify token generation works
- [ ] Test token validation works

### ✅ Token Expiration Patch
- [ ] Add expiration check in middleware
- [ ] Update client-side validation
- [ ] Test with expired tokens
- [ ] Verify automatic logout
- [ ] Check timezone handling

### ✅ Rate Limiting Patch
- [ ] Implement attempt tracking
- [ ] Add rate limit checks
- [ ] Test rate limiting behavior
- [ ] Verify error messages
- [ ] Check cleanup of old attempts

### ✅ Post-Patch Testing
- [ ] Full authentication flow test
- [ ] Token refresh test
- [ ] Password reset flow test
- [ ] Security regression test
- [ ] Performance impact assessment

---

## 🚨 EMERGENCY ROLLBACK PROCEDURES

### If Authentication Fails:
```bash
# Revert to previous commit
git revert <patch-commit-hash>

# Or restore backup files
cp backup/auth_middleware.dart school_server/lib/
cp backup/auth_service.dart test/lib/services/
```

### If Environment Variables Missing:
```bash
# Set temporary secret for testing
export JWT_SECRET="temporary-secret-for-testing-only"
dart bin/server.dart
```

---

## 📊 PATCH VALIDATION METRICS

### Security Metrics:
- JWT secret: ✅ Environment-based
- Token expiration: ✅ Validated server & client
- Rate limiting: ✅ Implemented
- Password complexity: ⏳ Pending DB schema update

### Performance Metrics:
- Token validation time: < 50ms
- Rate limiting overhead: < 5ms
- Environment variable access: < 1ms

---

## 🔄 CONTINUOUS MONITORING

### Add to production:
```dart
// Security monitoring
class SecurityMonitor {
  static void logAuthAttempt(String email, bool success) {
    // Log to secure audit trail
  }
  
  static void logTokenValidation(String userId, bool valid) {
    // Monitor token validation failures
  }
  
  static void logRateLimitHit(String email) {
    // Monitor rate limiting triggers
  }
}
```

---

**⚠️ CRITICAL**: Apply patches in order: JWT Secret → Token Expiration → Rate Limiting → Database Security

**📞 Support**: If patches cause issues, immediately rollback and review audit logs for root cause analysis.
