#!/system/bin/sh
PKG="com.tepari.macrostock.macrostock_starter"
USER_ID=0
LOG="/data/local/tmp/macrostock_wifi_approve.log"

# Log uid so we can confirm it's root here
id >> "$LOG"
echo "$(date) start approve script" >> "$LOG"

# Wait for user-0 unlocked (handles "1" OR "true")
for i in $(seq 1 120); do
  v=$(getprop sys.user.0.ce_available)
  [ "$v" = "1" ] || [ "$v" = "true" ] && break
  sleep 1
done
echo "$(date) user0 unlocked=$(getprop sys.user.0.ce_available)" >> "$LOG"

# Ensure package is installed for user 0
for i in $(seq 1 60); do
  pm path --user $USER_ID "$PKG" >/dev/null 2>&1 && break
  sleep 1
done
echo "$(date) pm path: $(pm path --user $USER_ID "$PKG" 2>&1)" >> "$LOG"

# Ensure cmd wifi responds
for i in $(seq 1 60); do
  cmd wifi help >/dev/null 2>&1 && break
  sleep 1
end
echo "$(date) cmd wifi responsive=$?" >> "$LOG"

# Optional: enable wifi once (some BSPs need a first toggle)
svc wifi enable 2>/dev/null
sleep 2

# Try to set + verify (root required!)
for i in $(seq 1 30); do
  OUT_SET=$(cmd wifi nesystemtwork-suggestions-set-user-approved "$PKG" yes --user $USER_ID 2>&1; echo "rc=$?")
  OUT_HAS=$(cmd wifi network-suggestions-has-user-approved "$PKG" --user $USER_ID 2>&1)
  echo "$(date) attempt $i: SET='$OUT_SET' HAS='$OUT_HAS'" >> "$LOG"
  if [ "$OUT_HAS" = "yes" ]; then
    setprop persist.sys.macrostock_wifi_sugg_approved 1
    echo "$(date) SUCCESS; sticky prop set" >> "$LOG"
    exit 0
  fi
  sleep 2
done

echo "$(date) FAILED after retries" >> "$LOG"
exit 1
