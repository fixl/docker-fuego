# fuego Image

[![](https://images.microbadger.com/badges/image/fixl/fuego.svg)](https://microbadger.com/images/fixl/fuego "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/fixl/fuego.svg)](https://microbadger.com/images/fixl/fuego "Get your own version badge on microbadger.com")

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
