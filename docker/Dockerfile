FROM docker.io/alpine:3.11

EXPOSE 8000

RUN apk add --no-cache build-base curl git

# Create a non-root user to run the app as
ARG USER=app
ARG GROUP=app
ARG UID=1101
ARG GID=1101
ARG JANET=1.27.0

RUN addgroup -g $GID -S $GROUP
RUN adduser -u $UID -S $USER -G $GROUP

# Move to tmp and install janet
RUN git clone --depth 1 --branch v$JANET https://github.com/janet-lang/janet.git /tmp/janet && \
    cd /tmp/janet && \
    make all test install

# Install jpm
RUN git clone --depth 1 https://github.com/janet-lang/jpm.git /tmp/jpm && \
    cd /tmp/jpm && \
    janet bootstrap.janet

RUN chmod 777 /usr/local/lib/janet

# Use jpm to install joy

RUN jpm install joy

RUN chown -R $USER:$GROUP /usr/local/lib/janet/joy

# Create a place to mount or copy in your server
RUN mkdir -p /var/app
RUN chown -R $USER:$GROUP /var/app

USER $USER
WORKDIR /var/app
