import com.android.build.api.dsl.ApplicationExtension
import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import java.io.File
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Local builds read android/key.properties. CI builds can provide the same
// values through GitHub Actions secrets/environment variables.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use(keystoreProperties::load)
}

fun signingValue(environmentName: String, propertyName: String): String? =
    System.getenv(environmentName)?.takeIf(String::isNotBlank)
        ?: keystoreProperties.getProperty(propertyName)?.takeIf(String::isNotBlank)

extensions.configure<ApplicationExtension> {
    namespace = "com.hme.company"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.hme.company"
        // You can update these values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            // Environment variables take precedence for CI; local builds use key.properties.
            val configuredStoreFile = signingValue("ANDROID_KEYSTORE_PATH", "storeFile")
                ?: throw GradleException(
                    "Missing keystore path. Set ANDROID_KEYSTORE_PATH or storeFile in android/key.properties."
                )

            storeFile = if (System.getenv("ANDROID_KEYSTORE_PATH").isNullOrBlank()) {
                // key.properties storeFile is relative to android/app.
                file(configuredStoreFile)
            } else {
                // CI's ANDROID_KEYSTORE_PATH is relative to the repository root.
                val configuredFile = File(configuredStoreFile)
                if (configuredFile.isAbsolute) configuredFile
                else rootProject.projectDir.parentFile.resolve(configuredFile)
            }

            storePassword = signingValue("ANDROID_KEYSTORE_PASSWORD", "storePassword")
                ?: throw GradleException(
                    "Missing keystore password. Set ANDROID_KEYSTORE_PASSWORD or storePassword in android/key.properties."
                )
            keyAlias = signingValue("ANDROID_KEY_ALIAS", "keyAlias")
                ?: throw GradleException(
                    "Missing key alias. Set ANDROID_KEY_ALIAS or keyAlias in android/key.properties."
                )
            keyPassword = signingValue("ANDROID_KEY_PASSWORD", "keyPassword")
                ?: throw GradleException(
                    "Missing private-key password. Set ANDROID_KEY_PASSWORD or keyPassword in android/key.properties."
                )

            if (!storeFile!!.isFile) {
                throw GradleException("Release keystore not found: ${storeFile!!.absolutePath}")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_17)
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

flutter {
    source = "../.."
}
