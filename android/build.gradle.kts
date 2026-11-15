import com.android.build.api.dsl.LibraryExtension

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// agora_rtc_engine reads this root extra property and otherwise falls back
// to compileSdk 31, which is too old for its AndroidX dependencies.
extra["compileSdkVersion"] = 36

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    // Some Flutter Android library plugins (including agora_rtc_engine)
    // declare an older compileSdk in their own build scripts. Apply the
    // override after project evaluation so it wins over plugin defaults.
    afterEvaluate {
        if (plugins.hasPlugin("com.android.library")) {
            extensions.configure<LibraryExtension> {
                compileSdk = 36
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// Stripe's Issuing push-provisioning artifact declares Google's private
// play-services-tapandpay SDK as a runtime dependency. AGP 9's release lint
// classpath resolves that runtime dependency even though this app only uses
// standard Stripe payments and does not use Issuing push provisioning.
// The TapAndPay SDK is not published to public Maven repositories, so remove
// it from this Stripe library's metadata to keep release lint resolvable.
subprojects {
    if (name == "stripe_android") {
        dependencies.components.withModule("com.stripe:stripe-android-issuing-push-provisioning") {
            allVariants {
                withDependencies {
                    removeAll {
                        it.group == "com.google.android.gms" &&
                            it.name == "play-services-tapandpay"
                    }
                }
            }
        }
    }
}
