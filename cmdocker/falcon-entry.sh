#!/bin/sh

DOCKER_DIR=/open-falcon
of_bin=$DOCKER_DIR/open-falcon
DOCKER_HOST_IP=$(route -n | awk '/UG[ \t]/{print $2}')


if [ -z $SMTP_SERVER ]; then
	SMTP_SERVER=smtp.exmail.qq.com
fi


reset_cfg() {
	cp $DOCKER_DIR/mail/mail.tpl $DOCKER_DIR/mail/config/cfg.json

	find $DOCKER_DIR/*/config/*.json -type f -exec sed -i "s/%%SMTP_SERVER%%/$SMTP_SERVER/g" {} \;
	find $DOCKER_DIR/*/config/*.json -type f -exec sed -i "s/%%USERNAME%%/$USERNAME/g" {} \;
	find $DOCKER_DIR/*/config/*.json -type f -exec sed -i "s/%%PASSWD%%/$PASSWD/g" {} \;
	find $DOCKER_DIR/*/config/*.json -type f -exec sed -i "s/%%FROM%%/$FROM/g" {} \;
}


m=$FALCON_MODULE
if [ ! -f $DOCKER_DIR/$m/config/cfg.json ]; then
	reset_cfg
fi

if [ -z "$SYSLOG_SERVER_PORT" ] ; then
        SYSLOG_SERVER_PORT=514
fi

OPT=
if [ -n "$SYSLOG_SERVER_TCP" ] ; then
        OPT=--tcp
fi

if [ -z "$SYSLOG_SERVER_ADDR" ] ; then
        exec $DOCKER_DIR/$m/bin/falcon-$m -c $DOCKER_DIR/$m/config/cfg.json 2>&1
        exit 0
else
        exec $DOCKER_DIR/$m/bin/falcon-$m -c $DOCKER_DIR/$m/config/cfg.json 2>&1 | logger -st falcon-$m --server $SYSLOG_SERVER_ADDR $OPT --port $SYSLOG_SERVER_PORT
        exit 0
fi

#exec "$@"
