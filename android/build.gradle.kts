allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}
subprojects {
    val configureAndroid = {
        val android = extensions.findByName("android")
        if (android != null) {
            var success = false
            for (method in android.javaClass.methods) {
                val name = method.name
                if (name == "compileSdkVersion" || name == "setCompileSdkVersion" || name == "compileSdk" || name == "setCompileSdk") {
                    val params = method.parameterTypes
                    if (params.size == 1 && (params[0] == Int::class.javaPrimitiveType || params[0] == java.lang.Integer::class.java)) {
                        try {
                            method.invoke(android, 36)
                            success = true
                            println("[salin] Configured ${project.name} compileSdkVersion to 36 via method: ${method.name}")
                        } catch (e: Exception) {
                            // try others
                        }
                    }
                }
            }
            if (!success) {
                println("[salin] WARNING: Failed to configure compileSdkVersion to 36 for subproject ${project.name}")
            }
        }
    }
    if (project.state.executed) {
        configureAndroid()
    } else {
        project.afterEvaluate {
            configureAndroid()
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
