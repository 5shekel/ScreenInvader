#!/bin/sh

### BEGIN INIT INFO
# Provides:          xserver
# Required-Start:    thttpd mpd dbus
# Required-Stop:
# Should-Start:
# Should-Stop:
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Starts the xserver without display manager
# Description:
### END INIT INFO

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
DAEMON=/usr/bin/xinit
XINITRC="/lounge/xsession.sh"
XOPTS="-logfile /dev/null :0"
DESC="xserver"
NAME=xserver

PIDFILE=/tmp/Xorg.0.pid

test -x $DAEMON || exit 1

set -e

case "$1" in
	start)
		echo -n "Starting $DESC: "
		bash -c "/usr/bin/xinit /lounge/xsession.sh -- -logfile /dev/null :0" &> /dev/null
		echo "$NAME."
		;;

	stop)
		echo -n "Stopping $DESC: "
		killall awesome
		killall Xorg
		echo "$NAME."
		;;

	force-stop)
		echo -n "Stopping $DESC: "
		start-stop-daemon -K -q -p $PIDFILE -x $DAEMON
		echo "$NAME."
		;;

	force-reload)
		if start-stop-daemon -K -q -p $PIDFILE -x $DAEMON --test
		then
			$0 restart
		fi
		;;

	restart)
		$0 stop
		sleep 1
		$0 start
		;;

	*)
		N=/etc/init.d/$NAME
		echo "Usage: $N {start|stop|force-stop|restart|force-reload}" >&2
		exit 1
		;;
esac

exit 0
