#!/bin/bash

# ==========================================
# HEXHOST MANAGER v2
# Premium UI + Silent Installer Logs
# ==========================================

RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
MAGENTA="\e[35m"
CYAN="\e[36m"
WHITE="\e[97m"
GRAY="\e[90m"
BOLD="\e[1m"
DIM="\e[2m"
RESET="\e[0m"

BASE_DIR="/opt/hexhost-manager"
LOG_DIR="$BASE_DIR/logs"
BLUEPRINT_DIR="$BASE_DIR/blueprints"
EXT_DIR="$BASE_DIR/extensions"
PANEL_DIR="/var/www/pterodactyl"
LOG_FILE="$LOG_DIR/latest.log"

mkdir -p "$LOG_DIR" "$BLUEPRINT_DIR" "$EXT_DIR"

pause() {
  echo
  echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  read -p "Press ENTER to continue..."
}

line() {
  echo -e "${RED}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}

big_banner() {
  clear
  echo
  line
  echo -e "${CYAN}${BOLD}"
  echo "  ██╗  ██╗███████╗██╗  ██╗██╗  ██╗ ██████╗ ███████╗████████╗"
  echo "  ██║  ██║██╔════╝╚██╗██╔╝██║  ██║██╔═══██╗██╔════╝╚══██╔══╝"
  echo "  ███████║█████╗   ╚███╔╝ ███████║██║   ██║███████╗   ██║   "
  echo "  ██╔══██║██╔══╝   ██╔██╗ ██╔══██║██║   ██║╚════██║   ██║   "
  echo "  ██║  ██║███████╗██╔╝ ██╗██║  ██║╚██████╔╝███████║   ██║   "
  echo "  ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝   ╚═╝   "
  echo -e "${RESET}"
  echo -e "            ${WHITE}${BOLD}🚀 HEXHOST MANAGER TOOL${RESET}"
  echo -e "            ${GRAY}${BOLD}Premium Hosting Automation CLI${RESET}"
  line
  echo
}

box_title() {
  echo -e "${RED}${BOLD}╔══════════════════════════════════════════════════╗${RESET}"
  printf "${RED}${BOLD}║${RESET} ${CYAN}${BOLD}%-48s${RESET} ${RED}${BOLD}║${RESET}\n" "$1"
  echo -e "${RED}${BOLD}╚══════════════════════════════════════════════════╝${RESET}"
  echo
}

menu_item() {
  printf " ${WHITE}${BOLD}%2s)${RESET} ${RED}${BOLD}%-42s${RESET}\n" "$1" "$2"
}

success_msg() {
  echo -e "${GREEN}${BOLD}✓ $1${RESET}"
}

error_msg() {
  echo -e "${RED}${BOLD}✗ $1${RESET}"
}

info_msg() {
  echo -e "${CYAN}${BOLD}➤ $1${RESET}"
}

warn_msg() {
  echo -e "${YELLOW}${BOLD}⚠ $1${RESET}"
}

check_root() {
  if [ "$EUID" -ne 0 ]; then
    error_msg "Please run this tool as root."
    exit 1
  fi
}

run_silent() {
  MSG="$1"
  shift

  echo -ne "${CYAN}${BOLD}⦿ ${MSG}${RESET} "

  {
    echo
    echo "=================================================="
    echo "[$(date)] $MSG"
    echo "Command: $*"
    echo "=================================================="
    "$@"
  } >> "$LOG_FILE" 2>&1 &

  PID=$!
  SPIN='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  i=0

  while kill -0 "$PID" 2>/dev/null; do
    i=$(( (i+1) % 10 ))
    echo -ne "\r${CYAN}${BOLD}⦿ ${MSG}${RESET} ${YELLOW}${BOLD}${SPIN:$i:1}${RESET}"
    sleep 0.12
  done

  wait "$PID"
  STATUS=$?

  if [ "$STATUS" -eq 0 ]; then
    echo -e "\r${GREEN}${BOLD}✓ ${MSG} completed${RESET}                    "
    return 0
  else
    echo -e "\r${RED}${BOLD}✗ ${MSG} failed${RESET}                    "
    echo -e "${YELLOW}${BOLD}Log file:${RESET} $LOG_FILE"
    return 1
  fi
}

run_bash_silent() {
  MSG="$1"
  CMD="$2"

  echo -ne "${CYAN}${BOLD}⦿ ${MSG}${RESET} "

  {
    echo
    echo "=================================================="
    echo "[$(date)] $MSG"
    echo "Command:"
    echo "$CMD"
    echo "=================================================="
    bash -c "$CMD"
  } >> "$LOG_FILE" 2>&1 &

  PID=$!
  SPIN='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  i=0

  while kill -0 "$PID" 2>/dev/null; do
    i=$(( (i+1) % 10 ))
    echo -ne "\r${CYAN}${BOLD}⦿ ${MSG}${RESET} ${YELLOW}${BOLD}${SPIN:$i:1}${RESET}"
    sleep 0.12
  done

  wait "$PID"
  STATUS=$?

  if [ "$STATUS" -eq 0 ]; then
    echo -e "\r${GREEN}${BOLD}✓ ${MSG} completed${RESET}                    "
    return 0
  else
    echo -e "\r${RED}${BOLD}✗ ${MSG} failed${RESET}                    "
    echo -e "${YELLOW}${BOLD}Log file:${RESET} $LOG_FILE"
    return 1
  fi
}

progress_intro() {
  echo
  echo -e "${MAGENTA}${BOLD}╔══════════════════════════════════════════════════╗${RESET}"
  echo -e "${MAGENTA}${BOLD}║${RESET} ${WHITE}${BOLD}HexHost automation started. Please wait...${RESET}       ${MAGENTA}${BOLD}║${RESET}"
  echo -e "${MAGENTA}${BOLD}║${RESET} ${GRAY}Real install logs are saved safely in latest.log${RESET}    ${MAGENTA}${BOLD}║${RESET}"
  echo -e "${MAGENTA}${BOLD}╚══════════════════════════════════════════════════╝${RESET}"
  echo
}

main_menu() {
  while true; do
    big_banner
    box_title "MAIN MENU"

    menu_item "1" "Pterodactyl Manager"
    menu_item "2" "Wings Manager"
    menu_item "3" "Blueprint Installer"
    menu_item "4" "Extension Installer"
    menu_item "5" "System Information"
    menu_item "6" "View Latest Logs"
    menu_item "0" "Exit"

    echo
    line
    read -p "$(echo -e ${YELLOW}${BOLD}'➤ Select option [0-6]: '${RESET})" opt

    case "$opt" in
      1) pterodactyl_menu ;;
      2) wings_menu ;;
      3) blueprint_menu ;;
      4) extension_menu ;;
      5) system_info ;;
      6) view_logs ;;
      0) clear; exit 0 ;;
      *) warn_msg "Invalid option"; sleep 1 ;;
    esac
  done
}

pterodactyl_menu() {
  while true; do
    big_banner
    box_title "PTERODACTYL MANAGER"

    menu_item "1" "Install Panel"
    menu_item "2" "Create Panel User"
    menu_item "3" "Update Panel"
    menu_item "4" "Uninstall Panel"
    menu_item "5" "Back"

    echo
    line
    read -p "$(echo -e ${YELLOW}${BOLD}'➤ Select option [1-5]: '${RESET})" opt

    case "$opt" in
      1) install_panel ;;
      2) create_panel_user ;;
      3) update_panel ;;
      4) uninstall_panel ;;
      5) break ;;
      *) warn_msg "Invalid option"; sleep 1 ;;
    esac
  done
}

install_panel() {
  big_banner
  box_title "INSTALL PTERODACTYL PANEL"

  echo -e "${WHITE}${BOLD}Enter your panel domain.${RESET}"
  echo -e "${GRAY}${BOLD}Example: panel.example.in${RESET}"
  echo
  read -p "$(echo -e ${YELLOW}${BOLD}'Panel domain: '${RESET})" DOMAIN

  if [ -z "$DOMAIN" ]; then
    error_msg "Domain is required."
    pause
    return
  fi

  ADMIN_EMAIL="admin@$DOMAIN"
  ADMIN_USER="admin"
  ADMIN_PASS=$(openssl rand -base64 24 | tr -dc 'A-Za-z0-9' | head -c 16)
  DB_PASS=$(openssl rand -base64 24 | tr -dc 'A-Za-z0-9' | head -c 20)

  progress_intro

  run_bash_silent "Preparing server packages" "
    apt update -y &&
    apt install -y software-properties-common curl apt-transport-https ca-certificates gnupg unzip tar git nginx redis-server mariadb-server
  " || { pause; return; }

  run_bash_silent "Installing PHP 8.3 and extensions" "
    add-apt-repository -y ppa:ondrej/php &&
    apt update -y &&
    apt install -y php8.3 php8.3-cli php8.3-fpm php8.3-gd php8.3-mysql php8.3-mbstring php8.3-bcmath php8.3-xml php8.3-curl php8.3-zip php8.3-intl php8.3-sqlite3 php8.3-redis php8.3-tokenizer php8.3-dom
  " || { pause; return; }

  run_bash_silent "Installing Composer" "
    curl -sS https://getcomposer.org/installer | php &&
    mv composer.phar /usr/local/bin/composer || true
  " || { pause; return; }

  run_bash_silent "Downloading Pterodactyl Panel" "
    mkdir -p $PANEL_DIR &&
    cd $PANEL_DIR &&
    curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz &&
    tar -xzf panel.tar.gz &&
    chmod -R 755 storage/* bootstrap/cache/ &&
    cp .env.example .env
  " || { pause; return; }

  run_bash_silent "Creating database" "
    mysql -u root <<MYSQL
CREATE DATABASE IF NOT EXISTS panel;
CREATE USER IF NOT EXISTS 'pterodactyl'@'127.0.0.1' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON panel.* TO 'pterodactyl'@'127.0.0.1' WITH GRANT OPTION;
FLUSH PRIVILEGES;
MYSQL
  " || { pause; return; }

  run_bash_silent "Installing panel dependencies" "
    cd $PANEL_DIR &&
    COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader
  " || { pause; return; }

  run_bash_silent "Configuring panel environment" "
    cd $PANEL_DIR &&
    php artisan key:generate --force &&
    php artisan p:environment:setup --author='$ADMIN_EMAIL' --url='https://$DOMAIN' --timezone='Asia/Kolkata' --cache='redis' --session='redis' --queue='redis' --redis-host='127.0.0.1' --redis-pass='null' --redis-port='6379' --settings-ui='yes' &&
    php artisan p:environment:database --host='127.0.0.1' --port='3306' --database='panel' --username='pterodactyl' --password='$DB_PASS' &&
    php artisan migrate --seed --force
  " || { pause; return; }

  run_bash_silent "Creating admin user automatically" "
    cd $PANEL_DIR &&
    php artisan p:user:make --email='$ADMIN_EMAIL' --username='$ADMIN_USER' --name-first='HexHost' --name-last='Admin' --password='$ADMIN_PASS' --admin=1
  " || true

  PHP_SOCK=$(ls /run/php/php*-fpm.sock 2>/dev/null | sort -V | tail -n1)

  run_bash_silent "Configuring Nginx" "
    cat > /etc/nginx/sites-available/pterodactyl.conf <<NGINX
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
        try_files \\\$uri \\\$uri/ /index.php?\\\$query_string;
    }

    location ~ \\\.php\\\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:$PHP_SOCK;
        fastcgi_param SCRIPT_FILENAME \\\$document_root\\\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\\.ht {
        deny all;
    }
}
NGINX

    rm -f /etc/nginx/sites-enabled/default &&
    ln -sf /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/pterodactyl.conf &&
    chown -R www-data:www-data $PANEL_DIR &&
    nginx -t
  " || { pause; return; }

  run_bash_silent "Starting panel services" "
    cat > /etc/systemd/system/pteroq.service <<SERVICE
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

    systemctl daemon-reload &&
    systemctl enable --now redis-server &&
    systemctl enable --now php8.3-fpm &&
    systemctl enable --now nginx &&
    systemctl enable --now pteroq &&
    systemctl restart nginx &&
    systemctl restart pteroq
  " || { pause; return; }

  echo
  echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════════╗${RESET}"
  echo -e "${GREEN}${BOLD}║            PANEL INSTALL COMPLETED              ║${RESET}"
  echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════════╝${RESET}"
  echo
  echo -e "${WHITE}${BOLD}Panel URL:${RESET} ${CYAN}https://$DOMAIN${RESET}"
  echo -e "${WHITE}${BOLD}Admin Email:${RESET} ${CYAN}$ADMIN_EMAIL${RESET}"
  echo -e "${WHITE}${BOLD}Username:${RESET} ${CYAN}$ADMIN_USER${RESET}"
  echo -e "${WHITE}${BOLD}Password:${RESET} ${CYAN}$ADMIN_PASS${RESET}"
  echo
  warn_msg "Point DNS to this VPS, then install SSL."
  pause
}

create_panel_user() {
  big_banner
  box_title "CREATE PANEL USER"

  if [ ! -d "$PANEL_DIR" ]; then
    error_msg "Panel not found at $PANEL_DIR"
    pause
    return
  fi

  echo -e "${GRAY}${BOLD}Example email: admin@example.in${RESET}"
  read -p "$(echo -e ${YELLOW}${BOLD}'Admin email: '${RESET})" EMAIL
  read -p "$(echo -e ${YELLOW}${BOLD}'Username: '${RESET})" USERNAME

  PASSWORD=$(openssl rand -base64 24 | tr -dc 'A-Za-z0-9' | head -c 16)

  run_bash_silent "Creating panel user" "
    cd $PANEL_DIR &&
    php artisan p:user:make --email='$EMAIL' --username='$USERNAME' --name-first='HexHost' --name-last='Admin' --password='$PASSWORD' --admin=1
  " || { pause; return; }

  echo
  success_msg "User created"
  echo -e "${WHITE}${BOLD}Email:${RESET} $EMAIL"
  echo -e "${WHITE}${BOLD}Username:${RESET} $USERNAME"
  echo -e "${WHITE}${BOLD}Password:${RESET} $PASSWORD"
  pause
}

update_panel() {
  big_banner
  box_title "UPDATE PANEL"

  if [ ! -d "$PANEL_DIR" ]; then
    error_msg "Panel not found."
    pause
    return
  fi

  progress_intro

  run_bash_silent "Updating Pterodactyl Panel" "
    cd $PANEL_DIR &&
    php artisan down || true
    curl -L https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz | tar -xzv
    chmod -R 755 storage/* bootstrap/cache
    COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader
    php artisan view:clear
    php artisan config:clear
    php artisan migrate --seed --force
    chown -R www-data:www-data $PANEL_DIR
    php artisan queue:restart
    php artisan up
    systemctl restart pteroq
    systemctl restart nginx
  " || { pause; return; }

  success_msg "Panel updated successfully."
  pause
}

uninstall_panel() {
  big_banner
  box_title "UNINSTALL PANEL"

  echo -e "${RED}${BOLD}This will remove panel files and Nginx config.${RESET}"
  read -p "Type DELETE to continue: " CONFIRM

  if [ "$CONFIRM" != "DELETE" ]; then
    warn_msg "Cancelled."
    pause
    return
  fi

  run_bash_silent "Removing Pterodactyl Panel" "
    systemctl stop pteroq 2>/dev/null || true
    systemctl disable pteroq 2>/dev/null || true
    rm -f /etc/systemd/system/pteroq.service
    rm -rf $PANEL_DIR
    rm -f /etc/nginx/sites-enabled/pterodactyl.conf
    rm -f /etc/nginx/sites-available/pterodactyl.conf
    systemctl daemon-reload
    systemctl restart nginx
  " || true

  success_msg "Panel removed."
  pause
}

wings_menu() {
  while true; do
    big_banner
    box_title "WINGS MANAGER"

    menu_item "1" "Install Wings"
    menu_item "2" "Restart Wings"
    menu_item "3" "Wings Status"
    menu_item "4" "Uninstall Wings"
    menu_item "5" "Back"

    echo
    line
    read -p "$(echo -e ${YELLOW}${BOLD}'➤ Select option [1-5]: '${RESET})" opt

    case "$opt" in
      1) install_wings ;;
      2) run_silent "Restarting Wings" systemctl restart wings; pause ;;
      3) wings_status ;;
      4) uninstall_wings ;;
      5) break ;;
      *) warn_msg "Invalid option"; sleep 1 ;;
    esac
  done
}

install_wings() {
  big_banner
  box_title "INSTALL WINGS"

  progress_intro

  run_bash_silent "Installing Docker" "
    curl -sSL https://get.docker.com/ | CHANNEL=stable bash &&
    systemctl enable --now docker
  " || { pause; return; }

  run_bash_silent "Installing Wings binary" "
    mkdir -p /etc/pterodactyl &&
    curl -L -o /usr/local/bin/wings https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_amd64 &&
    chmod u+x /usr/local/bin/wings
  " || { pause; return; }

  run_bash_silent "Creating Wings service" "
    cat > /etc/systemd/system/wings.service <<SERVICE
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

    systemctl daemon-reload &&
    systemctl enable wings
  " || { pause; return; }

  success_msg "Wings installed."
  echo
  warn_msg "Now paste node config:"
  echo -e "${CYAN}${BOLD}nano /etc/pterodactyl/config.yml${RESET}"
  echo -e "${CYAN}${BOLD}systemctl restart wings${RESET}"
  pause
}

wings_status() {
  big_banner
  box_title "WINGS STATUS"

  systemctl status wings --no-pager || true
  echo
  echo -e "${CYAN}${BOLD}Latest Wings Logs:${RESET}"
  journalctl -u wings -n 50 --no-pager || true
  pause
}

uninstall_wings() {
  big_banner
  box_title "UNINSTALL WINGS"

  read -p "Type DELETE to remove Wings: " CONFIRM

  if [ "$CONFIRM" != "DELETE" ]; then
    warn_msg "Cancelled."
    pause
    return
  fi

  run_bash_silent "Removing Wings" "
    systemctl stop wings 2>/dev/null || true
    systemctl disable wings 2>/dev/null || true
    rm -f /usr/local/bin/wings
    rm -f /etc/systemd/system/wings.service
    systemctl daemon-reload
  " || true

  success_msg "Wings removed. Config folder kept at /etc/pterodactyl"
  pause
}

blueprint_menu() {
  while true; do
    big_banner
    box_title "BLUEPRINT INSTALLER"

    menu_item "1" "Install Blueprint Framework"
    menu_item "2" "Install Local Blueprint File"
    menu_item "3" "List Local Blueprints"
    menu_item "4" "Back"

    echo
    line
    read -p "$(echo -e ${YELLOW}${BOLD}'➤ Select option [1-4]: '${RESET})" opt

    case "$opt" in
      1) install_blueprint_framework ;;
      2) install_local_blueprint ;;
      3) list_blueprints ;;
      4) break ;;
      *) warn_msg "Invalid option"; sleep 1 ;;
    esac
  done
}

install_blueprint_framework() {
  big_banner
  box_title "INSTALL BLUEPRINT FRAMEWORK"

  echo -e "${YELLOW}${BOLD}Add your custom Blueprint framework command here.${RESET}"
  echo
  echo -e "${WHITE}${BOLD}Edit:${RESET} /opt/hexhost-manager/hexhost-manager.sh"
  echo
  echo -e "${GRAY}Function name: install_blueprint_framework${RESET}"
  pause
}

install_local_blueprint() {
  big_banner
  box_title "INSTALL LOCAL BLUEPRINT"

  mkdir -p "$BLUEPRINT_DIR"

  echo -e "${WHITE}${BOLD}Upload .blueprint files here:${RESET}"
  echo -e "${CYAN}${BOLD}$BLUEPRINT_DIR${RESET}"
  echo
  ls -1 "$BLUEPRINT_DIR"/*.blueprint 2>/dev/null || echo "No blueprint files found."
  echo
  read -p "$(echo -e ${YELLOW}${BOLD}'Enter file name example xyz.blueprint: '${RESET})" FILE

  if [ ! -f "$BLUEPRINT_DIR/$FILE" ]; then
    error_msg "File not found: $BLUEPRINT_DIR/$FILE"
    pause
    return
  fi

  progress_intro

  run_bash_silent "Installing blueprint $FILE" "
    cd $PANEL_DIR &&
    blueprint -install '$BLUEPRINT_DIR/$FILE' &&
    php artisan optimize:clear &&
    chown -R www-data:www-data $PANEL_DIR
  " || { pause; return; }

  success_msg "Blueprint installed."
  pause
}

list_blueprints() {
  big_banner
  box_title "LOCAL BLUEPRINT FILES"
  ls -lah "$BLUEPRINT_DIR"
  pause
}

extension_menu() {
  while true; do
    big_banner
    box_title "EXTENSION INSTALLER"

    menu_item "1" "Install Local Extension"
    menu_item "2" "List Local Extensions"
    menu_item "3" "Back"

    echo
    line
    read -p "$(echo -e ${YELLOW}${BOLD}'➤ Select option [1-3]: '${RESET})" opt

    case "$opt" in
      1) install_local_extension ;;
      2) list_extensions ;;
      3) break ;;
      *) warn_msg "Invalid option"; sleep 1 ;;
    esac
  done
}

install_local_extension() {
  big_banner
  box_title "INSTALL LOCAL EXTENSION"

  mkdir -p "$EXT_DIR"

  echo -e "${WHITE}${BOLD}Upload extension files here:${RESET}"
  echo -e "${CYAN}${BOLD}$EXT_DIR${RESET}"
  echo
  ls -lah "$EXT_DIR"
  echo

  read -p "$(echo -e ${YELLOW}${BOLD}'Enter extension file/folder name: '${RESET})" EXT

  if [ ! -e "$EXT_DIR/$EXT" ]; then
    error_msg "Extension not found."
    pause
    return
  fi

  progress_intro

  run_bash_silent "Installing extension $EXT" "
    cd $PANEL_DIR &&
    blueprint -install '$EXT_DIR/$EXT' &&
    php artisan optimize:clear &&
    chown -R www-data:www-data $PANEL_DIR
  " || { pause; return; }

  success_msg "Extension installed."
  pause
}

list_extensions() {
  big_banner
  box_title "LOCAL EXTENSION FILES"
  ls -lah "$EXT_DIR"
  pause
}

system_info() {
  big_banner
  box_title "SYSTEM INFORMATION"

  HOSTNAME=$(hostname -f 2>/dev/null || hostname)
  IP=$(curl -4 -s ifconfig.me 2>/dev/null || curl -4 -s icanhazip.com 2>/dev/null || echo "Unknown")
  OS=$(grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '"')
  UPTIME=$(uptime -p)
  CPU=$(lscpu | grep "Model name" | sed 's/Model name:[ \t]*//')
  RAM=$(free -h | awk '/Mem:/ {print $3 " / " $2}')
  DISK=$(df -h / | awk 'NR==2 {print $3 " / " $2 " used (" $5 ")"}')

  echo -e "${RED}${BOLD}╔══════════════════════════════════════════════════╗${RESET}"
  printf "${RED}${BOLD}║${RESET} ${WHITE}${BOLD}%-16s${RESET} ${CYAN}${BOLD}%-29s${RESET} ${RED}${BOLD}║${RESET}\n" "Hostname:" "$HOSTNAME"
  printf "${RED}${BOLD}║${RESET} ${WHITE}${BOLD}%-16s${RESET} ${CYAN}${BOLD}%-29s${RESET} ${RED}${BOLD}║${RESET}\n" "Public IP:" "$IP"
  printf "${RED}${BOLD}║${RESET} ${WHITE}${BOLD}%-16s${RESET} ${CYAN}${BOLD}%-29s${RESET} ${RED}${BOLD}║${RESET}\n" "OS:" "$OS"
  printf "${RED}${BOLD}║${RESET} ${WHITE}${BOLD}%-16s${RESET} ${CYAN}${BOLD}%-29s${RESET} ${RED}${BOLD}║${RESET}\n" "Uptime:" "$UPTIME"
  printf "${RED}${BOLD}║${RESET} ${WHITE}${BOLD}%-16s${RESET} ${CYAN}${BOLD}%-29s${RESET} ${RED}${BOLD}║${RESET}\n" "RAM:" "$RAM"
  printf "${RED}${BOLD}║${RESET} ${WHITE}${BOLD}%-16s${RESET} ${CYAN}${BOLD}%-29s${RESET} ${RED}${BOLD}║${RESET}\n" "Disk:" "$DISK"
  echo -e "${RED}${BOLD}╚══════════════════════════════════════════════════╝${RESET}"
  echo
  echo -e "${WHITE}${BOLD}CPU:${RESET} ${CYAN}$CPU${RESET}"
  echo
  echo -e "${YELLOW}${BOLD}Service Status:${RESET}"
  systemctl is-active --quiet nginx && success_msg "Nginx running" || error_msg "Nginx not running"
  systemctl is-active --quiet php8.3-fpm && success_msg "PHP-FPM running" || error_msg "PHP-FPM not running"
  systemctl is-active --quiet pteroq && success_msg "Pteroq running" || warn_msg "Pteroq not running"
  systemctl is-active --quiet wings && success_msg "Wings running" || warn_msg "Wings not running"
  systemctl is-active --quiet mariadb && success_msg "MariaDB running" || warn_msg "MariaDB not running"
  systemctl is-active --quiet redis-server && success_msg "Redis running" || warn_msg "Redis not running"

  pause
}

view_logs() {
  big_banner
  box_title "LATEST INSTALL LOGS"

  if [ ! -f "$LOG_FILE" ]; then
    warn_msg "No logs found yet."
    pause
    return
  fi

  tail -n 120 "$LOG_FILE"
  pause
}

check_root
main_menu
