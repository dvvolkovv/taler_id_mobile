plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "tirol.taler.taler_id_mobile"
    compileSdk = 36
    ndkVersion = "28.2.13676358"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "tirol.taler.taler_id_mobile"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "environment"
    productFlavors {
        create("dev") {
            dimension = "environment"
            applicationId = "tirol.taler.taler_id_mobile.dev"
            versionNameSuffix = "-dev"
            resValue("string", "app_name", "Taler ID Dev")
        }
        create("prod") {
            dimension = "environment"
            applicationId = "tirol.taler.taler_id_mobile"
            resValue("string", "app_name", "Taler ID")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("com.google.mlkit:segmentation-selfie:16.0.0-beta6")
    compileOnly("io.github.webrtc-sdk:android:125.6422.03")
    // Phase 1A: Kotlin unit tests for the notifications module.
    testImplementation("junit:junit:4.13.2")
}
