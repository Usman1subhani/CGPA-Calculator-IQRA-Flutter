import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android Gradle Plugin.
    id("dev.flutter.flutter-gradle-plugin")
}

val selectedApplicationId = providers.gradleProperty("applicationId").orNull
    ?: "com.usmansubhani.iu_gpacalculator"
val keyPropertiesFile = rootProject.file("key.properties")
val keyProperties = Properties()
if (keyPropertiesFile.exists()) {
    keyPropertiesFile.inputStream().use { keyProperties.load(it) }
}

val verifyReleaseConfiguration = tasks.register("verifyReleaseConfiguration") {
    doLast {
        val validApplicationId = selectedApplicationId.split(".").let { parts ->
            parts.size >= 2 && parts.all {
                it.matches(Regex("[A-Za-z][A-Za-z0-9_]*"))
            }
        }
        check(validApplicationId && !selectedApplicationId.startsWith("com.example")) {
            "Set a permanent applicationId with -PapplicationId=<your.unique.package.id> before building a release."
        }

        val requiredKeys = listOf(
            "storeFile",
            "storePassword",
            "keyAlias",
            "keyPassword",
        )
        val missingKeys = requiredKeys.filter { keyProperties.getProperty(it).isNullOrBlank() }
        check(keyPropertiesFile.exists() && missingKeys.isEmpty()) {
            "Configure android/key.properties with storeFile, storePassword, keyAlias, and keyPassword before building a release."
        }
        check(rootProject.file(keyProperties.getProperty("storeFile")).isFile) {
            "The keystore file configured by android/key.properties does not exist."
        }
    }
}

tasks.configureEach {
    if (name.startsWith("assembleRelease") || name.startsWith("bundleRelease")) {
        dependsOn(verifyReleaseConfiguration)
    }
}

android {
    namespace = "com.usmansubhani.iu_gpacalculator"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = selectedApplicationId
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val storeFilePath = keyProperties.getProperty("storeFile")
            if (!storeFilePath.isNullOrBlank()) {
                storeFile = rootProject.file(storeFilePath)
                storePassword = keyProperties.getProperty("storePassword")
                keyAlias = keyProperties.getProperty("keyAlias")
                keyPassword = keyProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
