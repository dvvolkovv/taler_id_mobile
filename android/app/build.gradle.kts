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
            // Three-track naming (1.1.1+): app icon shows the environment so
            // testers don't mix builds. DEV=aeza staging, TEST=aeza prod
            // (legacy bundle, kept for existing installs until DO cutover),
            // no-prefix=DO prod (io.talerid.app).
            resValue("string", "app_name", "DEV Taler ID")
            signingConfig = signingConfigs.getByName("debug")
        }
        create("prod") {
            dimension = "environment"
            applicationId = "tirol.taler.taler_id_mobile"
            // aeza prod track repositioned as TEST. Existing users upgrading
            // from 1.1.0 will see their icon name change to "TEST Taler ID"
            // — release notes explain the new three-track layout.
            resValue("string", "app_name", "TEST Taler ID")
            signingConfig = signingConfigs.getByName("debug")
        }
        create("talerid") {
            dimension = "environment"
            applicationId = "io.talerid.app"
            // DO production — canonical "Taler ID" with no prefix.
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
