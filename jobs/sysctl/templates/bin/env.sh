JOB=sysctl
JOB_DIR="/var/vcap/jobs/$JOB"
RUN_DIR="/var/vcap/sys/run/$JOB"
LOG_DIR="/var/vcap/sys/log/$JOB"
PIDFILE="$RUN_DIR/pid"

mkdir -p "$JOB_DIR" "$LOG_DIR" "$RUN_DIR"

# send the logs 1) to log file (with timestamp), 2) to syslog and 3) to stdout/stderr
if [ -z "$SUBJOB" ]; then
  SUB=""
  SUBJOB="$JOB"
else
  SUB=".$SUBJOB"
fi

# TODO: replace awk with ts when ts becomes available in the stemcell
# TODO: add --id=$$ to logger, when logger gains support for --id=<PID>
exec -- \
  1> >(
    exec -a "$JOB$SUB stdout forwarder" tee \
      >(awk -W interactive "{ \"date -Ins\" | getline TS; close(\"date -Ins\"); print TS, \"$$ OUT\", \$0 }" >>"$LOG_DIR/$SUBJOB.log") \
      >(logger -p user.info  -t "vcap.$JOB$SUB")
  ) \
  2> >(
    exec -a "$JOB$SUB stderr forwarder" tee \
      >(awk -W interactive "{ \"date -Ins\" | getline TS; close(\"date -Ins\"); print TS, \"$$ ERR\", \$0 }" >>"$LOG_DIR/$SUBJOB.log") \
      >(logger -p user.error -t "vcap.$JOB$SUB") \
      1>&2
  )
