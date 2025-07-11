plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Google Services plugin for Firebase/Google Sign-In
    id("com.google.gms.google-services")
    // Firebase Crashlytics plugin for crash reporting
    id("com.google.firebase.crashlytics")
    // Firebase Performance plugin for performance monitoring
    id("com.google.firebase.firebase-perf")
}

android {
    namespace = "com.dayliz.dayliz_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "29.0.13113456"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
        // Enable core library desugaring for flutter_local_notifications
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_21.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.dayliz.dayliz_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 21 // Required for flutter_local_notifications
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Google Sign-In configuration
        manifestPlaceholders["com.google.android.gms.client_id"] = "@string/web_client_id"

        // Google Maps API Key configuration - Secure environment injection with CI fallback
        val googleMapsKey = project.findProperty("GOOGLE_MAPS_API_KEY") as String?
            ?: System.getenv("GOOGLE_MAPS_API_KEY")
            ?: "PLACEHOLDER_API_KEY_FOR_CI_BUILD" // Fallback for CI environments

        manifestPlaceholders["GOOGLE_MAPS_API_KEY"] = googleMapsKey
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Core library desugaring for flutter_local_notifications
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
