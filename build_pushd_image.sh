#!/bin/sh

docker build -f stoatchat-0.11.1-ha-patch/Dockerfile.userCurrentArch -t ha-stoat-pushd:v0.11.1
docker save ha-stoat-pushd:v0.11.1 ha-stoatchat-pushd.tar
