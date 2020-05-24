# Deployments

We have some expectations for how joy is deployed, and we mostly operate on these assumptions. Our hope is that joy is fronted by a reverse proxy. We are going to provide you with two examples of this. This guide works on the assumptions you've installed [docker](https://docs.docker.com/engine/install/) and [docker compose](https://docs.docker.com/compose/install/).

## Creating a Joy Container

To get started we have a base Dockerfile we've included. It's available in the root, but documented here:

```dockerfile
FROM alpine:3.7

EXPOSE 8000

RUN apk add --no-cache build-base curl git

# Create a non-root user to run the app as
ARG USER=app
ARG GROUP=app
ARG UID=1101
ARG GID=1101

RUN addgroup -g $GID -S $GROUP
RUN adduser -u $UID -S $USER -G $GROUP

# Move to tmp and install janet
RUN git clone https://github.com/janet-lang/janet.git /tmp/janet && \
    cd /tmp/janet && \
    make all test install

RUN chmod 777 /usr/local/lib/janet

# Use jpm to install joy

RUN jpm install joy

RUN chown -R $USER:$GROUP /usr/local/lib/janet/joy

# Create a place to mount or copy in your server
RUN mkdir -p /var/app
RUN chown -R $USER:$GROUP /var/app

USER $USER
WORKDIR /var/app

```

This file extends `alpine`, a super small light weight linux distro, installs Janet from source, and then installs Joy via [`jpm`](https://janet-lang.org/docs/jpm.html). We are doing this so that we leverage the same tools we indicate to use. This also serves as a nice way to test our `jpm` config and publishing process.

We are currently creating and publishing the container for you under the tag `docker.pkg.github.com/joy-framework/joy/joy-web:latest`. You can pull that at anytime, or follow these instructions to make your own!

## Use with docker compose

All of our docker-compose configurations are assuming that you're placing them in the root of a repo you created with our template, `joy new my-joy-project`. The volume mounts are mapping in those files to your container and starting them!

## Using NGINX and docker compose

NGINX is a great tool for simple and lightweight serving of sites. For HTTPS it's a bit more manual, but that is paid off by how incredibly lightweight it is. We have a base conifg, `docker-compose.nginx.yml` available in our `docker/` folder in the root. To use this file you need to do these steps:

  1. Move `docker-compose.nginx.yml` and `ngingx.conf` to your repo
  1. Replace all occurrences of `<your-website>` with your actual url
  1. Obtain an SSL cert, and place it in a folder called `./certs` and name it `cert.pem`
    * you can change these names and locations as long as you update the volume mount and conf file names

After that simply:

    docker-compose -f docker-compose.nginx.yml up -d

That will get everything all started up for you and allow you to view your site over https.

## Using traefik and docker compose

Traefik is a great tool, though it's very heavy weight, it's feature set more than makes up for it. With this config you'll get SSL, a dashboard for container uptime, and more. It's also far simpler to use, to wit:

  1. Move `docker-compose.traefik.yml` to the root of your repo

After that simply:

    docker-compose -f docker-compose.traefik.yml up -d

Of note, this will create `./letsencrypt` that contains all of the new certs that get created.

## Caveats

There are a lot of complexities outside of just this setup. You need to configure your A records and have your server configured to have 80, 443, 8080 open in the firewall. There's more to it, but if that earlier statement doesn't make sense, you may be reading the wrong guide for your level of experience.
