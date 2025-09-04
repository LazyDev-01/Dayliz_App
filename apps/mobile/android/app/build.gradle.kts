import java.util.Properties
import java.io.FileInputStream

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

// Load keystore properties
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.dayliz.app"
    compileSdk = 35 // Android 15 (required by plugins)
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
        applicationId = "com.dayliz.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 23 // Required for firebase_analytics (updated from 21)
        targetSdk = 35 // Android 15 (required by plugins)
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Google Sign-In configuration
        manifestPlaceholders["com.google.android.gms.client_id"] = "@string/web_client_id"

        // Google Maps API Key configuration - Secure multi-source injection
        // Priority: 1) local.properties, 2) gradle.properties, 3) environment variable, 4) CI fallback
        val localProperties = Properties()
        val localPropertiesFile = rootProject.file("local.properties")
        if (localPropertiesFile.exists()) {
            localProperties.load(localPropertiesFile.inputStream())
        }

        val googleMapsKey = localProperties.getProperty("GOOGLE_MAPS_API_KEY")
            ?: project.findProperty("GOOGLE_MAPS_API_KEY") as String?
            ?: System.getenv("GOOGLE_MAPS_API_KEY")
            ?: "PLACEHOLDER_API_KEY_FOR_CI_BUILD" // Fallback for CI environments

        manifestPlaceholders["GOOGLE_MAPS_API_KEY"] = googleMapsKey
    }

    signingConfigs {
        create("release") {
            // Production keystore configuration
            // Load from key.properties file or environment variables
            keyAlias = keystoreProperties.getProperty("RELEASE_KEY_ALIAS") ?: System.getenv("RELEASE_KEY_ALIAS")
            keyPassword = keystoreProperties.getProperty("RELEASE_KEY_PASSWORD") ?: System.getenv("RELEASE_KEY_PASSWORD")
            storeFile = file(keystoreProperties.getProperty("RELEASE_STORE_FILE") ?: System.getenv("RELEASE_STORE_FILE") ?: "../release-keystore.jks")
            storePassword = keystoreProperties.getProperty("RELEASE_STORE_PASSWORD") ?: System.getenv("RELEASE_STORE_PASSWORD")
        }
    }

    buildTypes {
        release {
            // Production release configuration with proper signing
            signingConfig = signingConfigs.getByName("release")

            // Enable code shrinking and obfuscation for release builds
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Core library desugaring for flutter_local_notifications (updated to 2.1.4+ for compatibility)
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
