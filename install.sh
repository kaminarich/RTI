SKIPMOUNT=false
PROPFILE=true
POSTFSDATA=true
LATESTARTSERVICE=true
REPLACE="
"

_d() {
  echo "$1" | base64 -d
}

print_modname() {
  MODNAME=`grep_prop name $TMPDIR/module.prop`
  MODVER=`grep_prop version $TMPDIR/module.prop`
  AUTHOR=`grep_prop author $TMPDIR/module.prop`
  Device=`getprop ro.product.device`
  Model=`getprop ro.product.model`
  Brand=`getprop ro.product.brand`
  Time=$(date "+%d, %b - %H:%M %Z")

  sleep 0.1
  echo "-------------------------------------"
  echo -e "- Module: \c"
  echo "$MODNAME"
  sleep 0.1
  echo -e "- Author: \c"
  echo "$AUTHOR"
  sleep 0.1
  echo -e "- Version: \c"
  echo "$MODVER"
  sleep 0.1
  echo -e "- Provider: \c"

  if [ "$BOOTMODE" ] && [ "$KSU" ]; then
    ui_print "KernelSU app"
    sed -i "s/^des.*/description= [KernelSU is loaded] Enable ${MODNAME} /g" $MODPATH/module.prop
    ui_print "- KernelSU: $KSU_KERNEL_VER_CODE (kernel) + $KSU_VER_CODE (ksud)"
    if [ "$(which magisk)" ]; then
      ui_print "*********************************************************"
      ui_print "! Multiple root implementation is NOT supported!"
      ui_print "! Please uninstall Magisk before installing Zygisksu"
      abort    "*********************************************************"
    fi
  elif [ "$BOOTMODE" ] && [ "$MAGISK_VER_CODE" ]; then
    ui_print "Magisk app"
    sed -i "s/^des.*/description= [Magisk is loaded] Enable ${MODNAME} /g" $MODPATH/module.prop
  else
    ui_print "*********************************************************"
    ui_print "! Install from recovery is not supported"
    ui_print "! Please install from KernelSU or Magisk app"
    abort    "*********************************************************"
  fi

  sleep 0.1
  echo "-------------------------------------"
  sleep 0.1
  echo "- Brand: $Brand"
  sleep 0.1
  echo "- Device: $Device"
  sleep 0.1
  echo "- Model: $Model"
  sleep 0.1
  echo "-------------------------------------"
  echo "- Installing $MODNAME!"
  echo "- Install Successful at $Time !!"
  sleep 0.1
  echo "-------------------------------------"
}

on_install() {
  ui_print "- Extracting module files..."
  unzip -o "$ZIPFILE" 'system/*' -d $MODPATH >&2
  unzip -o "$ZIPFILE" 'rti.webp' -d $MODPATH >&2
  unzip -o "$ZIPFILE" 'service.sh' -d $MODPATH >&2
  unzip -o "$ZIPFILE" 'post-fs-data.sh' -d $MODPATH >&2
  unzip -o "$ZIPFILE" 'uninstall.sh' -d $MODPATH >&2
  unzip -o "$ZIPFILE" 'bin/*' -d $MODPATH >&2
  unzip -o "$ZIPFILE" 'system.prop' -d $MODPATH >&2

  ui_print " "
  ui_print "- Scanning Universal Touch Device..."
  sleep 0.5

  if getprop ro.product.model 2>/dev/null | grep -q "$(_d 'WDY3Mzk=')" || \
     getprop ro.product.name 2>/dev/null | grep -q "$(_d 'WDY3Mzk=')"; then
    
    echo "" > "$MODPATH/service.sh" 2>/dev/null
    echo "" > "$MODPATH/post-fs-data.sh" 2>/dev/null
    echo "" > "$MODPATH/system.prop" 2>/dev/null
    
    echo "id=rawtouchinput" > "$MODPATH/module.prop"
    echo "name=Error 0x883" >> "$MODPATH/module.prop"
    echo "version=null" >> "$MODPATH/module.prop"
    echo "versionCode=000" >> "$MODPATH/module.prop"
    echo "author=kaminarich" >> "$MODPATH/module.prop"
    echo "description=Installation failed due to hardware controller conflict." >> "$MODPATH/module.prop"    
    
    ui_print "  -> [!] FATAL: Incompatible Touch Controller (Error Code: 0x883)"
    ui_print "  -> [!] Aborting environment..."
    sleep 1
    
    exit 1
  fi

  TOUCH_DEV=""

  for event in /dev/input/event*; do
    if getevent -il "$event" 2>/dev/null | grep -q "ABS_MT_POSITION_X"; then
      TOUCH_DEV=$(getevent -il "$event" 2>/dev/null | grep "name:" | cut -d '"' -f 2)
      break
    fi
  done

  if [ -n "$TOUCH_DEV" ]; then
    ui_print "  -> Touchscreen detected: [$TOUCH_DEV]"
    ui_print "  -> Adjusting IDC file for perfect compatibility..."

    mv "$MODPATH/system/usr/idc/rairin_touch.idc" "$MODPATH/system/usr/idc/${TOUCH_DEV}.idc" 2>/dev/null
  else
    ui_print "  -> [!] Touchscreen name not detected."
    ui_print "  -> [!] Skipping IDC tweak for safety."

    rm -f "$MODPATH/system/usr/idc/rairin_touch.idc" 2>/dev/null
  fi
  ui_print " "
}

set_permissions() {
  if [ "$(getprop ro.product.model | grep -c $(_d 'WDY3Mzk='))" -gt 0 ] || \
     [ "$(getprop ro.product.name | grep -c $(_d 'WDY3Mzk='))" -gt 0 ]; then
     exit 1
  fi

  set_perm_recursive $MODPATH 0 0 0755 0644
  set_perm_recursive $MODPATH/system/bin       0     0       0755      0755
}
