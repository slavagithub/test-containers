#!/bin/bash
PID=0
sigterm_handler() {
  echo "Hazelcast Term Handler received shutdown signal. Signaling hazelcast instance on PID: ${PID}"
  if [ ${PID} -ne 0 ]; then
    kill -15 "${PID}"
  fi
  sleep 30
}

PRG="$0"
PRGDIR=`dirname "$PRG"`
HAZELCAST_HOME=`cd "$PRGDIR/.." >/dev/null; pwd`/hazelcast
PID_FILE=$HAZELCAST_HOME/hazelcast_instance.pid

if [ "x$MIN_HEAP_SIZE" != "x" ]; then
	JAVA_OPTS="$JAVA_OPTS -Xms${MIN_HEAP_SIZE}"
fi

if [ "x$MAX_HEAP_SIZE" != "x" ]; then
	JAVA_OPTS="$JAVA_OPTS -Xmx${MAX_HEAP_SIZE}"
fi

if [ "x$WAN_PUBLIC_IP" != "x" ]; then
    JAVA_OPTS="$JAVA_OPTS -DWAN_PUBLIC_IP=${WAN_PUBLIC_IP}"
fi

# disable phone home
JAVA_OPTS="$JAVA_OPTS -Dhazelcast.phone.home.enabled=false"

# adding license key property
export L_KEY=${license_env_key}
JAVA_OPTS="$JAVA_OPTS -Dhazelcast.enterprise.license.key=$L_KEY"

# if we receive SIGTERM (from docker stop) or SIGINT (ctrl+c if not running as daemon)
# trap the signal and delegate to sigterm_handler function, which will notify hazelcast instance process
trap sigterm_handler SIGTERM SIGINT

export CLASSPATH=$HAZELCAST_HOME/*:$CLASSPATH

# Set debug options if required
if [ x"${JAVA_ENABLE_DEBUG}" != x ] && [ "${JAVA_ENABLE_DEBUG}" != "false" ]; then
    java_debug_args="-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=${JAVA_DEBUG_PORT:-5005}"
fi

echo "########################################"
echo "# RUN_JAVA=$RUN_JAVA"
echo "# JAVA_OPTS=$JAVA_OPTS"
echo "# CLASSPATH=$CLASSPATH"
echo "# starting now...."
echo "########################################"

exec java -server $JAVA_OPTS ${java_debug_args} vs.example.SimpleServer &
PID="$!"
echo "Process id ${PID} for hazelcast instance is written to location: " $PID_FILE
echo ${PID} > ${PID_FILE}

# wait on hazelcast instance process
wait ${PID}
# if a signal came up, remove previous traps on signals and wait again (noop if process stopped already)
trap - SIGTERM SIGINT
wait ${PID}

