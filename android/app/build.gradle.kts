plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.slinkr"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // LÍNEA 1 DE LA SOLUCIÓN (con la sintaxis correcta)
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        applicationId = "com.flurian.slinkr"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = 1 // Reemplazamos las variables que daban error por valores fijos
        versionName = "1.0" // Reemplazamos las variables que daban error por valores fijos
        // Línea extra de seguridad para compatibilidad
        multiDexEnabled = true
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
    // LÍNEA 2 DE LA SOLUCIÓN (con la sintaxis correcta)
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}