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
        doLast {
            System.err.println('TEST MESSAGE: cleanTest done!')
        }
    }
}
