#!/usr/bin/env bash
JDK_HOME=/home/derek/.jdks/corretto-22.0.2
#PATH="${PATH}:~/.jdks/corretto-22.0.2/bin"

podman-compose -f ./docker-compose.local.yml down
podman-compose -f ./docker-compose.local.yml up -d --replace

./gradlew -Dorg.gradle.java.home=$JDK_HOME build --continuous &

sleep 15;

./gradlew -Dorg.gradle.java.home=$JDK_HOME startAll --Pspring.profiles.active="local"
