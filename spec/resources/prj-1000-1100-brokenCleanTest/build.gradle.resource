plugins {
    id 'java'
}

group 'jp.unaguna.example'
version '1.0-SNAPSHOT'

allprojects {
    repositories {
        mavenCentral()
    }
    cleanTest { task ->
        doFirst {
            throw new RuntimeException("${task.path} is broken for test")
        }
    }
}
