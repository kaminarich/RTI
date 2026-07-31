#!/system/bin/sh


until [ "$(getprop sys.boot_completed)" = "1" ]; do
    sleep 2
done
sleep 40

log -p i -t RTI "[xnxx] Starting CPU architecture check... [xnxx]"

MODDIR=$(dirname "$0")
ARCH=$(uname -m)

case "$ARCH" in
    aarch64)
        log -p i -t RTI "Architecture detected: $ARCH (64-bit). Executing RTI--aarch64..."
        chmod +x "$MODDIR/bin/RTI--aarch64"        
        "$MODDIR/bin/RTI--aarch64"
        ;;
    arm*|aarch32)
        log -p i -t RTI "Architecture detected: $ARCH (32-bit). Executing RTI--arm..."
        chmod +x "$MODDIR/bin/RTI--arm"       
        "$MODDIR/bin/RTI--arm"
        ;;
    *)

        log -p e -t RTI "ERROR: Architecture $ARCH is not supported!"
        exit 1
        ;;
esac

apply_prop() {
    if command -v resetprop >/dev/null 2>&1; then
        resetprop "$1" "$2"
    else
        setprop "$1" "$2"
    fi
}

apply_prop debug.sf.hw 1
apply_prop debug.egl.hw 1
apply_prop debug.hwui.force_hw_accel true
apply_prop ro.config.enable.hw_accel true
apply_prop persist.sys.composition.type gpu
apply_prop debug.hwui.render_thread true
apply_prop ro.hwui.render_thread true
apply_prop windowsmgr.max_events_per_sec 200
apply_prop view.touch_slop 2
apply_prop view.minimum_fling_velocity 25
apply_prop ro.min_pointer_dur 8

log -p i -t RTI "Sudah CRT"
