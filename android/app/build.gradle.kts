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

// Local builds read a properties file from android/ or android/app/.
// Accept common Windows duplicate/extension variants to avoid silently missing
// credentials when Explorer hides file extensions.
val keystoreProperties = Properties()
val keystorePropertiesCandidates = listOf(
    rootProject.file("key.properties"),
    project.file("key.properties"),
    rootProject.file("key(1).properties"),
    project.file("key(1).properties"),
    rootProject.file("key.properties.txt"),
    project.file("key.properties.txt"),
    rootProject.file("keystore.properties"),
    project.file("keystore.properties")
)
val keystorePropertiesFile = keystorePropertiesCandidates.firstOrNull { it.isFile }

if (keystorePropertiesFile != null) {
    keystorePropertiesFile.reader(Charsets.UTF_8).use(keystoreProperties::load)
}

fun signingValue(environmentName: String, propertyName: String): String? =
    System.getenv(environmentName)?.trim()?.takeIf(String::isNotEmpty)
        ?: keystoreProperties.getProperty(propertyName)?.trim()?.takeIf(String::isNotEmpty)

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
            val defaultLocalKeystore = listOf(
                project.file("keystore.jks"),
                project.file("upload-keystore.jks"),
                rootProject.file("app/keystore.jks"),
                rootProject.file("app/upload-keystore.jks")
            ).firstOrNull { it.isFile }

            storeFile = when {
                !System.getenv("ANDROID_KEYSTORE_PATH").isNullOrBlank() -> {
                    // CI's ANDROID_KEYSTORE_PATH is relative to the repository root.
                    val configuredFile = File(configuredStoreFile!!)
                    if (configuredFile.isAbsolute) configuredFile
                    else rootProject.projectDir.parentFile.resolve(configuredFile)
                }
                !configuredStoreFile.isNullOrBlank() -> {
                    // Local key.properties paths are relative to android/app.
                    file(configuredStoreFile)
                }
                defaultLocalKeystore != null -> defaultLocalKeystore
                else -> throw GradleException(
                    "Release keystore not found. Checked android/app/keystore.jks and android/app/upload-keystore.jks. " +
                        "Set storeFile in key.properties or ANDROID_KEYSTORE_PATH."
                )
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
            if (keystorePropertiesFile == null &&
                System.getenv("ANDROID_KEYSTORE_PASSWORD").isNullOrBlank()) {
                throw GradleException(
                    "No signing properties file was loaded. Checked android/key.properties, android/app/key.properties, " +
                        "key(1).properties, key.properties.txt and keystore.properties. " +
                        "Create android/key.properties with storePassword, keyPassword, keyAlias and storeFile."
                )
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
