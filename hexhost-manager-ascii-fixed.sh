#!/bin/bash
# ==========================================================
# HexHost Manager
# Premium Hosting Automation CLI
# Made by: Immu
# ==========================================================

RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
CYAN="\e[36m"
WHITE="\e[97m"
GRAY="\e[90m"
BOLD="\e[1m"
RESET="\e[0m"

BASE="/opt/hexhost-manager"
PANEL_DIR="/var/www/pterodactyl"
BLUEPRINT_DIR="$BASE/blueprints"
EXT_DIR="$BASE/extensions"
LOG_DIR="$BASE/logs"
LOG_FILE="$LOG_DIR/latest.log"

mkdir -p "$BLUEPRINT_DIR" "$EXT_DIR" "$LOG_DIR"

pause() {
  echo
  read -p "$(echo -e ${GREEN}${BOLD}'Press ENTER to continue... '${RESET})"
}

border() {
  echo -e "${RED}${BOLD}+------------------------------------------------------------+${RESET}"
}

row() {
  printf "${RED}${BOLD}|${RESET} ${WHITE}${BOLD}%-58.58s${RESET} ${RED}${BOLD}|${RESET}\n" "$1"
}

center() {
  local text="$1"
  local color="${2:-$CYAN}"
  local width=58
  local len=${#text}

  [ "$len" -gt "$width" ] && text="${text:0:$width}" && len=$width

  local left=$(( (width-len)/2 ))
  local right=$(( width-len-left ))

  printf "${RED}${BOLD}|${RESET} ${color}${BOLD}%*s%s%*s${RESET} ${RED}${BOLD}|${RESET}\n" "$left" "" "$text" "$right" ""
}

banner() {
  clear
  echo
  echo -e "${RED}${BOLD}────────────────────────────────────────────────────────────────────────────${RESET}"
  echo -e "${CYAN}${BOLD}"
  echo "  ██╗  ██╗███████╗██╗  ██╗██╗  ██╗ ██████╗ ███████╗████████╗"
  echo "  ██║  ██║██╔════╝╚██╗██╔╝██║  ██║██╔═══██╗██╔════╝╚══██╔══╝"
  echo "  ███████║█████╗   ╚███╔╝ ███████║██║   ██║███████╗   ██║   "
  echo "  ██╔══██║██╔══╝   ██╔██╗ ██╔══██║██║   ██║╚════██║   ██║   "
  echo "  ██║  ██║███████╗██╔╝ ██╗██║  ██║╚██████╔╝███████║   ██║   "
  echo "  ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝   ╚═╝   "
  echo -e "${RESET}"
  echo -e "                         ${GRAY}${BOLD}ᴍᴀᴅᴇ ʙʏ : ɪᴍᴍᴜ${RESET}"
  echo -e "${RED}${BOLD}────────────────────────────────────────────────────────────────────────────${RESET}"
  echo
}

title() {
  border
  row "$1"
  border
  echo
}

menu_item() {
  printf " ${CYAN}${BOLD}[%s]${RESET} ${WHITE}${BOLD}%s${RESET}\n" "$1" "$2"
}

ok() {
  echo -e "${GREEN}${BOLD}✓ $1${RESET}"
}

warn() {
  echo -e "${YELLOW}${BOLD}⚠ $1${RESET}"
}

err() {
  echo -e "${RED}${BOLD}✗ $1${RESET}"
}

show_fail_logs() {
  echo
  echo -e "${YELLOW}${BOLD}Something failed. Last logs:${RESET}"
  echo -e "${GRAY}${BOLD}+------------------------------------------------------------+${RESET}"
  tail -n 25 "$LOG_FILE" 2>/dev/null || true
  echo -e "${GRAY}${BOLD}+------------------------------------------------------------+${RESET}"
  echo -e "${YELLOW}${BOLD}Full log saved at:${RESET} ${WHITE}${BOLD}$LOG_FILE${RESET}"
}

run_silent() {
  local msg="$1"
  local cmd="$2"

  echo -ne "${CYAN}${BOLD}⦿ $msg${RESET} "

  {
    echo
    echo "=============================="
    echo "[$(date)] $msg"
    echo "$cmd"
    echo "=============================="
    bash -c "$cmd"
  } >> "$LOG_FILE" 2>&1 &

  local pid=$!
  local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  local i=0

  while kill -0 "$pid" 2>/dev/null; do
    i=$(( (i+1) % 10 ))
    echo -ne "\r${CYAN}${BOLD}⦿ $msg ${YELLOW}${spin:$i:1}${RESET}"
    sleep 0.12
  done

  wait "$pid"
  local status=$?

  if [ "$status" -eq 0 ]; then
    echo -e "\r${GREEN}${BOLD}✓ $msg completed${RESET}                    "
    return 0
  else
    echo -e "\r${RED}${BOLD}✗ $msg failed${RESET}                    "
    show_fail_logs
    return 1
  fi
}

clean_domain() {
  local d="$1"
  d="${d#http://}"
  d="${d#https://}"
  d="${d%%/*}"
  echo "$d"
}

valid_domain() {
  local d="$1"
  [[ "$d" =~ ^([A-Za-z0-9-]+\.)+[A-Za-z]{2,}$ ]]
}

check_root() {
  if [ "$EUID" -ne 0 ]; then
    err "Run this tool as root."
    exit 1
  fi
}

main_menu() {
  while true; do
    banner
    title "MAIN MENU"

    menu_item "1" "Pterodactyl Manager"
    menu_item "2" "Wings Manager"
    menu_item "3" "Blueprint Installer"
    menu_item "4" "Extension Installer"
    menu_item "5" "System Information"
    menu_item "6" "View Latest Logs"
    menu_item "0" "Exit"

    echo
    border
    read -p "$(echo -e ${YELLOW}${BOLD}'Select option [0-6]: '${RESET})" opt

    case "$opt" in
      1) pterodactyl_menu ;;
      2) wings_menu ;;
      3) blueprint_menu ;;
      4) extension_menu ;;
      5) system_info ;;
      6) view_logs ;;
      0) clear; exit 0 ;;
      *) warn "Invalid option"; sleep 1 ;;
    esac
  done
}

pterodactyl_menu() {
  while true; do
    banner
    title "PTERODACTYL MANAGER"

    menu_item "1" "Install Panel + SSL"
    menu_item "2" "Create Panel User"
    menu_item "3" "Update Panel"
    menu_item "4" "Uninstall Panel"
    menu_item "5" "Back"

    echo
    border
    read -p "$(echo -e ${YELLOW}${BOLD}'Select option [1-5]: '${RESET})" opt

    case "$opt" in
      1) install_panel ;;
      2) create_panel_user ;;
      3) update_panel ;;
      4) uninstall_panel ;;
      5) break ;;
      *) warn "Invalid option"; sleep 1 ;;
    esac
  done
}

install_panel() {
  banner
  title "INSTALL PTERODACTYL PANEL"

  echo -e "${WHITE}${BOLD}Enter panel domain.${RESET}"
  echo -e "${GRAY}Example: panel.example.in${RESET}"
  echo
  read -p "$(echo -e ${YELLOW}${BOLD}'Panel domain: '${RESET})" DOMAIN

  DOMAIN="$(clean_domain "$DOMAIN")"

  if [ -z "$DOMAIN" ]; then
    err "Domain is required."
    pause
    return
  fi

  if ! valid_domain "$DOMAIN"; then
    err "Invalid domain: $DOMAIN"
    echo -e "${GRAY}Use format like: panel.example.in${RESET}"
    pause
    return
  fi

  ADMIN_EMAIL="admin@$DOMAIN"
  ADMIN_USER="admin"
  ADMIN_PASS=$(openssl rand -base64 24 | tr -dc 'A-Za-z0-9' | head -c 16)
  DB_PASS=$(openssl rand -base64 24 | tr -dc 'A-Za-z0-9' | head -c 20)

  echo
  title "INSTALLATION STARTED"

  run_silent "Preparing server" "apt update -y && apt install -y software-properties-common curl apt-transport-https ca-certificates gnupg unzip tar git nginx redis-server mariadb-server certbot python3-certbot-nginx" || { pause; return; }

  run_silent "Installing PHP" "add-apt-repository -y ppa:ondrej/php && apt update -y && apt install -y php8.3 php8.3-cli php8.3-fpm php8.3-gd php8.3-mysql php8.3-mbstring php8.3-bcmath php8.3-xml php8.3-curl php8.3-zip php8.3-intl php8.3-sqlite3 php8.3-redis php8.3-tokenizer php8.3-dom" || { pause; return; }

  run_silent "Installing Composer" "curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer || true" || { pause; return; }

  run_silent "Downloading Panel" "mkdir -p $PANEL_DIR && cd $PANEL_DIR && curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz && tar -xzf panel.tar.gz && chmod -R 755 storage/* bootstrap/cache/ && cp .env.example .env" || { pause; return; }

  run_silent "Creating database" "mysql -u root -e \"CREATE DATABASE IF NOT EXISTS panel; CREATE USER IF NOT EXISTS 'pterodactyl'@'127.0.0.1' IDENTIFIED BY '$DB_PASS'; GRANT ALL PRIVILEGES ON panel.* TO 'pterodactyl'@'127.0.0.1' WITH GRANT OPTION; FLUSH PRIVILEGES;\"" || { pause; return; }

  run_silent "Installing dependencies" "cd $PANEL_DIR && COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader" || { pause; return; }

  run_silent "Configuring panel" "cd $PANEL_DIR && php artisan key:generate --force && php artisan p:environment:setup --author='$ADMIN_EMAIL' --url='https://$DOMAIN' --timezone='Asia/Kolkata' --cache='redis' --session='redis' --queue='redis' --redis-host='127.0.0.1' --redis-pass='null' --redis-port='6379' --settings-ui='yes' && php artisan p:environment:database --host='127.0.0.1' --port='3306' --database='panel' --username='pterodactyl' --password='$DB_PASS' && php artisan migrate --seed --force" || { pause; return; }

  run_silent "Creating admin user" "cd $PANEL_DIR && php artisan p:user:make --email='$ADMIN_EMAIL' --username='$ADMIN_USER' --name-first='HexHost' --name-last='Admin' --password='$ADMIN_PASS' --admin=1" || true

  PHP_SOCK=$(ls /run/php/php*-fpm.sock 2>/dev/null | sort -V | tail -n1)

  cat > /tmp/hexhost-nginx-panel.conf <<NGINX
server {
    listen 80;
    listen [::]:80;

    server_name $DOMAIN;

    root $PANEL_DIR/public;
    index index.php;

    client_max_body_size 100m;
    client_body_timeout 120s;
    sendfile off;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:$PHP_SOCK;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
NGINX

  run_silent "Configuring Nginx" "cp /tmp/hexhost-nginx-panel.conf /etc/nginx/sites-available/pterodactyl.conf && rm -f /etc/nginx/sites-enabled/default && ln -sf /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/pterodactyl.conf && chown -R www-data:www-data $PANEL_DIR && nginx -t" || { pause; return; }

  cat > /tmp/hexhost-pteroq.service <<SERVICE
[Unit]
Description=Pterodactyl Queue Worker
After=redis-server.service

[Service]
User=www-data
Group=www-data
Restart=always
ExecStart=/usr/bin/php $PANEL_DIR/artisan queue:work --queue=high,standard,low --sleep=3 --tries=3
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
SERVICE

  run_silent "Starting services" "cp /tmp/hexhost-pteroq.service /etc/systemd/system/pteroq.service && systemctl daemon-reload && systemctl enable --now redis-server php8.3-fpm nginx pteroq && systemctl restart nginx pteroq" || { pause; return; }

  SSL_STATUS="Not installed"
  if run_silent "Installing SSL certificate" "certbot --nginx -d '$DOMAIN' --non-interactive --agree-tos -m '$ADMIN_EMAIL' --redirect"; then
    SSL_STATUS="Installed"
  else
    SSL_STATUS="Failed"
    warn "Panel installed, but SSL failed. Make sure DNS points to this VPS IP and port 80 is open."
  fi

  echo
  title "PANEL INSTALL COMPLETED"
  echo -e "${WHITE}${BOLD}URL:${RESET} ${CYAN}https://$DOMAIN${RESET}"
  echo -e "${WHITE}${BOLD}Email:${RESET} ${CYAN}$ADMIN_EMAIL${RESET}"
  echo -e "${WHITE}${BOLD}Username:${RESET} ${CYAN}$ADMIN_USER${RESET}"
  echo -e "${WHITE}${BOLD}Password:${RESET} ${CYAN}$ADMIN_PASS${RESET}"
  echo -e "${WHITE}${BOLD}SSL:${RESET} ${CYAN}$SSL_STATUS${RESET}"
  pause
}

create_panel_user() {
  banner
  title "CREATE PANEL USER"

  if [ ! -d "$PANEL_DIR" ]; then
    err "Panel not found at $PANEL_DIR"
    pause
    return
  fi

  read -p "$(echo -e ${YELLOW}${BOLD}'Admin email: '${RESET})" EMAIL
  read -p "$(echo -e ${YELLOW}${BOLD}'Username: '${RESET})" USERNAME

  PASSWORD=$(openssl rand -base64 24 | tr -dc 'A-Za-z0-9' | head -c 16)

  run_silent "Creating panel user" "cd $PANEL_DIR && php artisan p:user:make --email='$EMAIL' --username='$USERNAME' --name-first='HexHost' --name-last='Admin' --password='$PASSWORD' --admin=1" || { pause; return; }

  echo
  ok "User created"
  echo -e "${WHITE}${BOLD}Email:${RESET} $EMAIL"
  echo -e "${WHITE}${BOLD}Username:${RESET} $USERNAME"
  echo -e "${WHITE}${BOLD}Password:${RESET} $PASSWORD"
  pause
}

update_panel() {
  banner
  title "UPDATE PANEL"

  if [ ! -d "$PANEL_DIR" ]; then
    err "Panel not found."
    pause
    return
  fi

  run_silent "Updating panel" "cd $PANEL_DIR && php artisan down || true; curl -L https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz | tar -xzv; chmod -R 755 storage/* bootstrap/cache; COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader; php artisan view:clear; php artisan config:clear; php artisan migrate --seed --force; chown -R www-data:www-data $PANEL_DIR; php artisan queue:restart; php artisan up; systemctl restart pteroq nginx" || { pause; return; }

  ok "Panel updated."
  pause
}

uninstall_panel() {
  banner
  title "UNINSTALL PANEL"

  echo -e "${RED}${BOLD}This will remove panel files.${RESET}"
  read -p "Type DELETE to continue: " CONFIRM

  if [ "$CONFIRM" != "DELETE" ]; then
    warn "Cancelled."
    pause
    return
  fi

  run_silent "Removing panel" "systemctl stop pteroq 2>/dev/null || true; systemctl disable pteroq 2>/dev/null || true; rm -f /etc/systemd/system/pteroq.service; rm -rf $PANEL_DIR; rm -f /etc/nginx/sites-enabled/pterodactyl.conf /etc/nginx/sites-available/pterodactyl.conf; systemctl daemon-reload; systemctl restart nginx" || true

  ok "Panel removed."
  pause
}

wings_menu() {
  while true; do
    banner
    title "WINGS MANAGER"

    menu_item "1" "Install Wings"
    menu_item "2" "Restart Wings"
    menu_item "3" "Wings Status"
    menu_item "4" "Uninstall Wings"
    menu_item "5" "Back"

    echo
    border
    read -p "$(echo -e ${YELLOW}${BOLD}'Select option [1-5]: '${RESET})" opt

    case "$opt" in
      1) install_wings ;;
      2) run_silent "Restarting Wings" "systemctl restart wings"; pause ;;
      3) systemctl status wings --no-pager; journalctl -u wings -n 50 --no-pager; pause ;;
      4) uninstall_wings ;;
      5) break ;;
      *) warn "Invalid option"; sleep 1 ;;
    esac
  done
}

install_wings() {
  banner
  title "INSTALL WINGS"

  run_silent "Installing Docker" "curl -sSL https://get.docker.com/ | CHANNEL=stable bash && systemctl enable --now docker" || { pause; return; }

  run_silent "Installing Wings" "mkdir -p /etc/pterodactyl && curl -L -o /usr/local/bin/wings https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_amd64 && chmod u+x /usr/local/bin/wings" || { pause; return; }

  cat > /tmp/hexhost-wings.service <<'SERVICE'
[Unit]
Description=Pterodactyl Wings Daemon
After=docker.service
Requires=docker.service
PartOf=docker.service

[Service]
User=root
WorkingDirectory=/etc/pterodactyl
LimitNOFILE=4096
PIDFile=/var/run/wings/daemon.pid
ExecStart=/usr/local/bin/wings
Restart=on-failure
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
SERVICE

  run_silent "Creating Wings service" "cp /tmp/hexhost-wings.service /etc/systemd/system/wings.service && systemctl daemon-reload && systemctl enable wings" || { pause; return; }

  ok "Wings installed."
  warn "Paste config: nano /etc/pterodactyl/config.yml"
  pause
}

uninstall_wings() {
  banner
  title "UNINSTALL WINGS"

  read -p "Type DELETE to continue: " CONFIRM

  if [ "$CONFIRM" != "DELETE" ]; then
    warn "Cancelled."
    pause
    return
  fi

  run_silent "Removing Wings" "systemctl stop wings 2>/dev/null || true; systemctl disable wings 2>/dev/null || true; rm -f /usr/local/bin/wings /etc/systemd/system/wings.service; systemctl daemon-reload" || true
  ok "Wings removed."
  pause
}

blueprint_menu() {
  while true; do
    banner
    title "BLUEPRINT INSTALLER"

    menu_item "1" "Install Blueprint Framework"
    menu_item "2" "Install Local Blueprint File"
    menu_item "3" "List Local Blueprints"
    menu_item "4" "Back"

    echo
    border
    read -p "$(echo -e ${YELLOW}${BOLD}'Select option [1-4]: '${RESET})" opt

    case "$opt" in
      1) warn "Add your custom framework command inside script."; pause ;;
      2) install_local_blueprint ;;
      3) ls -lah "$BLUEPRINT_DIR"; pause ;;
      4) break ;;
      *) warn "Invalid option"; sleep 1 ;;
    esac
  done
}

install_local_blueprint() {
  banner
  title "INSTALL LOCAL BLUEPRINT"

  echo -e "${WHITE}${BOLD}Upload .blueprint files to:${RESET} ${CYAN}$BLUEPRINT_DIR${RESET}"
  echo
  ls -1 "$BLUEPRINT_DIR"/*.blueprint 2>/dev/null || echo "No blueprint files found."
  echo

  read -p "$(echo -e ${YELLOW}${BOLD}'File name: '${RESET})" FILE

  if [ ! -f "$BLUEPRINT_DIR/$FILE" ]; then
    err "File not found."
    pause
    return
  fi

  run_silent "Installing blueprint" "cd $PANEL_DIR && blueprint -install '$BLUEPRINT_DIR/$FILE' && php artisan optimize:clear && chown -R www-data:www-data $PANEL_DIR" || { pause; return; }

  ok "Blueprint installed."
  pause
}

extension_menu() {
  while true; do
    banner
    title "EXTENSION INSTALLER"

    menu_item "1" "Install Local Extension"
    menu_item "2" "List Local Extensions"
    menu_item "3" "Back"

    echo
    border
    read -p "$(echo -e ${YELLOW}${BOLD}'Select option [1-3]: '${RESET})" opt

    case "$opt" in
      1) install_local_extension ;;
      2) ls -lah "$EXT_DIR"; pause ;;
      3) break ;;
      *) warn "Invalid option"; sleep 1 ;;
    esac
  done
}

install_local_extension() {
  banner
  title "INSTALL LOCAL EXTENSION"

  echo -e "${WHITE}${BOLD}Upload extension files to:${RESET} ${CYAN}$EXT_DIR${RESET}"
  echo
  ls -lah "$EXT_DIR"
  echo

  read -p "$(echo -e ${YELLOW}${BOLD}'File/folder name: '${RESET})" EXT

  if [ ! -e "$EXT_DIR/$EXT" ]; then
    err "Extension not found."
    pause
    return
  fi

  run_silent "Installing extension" "cd $PANEL_DIR && blueprint -install '$EXT_DIR/$EXT' && php artisan optimize:clear && chown -R www-data:www-data $PANEL_DIR" || { pause; return; }

  ok "Extension installed."
  pause
}

kv() {
  printf "${RED}${BOLD}|${RESET} ${WHITE}${BOLD}%-12s${RESET} : ${CYAN}${BOLD}%-41.41s${RESET} ${RED}${BOLD}|${RESET}\n" "$1" "$2"
}

status_line() {
  printf "${RED}${BOLD}|${RESET} ${GREEN}${BOLD}%-8s${RESET} ${WHITE}${BOLD}%-47.47s${RESET} ${RED}${BOLD}|${RESET}\n" "OK" "$1 running"
}

warn_line() {
  printf "${RED}${BOLD}|${RESET} ${YELLOW}${BOLD}%-8s${RESET} ${WHITE}${BOLD}%-47.47s${RESET} ${RED}${BOLD}|${RESET}\n" "WARN" "$1 not running"
}

service_check() {
  if systemctl is-active --quiet "$1" 2>/dev/null; then
    status_line "$2"
  else
    warn_line "$2"
  fi
}

system_info() {
  banner
  title "SYSTEM INFORMATION"

  HOSTNAME=$(hostname -f 2>/dev/null || hostname)
  IP=$(curl -4 -s --max-time 3 ifconfig.me 2>/dev/null || echo Unknown)
  OS=$(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"' || echo Unknown)
  UPTIME=$(uptime -p 2>/dev/null | sed 's/^up //' || echo Unknown)
  CPU=$(lscpu 2>/dev/null | awk -F: '/Model name/ {gsub(/^[ \t]+/,"",$2); print $2; exit}' | sed 's/[[:space:]]\+/ /g')
  RAM=$(free -h | awk '/Mem:/ {print $3 " / " $2}')
  DISK=$(df -h / | awk 'NR==2 {print $3 " / " $2 " used (" $5 ")"}')

  border
  kv "Hostname" "$HOSTNAME"
  kv "Public IP" "$IP"
  kv "OS" "$OS"
  kv "Uptime" "$UPTIME"
  kv "RAM" "$RAM"
  kv "Disk" "$DISK"
  kv "CPU" "$CPU"
  border

  echo
  title "SERVICE STATUS"

  border
  service_check nginx "Nginx"
  service_check php8.3-fpm "PHP-FPM"
  service_check pteroq "Pteroq"
  service_check wings "Wings"

  if systemctl is-active --quiet mariadb 2>/dev/null; then
    status_line "MariaDB"
  elif systemctl is-active --quiet mysql 2>/dev/null; then
    status_line "MySQL"
  else
    warn_line "Database"
  fi

  service_check redis-server "Redis"
  border

  pause
}

view_logs() {
  banner
  title "LATEST LOGS"

  if [ ! -f "$LOG_FILE" ]; then
    warn "No logs found."
    pause
    return
  fi

  tail -n 80 "$LOG_FILE"
  pause
}

check_root
main_menu
