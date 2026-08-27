import java.io.FileInputStream
import java.util.Base64
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseSigning = keystorePropertiesFile.exists()

if (hasReleaseSigning) {
    FileInputStream(keystorePropertiesFile).use(keystoreProperties::load)
}

// Flutter forwards --dart-define values to Gradle as comma-separated,
// base64-encoded KEY=VALUE entries. Expose the Firebase client identifiers as
// Android string resources as well as Dart constants so FirebaseInitProvider,
// Analytics and Messaging can initialize before the Flutter engine starts.
val dartDefines =
    (project.findProperty("dart-defines") as? String)
        ?.split(',')
        ?.mapNotNull { encoded ->
            runCatching {
                String(Base64.getDecoder().decode(encoded), Charsets.UTF_8)
            }.getOrNull()
        }
        ?.mapNotNull { define ->
            val separator = define.indexOf('=')
            if (separator <= 0) null else define.substring(0, separator) to define.substring(separator + 1)
        }
        ?.toMap()
        .orEmpty()

android {
    namespace = "com.mediguide.ug"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.mediguide.ug"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        resValue("string", "google_app_id", dartDefines["FIREBASE_ANDROID_APP_ID"].orEmpty())
        resValue("string", "google_api_key", dartDefines["FIREBASE_API_KEY"].orEmpty())
        resValue(
            "string",
            "gcm_defaultSenderId",
            dartDefines["FIREBASE_MESSAGING_SENDER_ID"].orEmpty(),
        )
        resValue("string", "project_id", dartDefines["FIREBASE_PROJECT_ID"].orEmpty())
    }

    flavorDimensions += "environment"
    productFlavors {
        create("development") {
            dimension = "environment"
            applicationIdSuffix = ".dev"
            manifestPlaceholders["appName"] = "MediGuide Dev"
        }
        create("staging") {
            dimension = "environment"
            applicationIdSuffix = ".staging"
            manifestPlaceholders["appName"] = "MediGuide Staging"
        }
        create("production") {
            dimension = "environment"
            manifestPlaceholders["appName"] = "MediGuide"
        }
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            // Local release-mode builds may use the debug key, but the tag
            // workflow requires key.properties and a private upload keystore.
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}
