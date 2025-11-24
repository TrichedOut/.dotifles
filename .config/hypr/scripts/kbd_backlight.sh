DEVICE="kbd_backlight"
STEP=16
CURRENT=$(brightnessctl --device="$DEVICE" get)

case "$1" in
  inc)
    NEW=$((CURRENT + STEP))
    if [ $NEW -gt 255 ]; then
      NEW=255
    fi
    ;;

  dec)
    NEW=$((CURRENT - STEP))
    if [ $NEW -lt 0 ]; then
      NEW=0
    fi
    ;;
  get)
    echo "Currently: $CURRENT"
    exit 0
    ;;
  *)
    echo "Usage: $0 [inc|dec|get]"
    exit 1
    ;;
esac

brightnessctl --device="$DEVICE" set $NEW >/dev/null