# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Run the app
flutter run

# Run on a specific device
flutter run -d windows
flutter run -d chrome

# Build
flutter build apk
flutter build windows

# Analyze code
flutter analyze

# Run tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Get dependencies
flutter pub get
```

## Architecture

This is a Flutter admin dashboard app (`admin_app`) using Provider for state management. It targets a PHP backend hosted on Railway.

**Base API URL:** `https://api-php-production-5399.up.railway.app` (in [lib/services/api_service.dart](lib/services/api_service.dart))

### State Management

Single `AuthProvider` (ChangeNotifier) in [lib/providers/auth_provider.dart](lib/providers/auth_provider.dart) manages all auth state. Tokens and user data are persisted via `flutter_secure_storage`. Auth status has three states: `checking`, `authenticated`, `unauthenticated`.

### Auth Flow

`AuthGate` in [lib/main.dart](lib/main.dart) reads from `AuthProvider` and routes:
- `checking` → loading spinner
- `authenticated + isAdmin` → `/dashboard`
- `authenticated + !isAdmin` → `/tienda`
- `unauthenticated` → `/login`

`ProtectedRoute` wraps `/dashboard` to redirect non-admins.

### Layer Structure

```
lib/
├── main.dart              # App entry, routing (AppRoutes), AuthGate, ProtectedRoute
├── providers/             # AuthProvider (single provider)
├── services/              # ApiService (HTTP calls), AuthService (auth logic)
├── controllers/           # Business logic: login, inventario, reportes
├── models/                # Data models (13 total)
└── views/                 # LoginView, DashboardView, TiendaView
```

### Key Files

- [lib/services/api_service.dart](lib/services/api_service.dart) — All HTTP requests. Uses Bearer token + session cookie. Has flexible JSON parsing to handle both uppercase and lowercase field names from the PHP backend. 30s timeout on all requests.
- [lib/views/dashboard_view.dart](lib/views/dashboard_view.dart) — ~2600 lines. The main admin panel with 4 tabs: Inicio (stats + charts), Reportes (period-filtered reports), Registro (provider/product CRUD), Perfil.
- [lib/models/reportes_dashboard_model.dart](lib/models/reportes_dashboard_model.dart) — Complex dashboard data model with nested structures (bar items, ranking items, best-day data).

### Secure Storage Keys

`flutter_secure_storage` uses these keys: `auth_token`, `refresh_token`, `session_cookie`, `auth_user` (JSON-encoded `UserModel`). All managed by `AuthProvider`.

### Notes

- `controllers/inventario_controller.dart` and `controllers/reportes_controller.dart` are empty stubs.
- `models/admin_model.dart` and `models/producto_model.dart` are also empty — do not import or extend without implementing them first.
- The `widgets/` directory exists but contains no files; add shared widgets there.

### Charts

Dashboard uses custom `CustomPaint`-based animated bar and line charts — no external charting library. Chart widgets are defined inside [lib/views/dashboard_view.dart](lib/views/dashboard_view.dart).

### API Response Pattern

All API calls return `ApiResponse<T>` from [lib/models/api_response.dart](lib/models/api_response.dart) — a generic wrapper with `success`, `data`, and `message` fields.
