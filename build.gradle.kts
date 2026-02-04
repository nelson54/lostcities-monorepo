plugins {
    id("org.owasp.dependencycheck") version "11.0.0"
    id("com.github.rising3.semver") version "0.8.2"
    kotlin("plugin.serialization") version "2.3.+" apply false
    // kotlin("plugin.serialization") version "2.3.0" apply false
}

group = "io.dereknelson"
version = "0.0.1-SNAPSHOT"

extra["commonsLang3.version"] = "3.18.+"
extra["httpclient5.version"] = "5.5.+"
extra["httpcore5.version"] = "5.3.+"
extra["jjwt.version"] = "0.12.+"
extra["springdoc.version"] = "2.5.+"
extra["hibernate.version"] = "6.4.+"
extra["lostcities-common.version"] = "0.0.+"
extra["lostcities-models.version"] = "0.0.+"
extra["ktlint.version"] = "0.49.+"
extra["jedis.version"] = "3.6.2"
extra["snippetsDir"] = file("build/generated-snippets")

tasks.register("buildAll") {
    group = "build"

    val childBuildTasks = childProjects
        .filter { it.value.tasks.findByName("build") != null }
        .map { it.value.tasks.findByName("build") }

    dependsOn(childBuildTasks)
    dependsOn(":lostcities-frontend:build")
}

tasks.register<Exec>("startAll") {
    group = "application"

    val childBootRunTasks = childProjects
        .filter { it.value.tasks.findByName("bootRun") != null }
        .map { it.value.tasks.findByName("bootRun")!! }


    dependsOn(childBootRunTasks)
    dependsOn(":lostcities-frontend:vueRun")
}

