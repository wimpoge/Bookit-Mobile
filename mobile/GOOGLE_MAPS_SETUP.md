# Google Maps Setup Guide

The BookIt mobile app requires proper Google Maps API keys to display maps and perform geocoding operations.

## Current Issue
- **Problem**: Google Maps shows blank white page
- **Cause**: Using dummy/temporary API keys that don't work with Google Services

## Setup Instructions

### 1. Create Google Cloud Project
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing project
3. Enable billing for the project (required for Maps API)

### 2. Enable Required APIs
Enable these APIs in Google Cloud Console:
- **Maps SDK for Android**
- **Geocoding API**
- **Places API** (if using places search)

### 3. Create API Keys

#### Android API Key
1. Go to **APIs & Services > Credentials**
2. Click **Create Credentials > API Key**
3. Restrict the key:
   - **Application restrictions**: Android apps
   - **Package name**: `com.example.hotel_booking_app`
   - **SHA-1 certificate fingerprint**: Get from your keystore
4. **API restrictions**: Select the enabled APIs above

#### Get SHA-1 Fingerprint
```bash
# For debug keystore (development)
cd C:\Users\black\OneDrive\Desktop\Bookit\mobile\android
./gradlew signingReport

# Or using keytool
keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore -storepass android -keypass android
```

### 4. Configure Firebase (for google-services.json)
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create new project or select existing
3. Add Android app:
   - **Package name**: `com.example.hotel_booking_app`
   - **SHA-1**: Same as above
4. Download `google-services.json`
5. Place in `android/app/google-services.json`

### 5. Update API Keys in Code

Replace the dummy API key in `android/app/src/main/AndroidManifest.xml`:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_ACTUAL_GOOGLE_MAPS_API_KEY" />
```

### 6. Test the Implementation
1. Run `flutter clean`
2. Run `flutter pub get`
3. Run `flutter run`

## Current Temporary Files
These files contain dummy data and should be replaced:
- `android/app/google-services.json` - Replace with real Firebase config
- AndroidManifest.xml API key - Replace with real Google Maps API key

## Cost Considerations
- Google Maps API has usage-based pricing
- Free tier includes $200 monthly credit
- Monitor usage in Google Cloud Console