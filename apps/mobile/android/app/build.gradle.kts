plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Google Services plugin for Firebase/Google Sign-In
    id("com.google.gms.google-services")
}

android {
    namespace = "com.dayliz.dayliz_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "29.0.13113456"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        // Enable core library desugaring for flutter_local_notifications
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
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

        // Google Maps API Key configuration
        manifestPlaceholders["GOOGLE_MAPS_API_KEY"] = project.findProperty("GOOGLE_MAPS_API_KEY") ?: "your_google_maps_api_key"

        // Mapbox Access Token configuration
        manifestPlaceholders["MAPBOX_ACCESS_TOKEN"] = project.findProperty("MAPBOX_ACCESS_TOKEN") ?: "pk.eyJ1IjoiZGF5bGl6IiwiYSI6ImNtYmJ0a244bzB6YXUybHNiaHB1bGI4bDkifQ.ZJdfmD9NbE3zAaDACGtg_g"
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
