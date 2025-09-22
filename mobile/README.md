# BookIt Mobile App

A comprehensive Flutter hotel booking application featuring real-time chat, AI assistance, QR code check-in, and advanced analytics for both guests and hotel owners.

## Features

### For Hotel Guests
- **Hotel Discovery**: Advanced search with filters (location, price, amenities, ratings)
- **Booking Management**: Complete booking lifecycle with QR code check-in/check-out
- **Payment Integration**: Stripe payment processing with multiple methods (Apple Pay, Google Pay)
- **Real-time Chat**: Direct communication with hotel owners via WebSocket
- **AI Assistant**: GPT-4o-mini powered hotel recommendations and support
- **Review System**: Rate and review hotels with detailed feedback
- **Location Services**: GPS-based nearby hotel discovery with Google Maps
- **Favorites**: Save and manage preferred hotels
- **Profile Management**: Account settings and booking history

### For Hotel Owners
- **Hotel Management**: Create, edit, and manage hotel listings with multi-image uploads
- **Booking Operations**: Confirm, check-in, and check-out guests
- **Analytics Dashboard**: Revenue tracking, booking trends, and performance metrics
- **Guest Communication**: Real-time chat with guests and support management
- **Review Management**: Respond to guest reviews and feedback
- **Dynamic Pricing**: Manage room rates and special discounts
- **Export Capabilities**: Generate PDF and Excel reports

## Technology Stack

### Core Framework
- **Flutter**: 3.10+ with Material Design 3
- **Dart**: 3.0+ with null safety
- **Architecture**: BLoC pattern for state management

### Key Dependencies
- **State Management**: flutter_bloc (^8.1.4), equatable (^2.0.5)
- **Navigation**: go_router (^13.2.0) with nested routing
- **Networking**: dio (^5.4.0), http (^1.2.0)
- **Payment**: flutter_stripe (^10.1.1)
- **Real-time**: WebSocket support for chat
- **Maps & Location**: google_maps_flutter (^2.6.0), location (^6.0.2)
- **Authentication**: google_sign_in (^6.2.1)
- **Storage**: flutter_secure_storage (^9.0.0), shared_preferences (^2.2.2)
- **UI/UX**: google_fonts (^6.2.0), cached_network_image (^3.3.1)
- **Charts**: fl_chart (^0.68.0) for analytics visualization
- **QR Codes**: qr_flutter (^4.1.0)
- **File Handling**: image_picker (^1.0.7), pdf (^3.10.7), excel (^4.0.2)

## Project Structure

### Architecture Overview
```
lib/
├── blocs/              # BLoC state management
│   ├── auth/           # Authentication states
│   ├── bookings/       # Booking management
│   ├── chat/           # Real-time messaging
│   ├── hotels/         # Hotel data management
│   ├── payments/       # Payment processing
│   └── reviews/        # Review system
├── models/             # Data models
├── screens/            # UI screens
│   ├── user/           # Guest user screens
│   ├── owner/          # Hotel owner screens
│   └── settings/       # App settings
├── services/           # Business logic services
├── widgets/            # Reusable UI components
└── config/             # App configuration
```

### Screen Structure

**Guest User Screens:**
- Home & hotel discovery
- Hotel details with booking
- Payment processing (Stripe integration)
- Booking management and history
- QR code check-in/check-out
- Real-time chat with owners
- Reviews and ratings
- Profile and favorites

**Hotel Owner Screens:**
- Hotel portfolio management
- Booking operations dashboard
- Analytics and reporting
- Guest communication hub
- Review management
- Dynamic pricing controls

## Setup Instructions

### Prerequisites
- Flutter SDK 3.10+
- Dart SDK 3.0+
- Android Studio / VS Code
- Google Cloud Console account
- Stripe account

### Installation

1. **Clone and install dependencies**
   ```bash
   git clone <repository-url>
   cd mobile
   flutter pub get
   ```

2. **Configure environment variables**
   ```bash
   # Create .env file in mobile directory
   cp .env.example .env
   ```

   Update `.env` with:
   ```env
   GOOGLE_MAPS_API_KEY=your-google-maps-api-key
   GOOGLE_CLIENT_ID=your-google-oauth-client-id
   STRIPE_PUBLISHABLE_KEY=your-stripe-publishable-key
   ```

3. **Setup Google Services**
   - Download `google-services.json` from Firebase Console
   - Place in `android/app/google-services.json`
   - Configure Google Maps API key in `android/app/src/main/AndroidManifest.xml`

4. **Configure API endpoint**
   Update in `lib/services/api_service.dart`:
   ```dart
   static const String baseUrl = 'http://your-backend-url.com/api';
   ```

### Running the Application

```bash
# Development mode
flutter run

# Specific device
flutter run -d <device-id>

# Debug build
flutter build apk --debug

# Release build
flutter build apk --release
```

## Key Features Implementation

### Authentication System
- JWT token management with secure storage
- Google OAuth integration
- Role-based routing (guest vs owner)
- Automatic token refresh and session management

### Payment Integration
- Stripe SDK integration with support for:
  - Credit/debit cards
  - Apple Pay (iOS)
  - Google Pay (Android)
  - Payment method storage and management
  - Secure payment processing

### Real-time Chat
- WebSocket-based messaging
- Connection state management
- Message persistence and history
- Automatic reconnection handling
- Owner-guest communication channels

### QR Code System
- Unique QR generation for each booking
- Contactless check-in/check-out process
- QR scanner integration
- Mobile-optimized QR display

### Location Services
- GPS integration for nearby hotels
- Google Maps integration with custom markers
- Geolocation-based search and filtering
- Address geocoding and reverse geocoding

### Analytics Dashboard
- Revenue tracking and trend analysis
- Booking conversion metrics
- Guest rating distribution
- Export functionality (PDF/Excel)
- Interactive charts and visualizations

### AI Assistant
- GPT-4o-mini integration for intelligent responses
- Hotel recommendation engine
- Natural language query processing
- Context-aware assistance

## Configuration Files

### Android Configuration
- `android/app/build.gradle` - Build configuration
- `android/app/src/main/AndroidManifest.xml` - Permissions and API keys
- `android/app/google-services.json` - Firebase configuration

### Environment Variables
```env
# Required environment variables
GOOGLE_MAPS_API_KEY=your-google-maps-api-key
GOOGLE_CLIENT_ID=your-google-oauth-client-id
STRIPE_PUBLISHABLE_KEY=your-stripe-publishable-key
```

## State Management

### BLoC Pattern Implementation
- **AuthBloc**: User authentication and session management
- **HotelsBloc**: Hotel data and search functionality
- **BookingsBloc**: Booking lifecycle management
- **PaymentsBloc**: Payment processing and method management
- **ChatBloc**: Real-time messaging state
- **ReviewsBloc**: Review and rating system

### Data Flow
- Centralized API service with singleton pattern
- Secure token management with automatic refresh
- Error handling and retry mechanisms
- Optimistic UI updates with rollback capabilities

## Security Features

- Secure token storage using flutter_secure_storage
- Environment variable management for sensitive data
- Input validation and sanitization
- HTTPS-only API communication
- Role-based access control
- Secure payment processing with Stripe

## Performance Optimizations

- Lazy loading of BLoC providers
- Image caching with cached_network_image
- Efficient navigation with GoRouter
- Background task handling for chat notifications
- Optimized build configurations for release

## Build & Deployment

### Debug Build
```bash
flutter build apk --debug
```

### Release Build
```bash
# Android APK
flutter build apk --release

# Android App Bundle (for Play Store)
flutter build appbundle --release
```

### Code Signing (Release)
Configure in `android/app/build.gradle`:
```gradle
android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
}
```

## Testing

```bash
# Run unit tests
flutter test

# Run integration tests
flutter drive --target=test_driver/app.dart
```

## Troubleshooting

### Common Issues
1. **Google Maps not showing**: Verify API key configuration
2. **Payment errors**: Check Stripe configuration and test keys
3. **Build failures**: Run `flutter clean && flutter pub get`
4. **WebSocket connection issues**: Verify backend URL and CORS settings

### Debug Commands
```bash
# Check Flutter setup
flutter doctor

# Clean build cache
flutter clean

# Analyze code
flutter analyze

# Check dependencies
flutter pub deps
```