import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
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

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    flavorDimensions += "environment"
    productFlavors {
        create("dev") {
            dimension = "environment"
            applicationId = "tirol.taler.taler_id_mobile.dev"
            versionNameSuffix = "-dev"
            resValue("string", "app_name", "Taler ID Dev")
            signingConfig = signingConfigs.getByName("debug")
        }
        create("prod") {
            dimension = "environment"
            applicationId = "tirol.taler.taler_id_mobile"
            resValue("string", "app_name", "Taler ID")
            signingConfig = signingConfigs.getByName("debug")
        }
        create("talerid") {
            dimension = "environment"
            applicationId = "io.talerid.app"
            resValue("string", "app_name", "Taler ID")
            signingConfig = signingConfigs.getByName("release")
        }
    }

    buildTypes {
        // signing is set per-flavor: talerid -> upload key, dev/prod -> debug
        release {}
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("com.google.mlkit:segmentation-selfie:16.0.0-beta6")
    compileOnly("io.github.webrtc-sdk:android:125.6422.03")
    testImplementation("junit:junit:4.13.2")
}
