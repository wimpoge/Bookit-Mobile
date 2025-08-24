# BookIt Mobile App

Flutter-based hotel booking application with real-time chat and Google authentication.

## Features

**For Users:**
- Hotel search and filtering
- Booking management with QR codes
- Real-time chat with hotel owners
- Review system
- Google OAuth authentication

**For Hotel Owners:**
- Hotel management
- Booking oversight
- Guest communication
- Review responses
- Basic analytics

## Tech Stack

- Flutter 3.10+ with BLoC pattern
- Go Router navigation
- Dio HTTP client
- Google Sign-In
- WebSocket communication
- Material Design 3

## Quick Start

1. **Setup Flutter**
   ```bash
   flutter pub get
   ```

2. **Configure Google Services**
   - Add `google-services.json` to `android/app/`
   - Configure Google Maps API key in AndroidManifest.xml

3. **Run the app**
   ```bash
   flutter run
   ```

## Configuration

### API Endpoint
Update in `lib/services/api_service.dart`:
```dart
static const String baseUrl = 'http://your-api-url.com/api';
```

### Google Services
Required files (use templates provided):
- `android/app/google-services.json`
- Google Maps API key in `AndroidManifest.xml`

## Build

```bash
# Debug
flutter build apk --debug

# Release
flutter build apk --release
```