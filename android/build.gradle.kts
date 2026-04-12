allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// Do not use evaluationDependsOn(":app") with dev.flutter.flutter-gradle-plugin —
// it re-enters :app configuration and registers tasks (e.g. generateLockfiles) twice.

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}