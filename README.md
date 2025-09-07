# fuego Image

[![Build Container](https://github.com/fixl/docker-fuego/actions/workflows/build.yml/badge.svg)](https://github.com/fixl/docker-fuego/actions/workflows/build.yml)
[![version](https://fixl.github.io/docker-fuego/version.svg)](https://github.com/fixl/docker-fuego/commits/main/)
[![size](https://fixl.github.io/docker-fuego/size.svg)](https://github.com/fixl/docker-fuego/commits/main/)
[![Docker Pulls](https://img.shields.io/docker/pulls/fixl/fuego)](https://hub.docker.com/r/fixl/fuego)
[![Docker Stars](https://img.shields.io/docker/stars/fixl/fuego)](https://hub.docker.com/r/fixl/fuego)

A Docker container containing [fuego](https://github.com/sgarciac/fuego), a command-line firestore client.


## Build the image

```bash
make build
```

## Inspect the image

```bash
docker inspect --format='{{ range $k, $v := .Config.Labels }}{{ printf "%s=%s\n" $k $v}}{{ end }}' fixl/fuego:latest
```

## Usage

```bash
docker run --rm -it fixl/fuego

docker run --rm -it --net=host --env FIRESTORE_EMULATOR_HOST=localhost:8080 fixl/fuego collections
```
