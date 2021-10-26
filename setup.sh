#!/usr/bin/env bash

echo preparing image with test server...
mvn -B -q clean package -DskipTests
cd docker-build/
cp ../target/test-containers-*-jar-with-dependencies.jar .
docker build . -t vs:simple-server -q

echo bootstrap completed, happy hacking...

