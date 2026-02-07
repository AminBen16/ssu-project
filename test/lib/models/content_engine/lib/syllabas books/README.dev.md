Development README — start server and run Flutter web

This short guide covers starting the backend server and running the Flutter web app during development.

Start backend (run from `school_server/`):

Run the Dart server locally

PowerShell:

```powershell
cd c:\Users\user\SSU\school_server
dart pub get
dart run bin/server.dart
```

Server will listen on <http://localhost:8080> by default.

Run Flutter web app (from the Flutter project root):

1) Use default local API URL (<http://localhost:8080>)

```powershell
cd c:\Users\user\SSU   # adjust to your Flutter app root if different
flutter pub get
flutter run -d chrome
```

2) Use a different API base URL (staging/prod) via compile-time define

Pass --dart-define to set API_BASE_URL used by `ApiClient`.

```powershell
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=https://staging.example.com
```

Notes on CORS, cookies and auth

- The backend includes CORS middleware that sets `Access-Control-Allow-Origin: *` and allows common methods/headers. That permits browser-based Flutter web apps to call the API during development.
- If you use cookie-based authentication (cookies instead of Bearer tokens), you must:
  - Configure the backend to return `Access-Control-Allow-Credentials: true` and set `Access-Control-Allow-Origin` to the specific origin (cannot be `*`).
  - On the client, send credentials where needed and ensure cookie flags (SameSite, Secure) are appropriate for your environment.
- For production deployments over HTTPS, ensure the backend serves HTTPS (or sits behind a TLS-terminating proxy) and update API_BASE_URL accordingly.

CORS environment variables (advanced)

- You can control CORS behavior using environment variables when starting the server.
- `CORS_ALLOW_CREDENTIALS=true` enables `Access-Control-Allow-Credentials: true` (useful when using cookies). When enabled, you MUST set `CORS_ALLOWED_ORIGIN` to a specific origin (for example `http://localhost:xxxx`) or the special value `echo` to echo the request Origin header. Browsers won't accept `Access-Control-Allow-Origin: *` together with credentials.
- Example (PowerShell):

```powershell
# Allow credentials and echo the request origin
$env:CORS_ALLOW_CREDENTIALS = 'true'
$env:CORS_ALLOWED_ORIGIN = 'echo'
dart run bin/server.dart
```

Flutter dev environment helper

- Instead of repeatedly passing `--dart-define` you can use `flutter_dotenv` for dev-only config loading. Add `flutter_dotenv` to your app `pubspec.yaml` dev_dependencies and create a `.env` file with vars such as `API_BASE_URL` for use in development.
- Example usage (dev-only):

```dart
// lib/dev_env.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> loadDevEnv() async {
  await dotenv.load();
}

String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:8080';
```

Then call `await loadDevEnv()` early during app startup (only in dev builds).

Troubleshooting

- If requests are blocked with a CORS error, check the browser console for the exact message and ensure the server returns the appropriate CORS headers.
- If `curl http://localhost:8080/health` fails with connection refused, ensure the server is running and listening on `localhost:8080`.

If you'd like, I can:

- Add a small environment config helper for the Flutter app to load variables from a file during dev.
- Update the server CORS middleware to optionally include `Access-Control-Allow-Credentials` behind a config flag.
- Run further checks on your machine if you allow me to execute terminal commands here.
