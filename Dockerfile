ARG VERSION=v0.11.3-beta

FROM golang:1.13-alpine as builder

ARG VERSION

# Force Go to use the cgo based DNS resolver. This is required to ensure DNS
# queries required to connect to linked containers succeed.
ENV GODEBUG netdns=cgo

# Explicitly turn on the use of modules (until this becomes the default).
ENV GO111MODULE on

# Install dependencies and install/build lnd.
RUN apk add --no-cache --update alpine-sdk \
    git \
    make \
&&  git clone --branch $VERSION https://github.com/lightninglabs/loop /go/src/github.com/lightningnetwork/loop \
&&  cd /go/src/github.com/lightningnetwork/loop/cmd \
&&  go install ./...

# Start a new, final image to reduce size.
FROM alpine as final

# Add bash.
RUN apk add --no-cache \
    bash \
    ca-certificates

USER 1000

# Expose lnd ports (server, rpc).
EXPOSE 8081 11010

# Copy the binaries and entrypoint from the builder image.
COPY --from=builder /go/bin/loopd /bin/
COPY --from=builder /go/bin/loop /bin/

ENTRYPOINT [ "/bin/loopd" ]
