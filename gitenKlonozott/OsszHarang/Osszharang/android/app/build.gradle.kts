import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// Kulcsok betöltése a key.properties fájlból
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.ballakeve.osszharang"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973" // Ha ez működik nálad, maradhat, de a flutter.ndkVersion az ajánlott

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // FONTOS: Ennek egyeznie kell azzal, amit a Google Play Console-ban megadtál!
        // Javaslom az egyszerűbb verziót, ha még nem fixáltad le máshogy:
        applicationId = "com.ballakeve.osszharang"

        minSdk = 24 // Ezt érdemes lehet 23-ra vagy 21-re venni a kompatibilitás miatt, de a 24 is oké
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storeFile = keystoreProperties.getProperty("storeFile")?.let { file(it) }
            storePassword = keystoreProperties.getProperty("storePassword")
        }
    }

    buildTypes {
        release {
            // ITT VOLT A HIBA: Debug helyett most már a Release kulcsot használjuk
            signingConfig = signingConfigs.getByName("release")

            // Optimalizálás (kód tömörítése és méretcsökkentés)
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}