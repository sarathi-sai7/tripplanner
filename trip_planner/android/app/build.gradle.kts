plugins {
    id("com.android.application")
    id("com.google.gms.google-services") // Firebase
    kotlin("android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.trip_planner"

    // ✅ FIX: Force latest SDK (required for <queries>)
    compileSdk = 36

    defaultConfig {
        applicationId = "com.example.trip_planner"

        // ✅ Safe values
        minSdk = flutter.minSdkVersion
        targetSdk = 36

        versionCode = flutter.versionCode
        versionName = flutter.versionName

        multiDexEnabled = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildTypes {
        release {
            // ⚠️ For now using debug signing (ok for testing)
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    implementation("androidx.multidex:multidex:2.0.1")
}

flutter {
    source = "../.."
}
