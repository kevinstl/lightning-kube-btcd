FROM golang:1.11-alpine as builder

MAINTAINER Olaoluwa Osuntokun <laolu@lightning.network>

# Install build dependencies such as git and glide.
RUN apk add --no-cache git gcc musl-dev

WORKDIR $GOPATH/src/github.com/btcsuite/btcd

# Grab and install the latest version of of btcd and all related dependencies.
RUN git clone https://github.com/btcsuite/btcd.git . \
    &&  GO111MODULE=on go install -v . ./cmd/...

# Start a new image
FROM alpine as final

# Expose mainnet ports (server, rpc)
EXPOSE 8333 8334

# Expose testnet ports (server, rpc)
EXPOSE 18333 18334

# Expose simnet ports (server, rpc)
EXPOSE 18555 18556

# Expose segnet ports (server, rpc)
EXPOSE 28901 28902

# Copy the compiled binaries from the builder image.
COPY --from=builder /go/bin/addblock /bin/
COPY --from=builder /go/bin/btcctl /bin/
COPY --from=builder /go/bin/btcd /bin/
COPY --from=builder /go/bin/findcheckpoint /bin/
COPY --from=builder /go/bin/gencerts /bin/

COPY "start-btcctl.sh" .
COPY "start-btcd.sh" .

RUN apk add --no-cache \
    bash \
    ca-certificates \
&&  mkdir "/rpc" "/root/.btcd" "/root/.btcctl" \
&&  touch "/root/.btcd/btcd.conf" \
&&  chmod +x start-btcctl.sh \
&&  chmod +x start-btcd.sh
#\
# Manually generate certificate and add all domains, it is needed to connect
# "btcctl" and "lnd" to "btcd" over docker links.
#&& "/bin/gencerts" --host="*" --directory="/rpc" --force
#&&  mkdir -p "/mnt/lk/shared/rpc" \
#&&  mkdir -p "/mnt/lk/shared/rpc"
#&& "/bin/gencerts" --host="*" --directory="/mnt/lk/shared/rpc" --force

# Create a volume to house pregenerated RPC credentials. This will be
# shared with any lnd, btcctl containers so they can securely query btcd's RPC
# server.
# You should NOT do this before certificate generation!
# Otherwise manually generated certificate will be overridden with shared
# mounted volume! For more info read dockerfile "VOLUME" documentation.
VOLUME ["/rpc"]


#RUN mkdir /mnt/lk
#RUN chmod -R 777 /mnt/lk
#RUN chown -R btcd /mnt/lk

RUN apk add --no-cache sudo

RUN adduser -u 501 -S btcd
RUN adduser btcd sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER btcd

#ARG UNAME=kevin
#ARG UID=501
#ARG GID=20
##RUN addgroup -g $GID -o $UNAME
#RUN adduser -m -u $UID -g $GID -o -s /bin/bash $UNAME
#USER $UNAME



ENTRYPOINT ["/start-btcd.sh"]



