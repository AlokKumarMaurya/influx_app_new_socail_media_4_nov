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
