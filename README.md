# fuego Image

[![pipeline status](https://gitlab.com/fixl/docker-fuego/badges/master/pipeline.svg)](https://gitlab.com/fixl/docker-fuego/-/commits/master)
[![version](https://fixl.gitlab.io/docker-fuego/version.svg)](https://gitlab.com/fixl/docker-fuego/-/commits/master)
[![size](https://fixl.gitlab.io/docker-fuego/size.svg)](https://gitlab.com/fixl/docker-fuego/-/commits/master)
[![Docker Pulls](https://img.shields.io/docker/pulls/fixl/fuego)](https://hub.docker.com/r/fixl/fuego)
[![Docker Pulls](https://img.shields.io/docker/stars/fixl/fuego)](https://hub.docker.com/r/fixl/fuego)

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
