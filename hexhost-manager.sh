cat > /root/patch-hexhost-clean-ui.sh <<'EOF'
#!/bin/bash
set -e

FILE="/opt/hexhost-manager/hexhost-manager.sh"

if [ ! -f "$FILE" ]; then
  echo "Tool file not found: $FILE"
  exit 1
fi

cp "$FILE" "$FILE.backup-ui-$(date +%F_%H-%M-%S)"

python3 <<'PY'
from pathlib import Path

p = Path("/opt/hexhost-manager/hexhost-manager.sh")
s = p.read_text()

marker = "\ncheck_root\nmain_menu"
if marker not in s:
    raise SystemExit("Could not find script ending: check_root / main_menu")

override = r'''

# ==========================================================
# HEXHOST CLEAN UI OVERRIDES
# Simple boxed UI, no overflow, user-friendly display
# ==========================================================

ui_border() {
  echo -e "${RED}${BOLD}+----------------------------------------------------------+${RESET}"
}

ui_center_row() {
  local text="$1"
  local width=56
  local len=${#text}

  if [ "$len" -gt "$width" ]; then
    text="${text:0:$width}"
    len=$width
  fi

  local left=$(( (width - len) / 2 ))
  local right=$(( width - len - left ))

  printf "${RED}${BOLD}|${RESET}${CYAN}${BOLD}%*s%s%*s${RESET}${RED}${BOLD}|${RESET}\n" "$left" "" "$text" "$right" ""
}

ui_row() {
  local text="$1"
  printf "${RED}${BOLD}|${RESET} ${WHITE}${BOLD}%-56.56s${RESET} ${RED}${BOLD}|${RESET}\n" "$text"
}

shorten() {
  local text="$1"
  local max="$2"

  if [ ${#text} -gt "$max" ]; then
    printf "%s..." "${text:0:$((max-3))}"
  else
    printf "%s" "$text"
  fi
}

big_banner() {
  clear
  echo
  ui_border
  ui_center_row "HEXHOST MANAGER"
  ui_center_row "Premium Hosting Automation CLI"
  ui_border
  echo
}

box_title() {
  ui_border
  ui_row "$1"
  ui_border
  echo
}

line() {
  ui_border
}

pause() {
  echo
  echo -e "${GRAY}+----------------------------------------------------------+${RESET}"
  read -p "$(echo -e ${GREEN}${BOLD}'Press ENTER to continue... '${RESET})"
}

menu_item() {
  printf " ${CYAN}${BOLD}[%s]${RESET} ${WHITE}${BOLD}%s${RESET}\n" "$1" "$2"
}

kv() {
  local key
  local val

  key="$(shorten "$1" 12)"
  val="$(shorten "$2" 39)"

  printf "${RED}${BOLD}|${RESET} ${WHITE}${BOLD}%-12s${RESET} ${GRAY}:${RESET} ${CYAN}${BOLD}%-39s${RESET} ${RED}${BOLD}|${RESET}\n" "$key" "$val"
}

wrap_kv() {
  local key="$1"
  local text="$2"
  local width=39
  local first=1
  local line

  if [ -z "$text" ]; then
    kv "$key" "Unknown"
    return
  fi

  while IFS= read -r line || [ -n "$line" ]; do
    if [ "$first" -eq 1 ]; then
      kv "$key" "$line"
      first=0
    else
      kv "" "$line"
    fi
  done < <(printf "%s" "$text" | fold -s -w "$width")
}

status_row() {
  local state="$1"
  local msg="$2"
  local color="$3"

  printf "${RED}${BOLD}|${RESET} ${color}${BOLD}%-8s${RESET} ${WHITE}${BOLD}%-45.45s${RESET} ${RED}${BOLD}|${RESET}\n" "$state" "$msg"
}

service_status_row() {
  local unit="$1"
  local label="$2"
  local warn_mode="$3"

  if systemctl is-active --quiet "$unit" 2>/dev/null; then
    status_row "OK" "$label running" "$GREEN"
  else
    if [ "$warn_mode" = "warn" ]; then
      status_row "WARN" "$label not running" "$YELLOW"
    else
      status_row "DOWN" "$label not running" "$RED"
    fi
  fi
}

database_status_row() {
  if systemctl is-active --quiet mariadb 2>/dev/null; then
    status_row "OK" "MariaDB running" "$GREEN"
  elif systemctl is-active --quiet mysql 2>/dev/null; then
    status_row "OK" "MySQL running" "$GREEN"
  else
    status_row "DOWN" "Database not running" "$RED"
  fi
}

progress_intro() {
  echo
  ui_border
  ui_center_row "INSTALLATION STARTED"
  ui_center_row "Please wait, process is running silently"
  ui_border
  echo
  echo -e "${CYAN}${BOLD}Log file:${RESET} ${WHITE}${BOLD}$LOG_FILE${RESET}"
  echo
}

system_info() {
  big_banner
  box_title "SYSTEM INFORMATION"

  local HOSTNAME
  local IP
  local OS
  local UPTIME
  local CPU
  local RAM
  local DISK

  HOSTNAME="$(hostname -f 2>/dev/null || hostname)"
  IP="$(curl -4 -s --max-time 3 ifconfig.me 2>/dev/null || curl -4 -s --max-time 3 icanhazip.com 2>/dev/null || echo Unknown)"
  OS="$(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"' || echo Unknown)"
  UPTIME="$(uptime -p 2>/dev/null | sed 's/^up //' || echo Unknown)"
  CPU="$(lscpu 2>/dev/null | awk -F: '/Model name/ {gsub(/^[ \t]+/,"",$2); print $2; exit}')"
  CPU="$(echo "$CPU" | sed 's/ BIOS.*//g' | sed 's/[[:space:]]\+/ /g')"
  RAM="$(free -h | awk '/Mem:/ {print $3 " / " $2}')"
  DISK="$(df -h / | awk 'NR==2 {print $3 " / " $2 " used (" $5 ")"}')"

  ui_border
  kv "Hostname" "$HOSTNAME"
  kv "Public IP" "$IP"
  kv "OS" "$OS"
  kv "Uptime" "$UPTIME"
  kv "RAM" "$RAM"
  kv "Disk" "$DISK"
  wrap_kv "CPU" "$CPU"
  ui_border

  echo
  box_title "SERVICE STATUS"

  ui_border
  service_status_row "nginx" "Nginx" "error"
  service_status_row "php8.3-fpm" "PHP-FPM" "error"
  service_status_row "pteroq" "Pteroq" "warn"
  service_status_row "wings" "Wings" "warn"
  database_status_row
  service_status_row "redis-server" "Redis" "warn"
  ui_border

  pause
}

view_logs() {
  big_banner
  box_title "LATEST LOGS"

  if [ ! -f "$LOG_FILE" ]; then
    status_row "INFO" "No logs found yet" "$YELLOW"
    pause
    return
  fi

  tail -n 80 "$LOG_FILE"
  pause
}

'''

a, b = s.rsplit(marker, 1)
p.write_text(a + "\n" + override + marker + b)
PY

chmod +x "$FILE"

echo "Clean UI patch installed."
echo "Run: hexhost"
EOF

chmod +x /root/patch-hexhost-clean-ui.sh
/root/patch-hexhost-clean-ui.sh
