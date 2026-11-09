# Influx — Customer Flutter App

A Flutter mobile application for the **Influx** influencer marketing and social community platform. Customers can browse creator profiles, pitch portfolios, view active campaigns, watch video reels, participate in groups/events, and transact securely through a digital wallet with multiple integrated payment gateways.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Project Setup](#project-setup)
3. [Configure the Base URL](#configure-the-base-url)
4. [Payment Gateway Configuration](#payment-gateway-configuration)
5. [Change Package Name & Bundle ID](#change-package-name--bundle-id)
6. [Change App Name & Icon](#change-app-name--icon)
7. [Run the Project Locally](#run-the-project-locally)
8. [Build for Release](#build-for-release)
9. [Project Structure](#project-structure)

---

## Prerequisites

| Tool | Minimum Version |
|---|---|
| Flutter SDK | `>= 3.9.0` |
| Dart SDK | `>= 3.0.0` |
| Android Studio / Xcode | Latest stable |
| Android SDK | API 21 (Android 5.0) |
| iOS | 12.0+ |
| Node / npm | Not required |

> Install Flutter by following the [official guide](https://docs.flutter.dev/get-started/install).

---

## Project Setup

```bash
# 1. Open this directory in your terminal
cd influx_app

# 2. Install all Dart/Flutter dependencies
flutter pub get

# 3. Verify your environment
flutter doctor
```

---

## Configure the Base URL

All API calls are routed through a single constant. **You must update this before building.**

**File:** `lib/config/app_config.dart`

```dart
class AppConfig {
  // ⬇ Replace with your production Laravel API domain
  static const String baseUrl = 'https://your-domain.com/api';

  static const String appName    = 'Influx';
  static const String appVersion = '1.0.0';
}
```

| Environment | Example value |
|---|---|
| Production | `https://influx.yourdomain.com/api` |
| Local (Android emulator) | Use an HTTPS tunnel, e.g. Ngrok: `https://xxxx.ngrok.io/api` |
| Local (iOS simulator) | `https://your-local-ip/api` |

> **HTTPS is required.** Plain `http://` URLs are blocked by Android and iOS in release builds.

---

## Payment Gateway Configuration

All payment gateway **secret keys and API credentials are stored in the Laravel backend**, not in the Flutter app. The app fetches public/initialisation keys from the backend at runtime via the `/payment-gateways` endpoint.

To configure a gateway:

1. Log in to the **Admin Panel**.
2. Navigate to **Settings → Payment Settings**.
3. Enable the gateway and enter the required keys (see table below).

| Gateway | Keys required in Admin Panel |
|---|---|
| **PayPal** | Client ID, Client Secret, Mode (sandbox / live) |
| **Stripe** | Publishable Key, Secret Key |
| **Razorpay** | Key ID, Key Secret, Currency |
| **Flutterwave** | Public Key, Secret Key, Currency |
| **Paystack** | Public Key, Secret Key |
| **Mollie** | API Key (live or test) |
| **SSLCommerz** | Store ID, Store Password, Mode (sandbox / live) |

> The Flutter app receives the **public/initialisation key** from the backend on checkout. Secret keys **never** leave the server.


## Change Package Name & Bundle ID

The default identifiers ship as `com.hme.company`. You **must** change these before publishing.

### Automated (recommended)

```bash
# Install the helper package (once)
flutter pub global activate change_app_package_name

# Apply your new package name
dart run change_app_package_name:main com.yourcompany.Influx
```

### Manual — Android

**File:** `android/app/build.gradle.kts`

```kotlin
android {
    namespace = "com.yourcompany.Influx"        // ← change

    defaultConfig {
        applicationId = "com.yourcompany.Influx" // ← change
    }
}
```

### Manual — iOS

1. Open `ios/Runner.xcodeproj` in Xcode.
2. Select the **Runner** target → **General** tab.
3. Update the **Bundle Identifier** field to `com.yourcompany.Influx`.

---

## Change App Name & Icon

### App Name

**File:** `lib/config/app_config.dart`

```dart
static const String appName = 'Your App Name';
```

For the native display name shown in the device launcher:

- **Android:** `android/app/src/main/AndroidManifest.xml` → `android:label`
- **iOS:** `ios/Runner/Info.plist` → `CFBundleDisplayName`

Or use the automated tool:

```bash
flutter pub global activate rename
flutter pub global run rename setAppName --value "Your App Name"
```

### App Icon

1. Replace `assets/images/logo/logo_old.png` with your icon (recommended **1024 × 1024 px**, no transparency for Android).
2. Regenerate all platform icon sizes:

```bash
dart run flutter_launcher_icons
```

The configuration in `pubspec.yaml` is pre-wired — no changes needed unless you rename the file.

---

## Run the Project Locally

```bash
# List connected devices / emulators
flutter devices

# Run in debug mode on a specific device
flutter run -d <device-id>

# Run on the first available device
flutter run

# Enable hot-reload after code changes (press 'r' in terminal)
```

> The backend must be running and reachable from the device/emulator at the configured `baseUrl` before launching the app.

---

## Build for Release & Production Deployment

To take your application and backend live, follow these detailed instructions for code signing, compiling, and deploying to a production environment.

---

### 1. Android Signed Release Build (Kotlin DSL)

The project is structured using Android's newer **Gradle Kotlin DSL (`.gradle.kts`)**. Follow these steps to configure secure release signing:

#### Step A: Generate a Keystore File
Open your terminal, navigate to the `influx_app` directory, and run the following command to generate a cryptographically secure key:
```bash
keytool -genkey -v -keystore android/app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```
*Note: Keep your keystore password and key password secure. Do not commit the `.jks` file to your public version control.*

#### Step B: Create key.properties
Create a new file named `key.properties` in the `android/` directory (i.e. `android/key.properties`) to reference your keystore credentials:
```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=upload-keystore.jks
```

#### Step C: Configure Android build.gradle.kts
Open `android/app/build.gradle.kts` and update it to read the `key.properties` file dynamically and apply the release signing configuration:

```kotlin
import java.io.Properties
import java.io.FileInputStream

// Load keystore properties
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    ...
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = rootProject.file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            // Apply the release signing config
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}
```

#### Step D: Compile the Release App
Run the compilation command in your root directory:
```bash
# Compile to a signed split-APK for direct installations
flutter build apk --release

# Compile to a signed Android App Bundle (AAB) for Google Play Store upload
flutter build appbundle --release
```
*Output binaries are generated under:* `build/app/outputs/flutter-apk/new_base_url_userApp.apk` or `build/app/outputs/bundle/release/app-release.aab`

---

### 2. iOS Code Signing & Release Build

To distribute the app to Apple TestFlight or the App Store, you must configure code signing within Xcode.

#### Step A: Configure Developer Portal
1. Register your **Bundle ID** (e.g., `com.yourcompany.Influx`) in the [Apple Developer Portal](https://developer.apple.com/account/resources/identifiers/list).
2. Generate an **iOS Distribution Certificate** and install it on your build machine (added to your macOS Keychain).
3. Create a **Provisioning Profile** (App Store or Ad Hoc/TestFlight) linked to your Bundle ID and Distribution Certificate.

#### Step B: Apply Profiles in Xcode
1. Open the project in Xcode: Open `ios/Runner.xcworkspace`.
2. Select the **Runner** project in the left navigation sidebar, and choose the **Runner** target.
3. Select the **Signing & Capabilities** tab.
4. Check **Automatically manage signing** OR select your custom Distribution Profile and Certificate under **Signing (Release)**.

#### Step C: Build the IPA Archive
Run the build command in the root terminal directory:
```bash
flutter build ipa --release
```
Open the generated archive (`build/ios/archive/Runner.xcarchive`) in Xcode Organizer, or open the Apple Transporter app to distribute the `.ipa` package directly to TestFlight and the App Store.

---

## Project Structure

```
lib/
├── config/
│   └── app_config.dart          # Base URL, app name, version, and theme configurations
├── controllers/
│   ├── feed_controller.dart     # Social Feed and post actions
│   ├── campaign_controller.dart # Influencer Campaign creation and application logic
│   └── discover_controller.dart # Discover dashboard homepage controller
├── data/
│   ├── models/                  # Dart models (CampaignModel, FeedItem, etc.)
│   ├── providers/
│   │   └── api_client.dart      # Custom Dio HTTP client wrapper with auth interceptors
│   └── services/
│       └── discover_service.dart # Discover API service client
├── pages/
│   ├── discover/
│   │   └── discover_home_page.dart # Interactive Discover dashboard
│   ├── watch/
│   │   └── watch_page.dart      # Vertical TikTok-style Reels feed
│   └── support/
│       └── support_tickets_page.dart # Customer Support Ticket desk
└── main.dart
```
