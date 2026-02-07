# Development notes for school_server

The server now uses SQLite as the database, making it completely self-contained without external dependencies.

Environment variables used by the server (development):

- DB_PATH: path to SQLite database file (default: `school_server.db` in current directory)
- BIND_ADDR: address to bind the HTTP server to (default: `0.0.0.0`)
- PORT: port the server listens on (default: `8080`)

Notes:

- The server uses SQLite with the `sqlite3` package for local database storage.
- Database file is created automatically if it doesn't exist.
- No external database server required - everything runs locally.
- To run locally:

  ```bash
  dart pub get
  dart run bin/server.dart
  ```

- Health endpoint: GET /health (for example: `http://localhost:8080/health`)

Database file location:
- Default: `school_server.db` in the server directory
- The database contains all user data, student records, exam results, etc.
- Backup the `.db` file to preserve data
