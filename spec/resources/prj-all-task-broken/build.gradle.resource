plugins {
    id 'java'
}

group 'jp.unaguna.example'
version '1.0-SNAPSHOT'

allprojects {
    repositories {
        mavenCentral()
    }
    afterEvaluate { project ->
        project.tasks.forEach { task ->
            task.doFirst {
                throw new RuntimeException("${task.path} is broken for test")
            }
        }
    }
}
