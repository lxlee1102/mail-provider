FROM openfalcon/makegcc-golang:1.10-alpine as builder
LABEL maintainer laiwei.ustc@gmail.com
USER root

ENV FALCON_DIR=/open-falcon PROJ_PATH=${GOPATH}/src/github.com/open-falcon/mail-provider

RUN mkdir -p $FALCON_DIR && \
    mkdir -p $FALCON_DIR/mail/config && \
    mkdir -p $FALCON_DIR/mail/bin && \
    mkdir -p $FALCON_DIR/mail/var && \
    mkdir -p $PROJ_PATH && \
    apk add --no-cache ca-certificates bash git

COPY . ${PROJ_PATH}
WORKDIR ${PROJ_PATH}
RUN go get ./... && \
    ./control build  && \
    cp -f falcon-mail $FALCON_DIR/mail/bin/falcon-mail && \
    cp -f cmdocker/mail.tpl $FALCON_DIR/mail/ && \
    cp -f cmdocker/falcon-entry.sh $FALCON_DIR/ && \
    cp -f cmdocker/localtime.shanghai $FALCON_DIR/ && \
    rm -rf ${PROJ_PATH}

WORKDIR $FALCON_DIR
RUN tar -czf falcon-mail.tar.gz ./


FROM harbor.cloudminds.com/library/alpine:3.CM-Beta-1.3
USER root

ENV PROJECT=mcs MODULE=falcon-mail LOGPATH=

ENV FALCON_DIR=/open-falcon FALCON_MODULE=mail

RUN mkdir -p $FALCON_DIR && \
    apk add --no-cache ca-certificates bash util-linux tcpdump busybox-extras

WORKDIR $FALCON_DIR

COPY --from=0  $FALCON_DIR/falcon-mail.tar.gz  $FALCON_DIR/
COPY --from=0  $FALCON_DIR/localtime.shanghai  $FALCON_DIR/
RUN tar -zxf falcon-mail.tar.gz && \
    rm -rf falcon-mail.tar.gz && \
    mv localtime.shanghai /etc/localtime

EXPOSE 4000

# create config-files by ENV
CMD ["./falcon-entry.sh"]

#CMD ["/open-falcon/mail/bin/falcon-mail", "-c", "/open-falcon/mail/config/cfg.json"]

