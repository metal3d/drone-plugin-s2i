# Drone.io plugin to build images with s2i

[Source to image](https://github.com/openshift/source-to-image), aka "s2i", is a Red Hat project originaly created to build images from sources without the need of a Dockerfile, made for Openshit/OKD (see https://www.openshift.com/ and the community version https://www.okd.io/)

[Drone](https://drone.io) is a CI/CD solution that can run on Docker and Kubernetes.

To be able to have the same build solution, you need this plugin.

## Usage

In your .drone.yml file, you can use `metal3d/drone-plugin-s2i` - you can use that paramters:

- `image` (mandatory) is the "s2i" image that assembles the `target` image
- `target` (mandatory) is the target image built with s2i `image`
- `push` (boolean, default to false) will push your image after the build
- `context` (string, default to "./") is the context directory inside you repository
- `incremental` (boolean, default to false) perform an incremental build if possible
- `registry` is the registry you want to login (login not yet supported)
- `insecure` (boolean, default to false) to use the `registry` as "insecure" (http instead of https)
- `username` if set with `password`, try to authenticate `registry` with that user
- `password` is the password used to authenticate user 


Exemple, with `docker-registry:5000` as a private registry:

New format (v2 tags):
```yaml
kind: pipeline
name: default

steps:
  - name: s2i-build
    image: metal3d/drone-plugin-s2i:v2
    pull: always
    settings:
      registry: docker-registry:5000
      insecure: true
      builder: docker-registry:5000/metal3d/nginx:1.15-s2i 
      target: docker-registry:5000/metal3d/httptest
      tags:
        - latest
        - ${DRONE_TAG}
      push: true
      context: "./src"
      increental: false
      user:
        from_secret: registry-username
      password:
        from_secret: registry-password
```


Old format (v1 tags):

```yaml
kind: pipeline
name: default

steps:
  - name: s2i-build
    image: metal3d/drone-plugin-s2i:v1
    pull: always
    settings:
      registry: docker-registry:5000
      insecure: true
      image: docker-registry:5000/metal3d/nginx:1.15-s2i 
      target: docker-registry:5000/metal3d/httptest
      push: true
      context: "./src"
      increental: false
```

Note that in kubernetes, "docker-registry" can be the service name of your private registry. For example, if your service `docker-registry` resides in the "registry" namespace, you can use `docker-registry.registry:5000`.

## Privileged mode

As we need docker daemon to be launched, you'll need to use "`privileged: true`". That means that the repository should be trusted.

To avoid that, you can add the plugin to `DRONE_RUNNER_PRIVILEGED_IMAGES`:

```
DRONE_RUNNER_PRIVILEGED_IMAGES=plugins/docker,plugins/ecr,metal3d/drone-plugin-s2i
```

That way, you will not need to set privileged mode, and others users will be able to build images with s2i.
