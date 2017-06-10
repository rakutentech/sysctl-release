JOB=sysctl
JOB_DIR="/var/vcap/jobs/$JOB"
RUN_DIR="/var/vcap/sys/run/$JOB"
LOG_DIR="/var/vcap/sys/log/$JOB"
PIDFILE="$RUN_DIR/pid"

mkdir -p "$JOB_DIR" "$LOG_DIR" "$RUN_DIR"
chown -R vcap:vcap "$JOB_DIR" "$LOG_DIR" "$RUN_DIR"

# send the logs 1) to log file (with timestamp), 2) to syslog and 3) to stdout/stderr
if [ -z "$SUBJOB" ]; then
  SUB=""
  SUBJOB="$JOB"
else
  SUB=".$SUBJOB"
fi
_PID=$PID

exec -- \
  1> >(
    exec -a "$JOB$SUB stdout forwarder" tee \
      >(ts "%Y-%m-%dT%T%z $_PID OUT " >>"$LOG_DIR/$SUBJOB.log") \
      >(logger -p user.info  --id="$_PID" -t "vcap.$JOB$SUB")
  ) \
  2> >(
    exec -a "$JOB$SUB stderr forwarder" tee \
      >(ts "%Y-%m-%dT%T%z $_PID ERR " >>"$LOG_DIR/$SUBJOB.log") \
      >(logger -p user.error --id="$_PID" -t "vcap.$JOB$SUB") \
      1>&2
  )
