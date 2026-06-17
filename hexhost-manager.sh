#!/bin/bash

RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
CYAN="\e[36m"
WHITE="\e[97m"
RESET="\e[0m"

PANEL_DIR="/var/www/pterodactyl"
BLUEPRINT_DIR="/opt/hexhost-manager/blueprints"
EXT_DIR="/opt/hexhost-manager/extensions"

pause() {
  echo
  read -p "Press ENTER to continue..."
}

banner() {
  clear
  echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo -e "${CYAN}🚀 HEXHOST MANAGER${RESET}"
  echo -e "${WHITE}made by HexHost${RESET}"
  echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo
}

check_root() {
  if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Run this tool as root.${RESET}"
    exit 1
  fi
}

main_menu() {
  while true; do
    banner
    echo -e "${WHITE}1)${RESET} Pterodactyl Install"
    echo -e "${WHITE}2)${RESET} Wings Install"
    echo -e "${WHITE}3)${RESET} Blueprint Installer"
    echo -e "${WHITE}4)${RESET} Extension Installer"
    echo -e "${WHITE}5)${RESET} System Info"
    echo -e "${WHITE}0)${RESET} Exit"
    echo
    read -p "Select option [0-5]: " opt

    case "$opt" in
      1) pterodactyl_menu ;;
      2) wings_menu ;;
      3) blueprint_menu ;;
      4) extension_menu ;;
      5) system_info ;;
      0) exit 0 ;;
      *) echo -e "${RED}Invalid option.${RESET}"; sleep 1 ;;
    esac
  done
}

pterodactyl_menu() {
  while true; do
    banner
    echo -e "${CYAN}PTERODACTYL MANAGER${RESET}"
    echo
    echo -e "${WHITE}1)${RESET} Install Panel"
    echo -e "${WHITE}2)${RESET} Create Panel User"
    echo -e "${WHITE}3)${RESET} Update Panel"
    echo -e "${WHITE}4)${RESET} Uninstall Panel"
    echo -e "${WHITE}5)${RESET} Back"
    echo
    read -p "Select option [1-5]: " opt

    case "$opt" in
      1) install_panel ;;
      2) create_panel_user ;;
      3) update_panel ;;
      4) uninstall_panel ;;
      5) break ;;
      *) echo -e "${RED}Invalid option.${RESET}"; sleep 1 ;;
    esac
  done
}

install_panel() {
  banner
  echo -e "${CYAN}Pterodactyl Panel Installer${RESET}"
  echo
  read -p "Enter panel domain example panel.example.in: " DOMAIN

  if [ -z "$DOMAIN" ]; then
    echo -e "${RED}Domain is required.${RESET}"
    pause
    return
  fi

  ADMIN_EMAIL="admin@$DOMAIN"
  ADMIN_USER="admin"
  ADMIN_PASS=$(openssl rand -base64 16 | tr -dc 'A-Za-z0-9' | head -c 16)

  echo
  echo -e "${YELLOW}Installing panel for: $DOMAIN${RESET}"
  echo

  apt update -y
  apt install -y software-properties-common curl apt-transport-https ca-certificates gnupg unzip tar git nginx redis-server mariadb-server

  add-apt-repository -y ppa:ondrej/php
  apt update -y

  apt install -y php8.3 php8.3-cli php8.3-fpm php8.3-gd php8.3-mysql php8.3-mbstring php8.3-bcmath php8.3-xml php8.3-curl php8.3-zip php8.3-intl php8.3-sqlite3 php8.3-redis php8.3-tokenizer php8.3-dom

  curl -sS https://getcomposer.org/installer | php
  mv composer.phar /usr/local/bin/composer

  mkdir -p "$PANEL_DIR"
  cd "$PANEL_DIR"

  curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
  tar -xzvf panel.tar.gz
  chmod -R 755 storage/* bootstrap/cache/

  cp .env.example .env

  DB_PASS=$(openssl rand -base64 24 | tr -dc 'A-Za-z0-9' | head -c 20)

  mysql -u root <<MYSQL
CREATE DATABASE IF NOT EXISTS panel;
CREATE USER IF NOT EXISTS 'pterodactyl'@'127.0.0.1' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON panel.* TO 'pterodactyl'@'127.0.0.1' WITH GRANT OPTION;
FLUSH PRIVILEGES;
MYSQL

  COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader

  php artisan key:generate --force

  php artisan p:environment:setup \
    --author="$ADMIN_EMAIL" \
    --url="https://$DOMAIN" \
    --timezone="Asia/Kolkata" \
    --cache="redis" \
    --session="redis" \
    --queue="redis" \
    --redis-host="127.0.0.1" \
    --redis-pass="null" \
    --redis-port="6379" \
    --settings-ui="yes"

  php artisan p:environment:database \
    --host="127.0.0.1" \
    --port="3306" \
    --database="panel" \
    --username="pterodactyl" \
    --password="$DB_PASS"

  php artisan migrate --seed --force

  php artisan p:user:make \
    --email="$ADMIN_EMAIL" \
    --username="$ADMIN_USER" \
    --name-first="HexHost" \
    --name-last="Admin" \
    --password="$ADMIN_PASS" \
    --admin=1 || true

  chown -R www-data:www-data "$PANEL_DIR"

  PHP_SOCK=$(ls /run/php/php*-fpm.sock | sort -V | tail -n1)

  cat > /etc/nginx/sites-available/pterodactyl.conf <<EOF
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
EOF

  rm -f /etc/nginx/sites-enabled/default
  ln -sf /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/pterodactyl.conf

  cat > /etc/systemd/system/pteroq.service <<EOF
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
EOF

  systemctl enable --now redis-server
  systemctl enable --now php8.3-fpm
  systemctl enable --now nginx
  systemctl enable --now pteroq

  nginx -t
  systemctl restart nginx
  systemctl restart pteroq

  echo
  echo -e "${GREEN}Panel installed.${RESET}"
  echo -e "${CYAN}URL:${RESET} https://$DOMAIN"
  echo -e "${CYAN}Admin Email:${RESET} $ADMIN_EMAIL"
  echo -e "${CYAN}Username:${RESET} $ADMIN_USER"
  echo -e "${CYAN}Password:${RESET} $ADMIN_PASS"
  echo
  echo -e "${YELLOW}Set Cloudflare DNS first, then add SSL manually or from tool v2.${RESET}"
  pause
}

create_panel_user() {
  banner

  if [ ! -d "$PANEL_DIR" ]; then
    echo -e "${RED}Panel not found at $PANEL_DIR${RESET}"
    pause
    return
  fi

  cd "$PANEL_DIR"

  read -p "Enter admin email example admin@example.in: " EMAIL
  read -p "Enter username example admin: " USERNAME
  PASSWORD=$(openssl rand -base64 16 | tr -dc 'A-Za-z0-9' | head -c 16)

  php artisan p:user:make \
    --email="$EMAIL" \
    --username="$USERNAME" \
    --name-first="HexHost" \
    --name-last="Admin" \
    --password="$PASSWORD" \
    --admin=1 || true

  echo
  echo -e "${GREEN}User created.${RESET}"
  echo -e "${CYAN}Email:${RESET} $EMAIL"
  echo -e "${CYAN}Username:${RESET} $USERNAME"
  echo -e "${CYAN}Password:${RESET} $PASSWORD"
  pause
}

update_panel() {
  banner

  if [ ! -d "$PANEL_DIR" ]; then
    echo -e "${RED}Panel not found at $PANEL_DIR${RESET}"
    pause
    return
  fi

  cd "$PANEL_DIR"

  php artisan down || true
  curl -L https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz | tar -xzv
  chmod -R 755 storage/* bootstrap/cache
  COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader
  php artisan view:clear
  php artisan config:clear
  php artisan migrate --seed --force
  chown -R www-data:www-data "$PANEL_DIR"
  php artisan queue:restart
  php artisan up

  systemctl restart pteroq
  systemctl restart nginx

  echo -e "${GREEN}Panel updated.${RESET}"
  pause
}

uninstall_panel() {
  banner
  echo -e "${RED}This will remove Pterodactyl panel files and nginx config.${RESET}"
  read -p "Type DELETE to continue: " CONFIRM

  if [ "$CONFIRM" != "DELETE" ]; then
    echo "Cancelled."
    pause
    return
  fi

  systemctl stop pteroq 2>/dev/null || true
  systemctl disable pteroq 2>/dev/null || true
  rm -f /etc/systemd/system/pteroq.service
  rm -rf "$PANEL_DIR"
  rm -f /etc/nginx/sites-enabled/pterodactyl.conf
  rm -f /etc/nginx/sites-available/pterodactyl.conf
  systemctl daemon-reload
  systemctl restart nginx

  echo -e "${GREEN}Panel removed.${RESET}"
  pause
}

wings_menu() {
  while true; do
    banner
    echo -e "${CYAN}WINGS MANAGER${RESET}"
    echo
    echo -e "${WHITE}1)${RESET} Install Wings"
    echo -e "${WHITE}2)${RESET} Restart Wings"
    echo -e "${WHITE}3)${RESET} Wings Status"
    echo -e "${WHITE}4)${RESET} Uninstall Wings"
    echo -e "${WHITE}5)${RESET} Back"
    echo
    read -p "Select option [1-5]: " opt

    case "$opt" in
      1) install_wings ;;
      2) systemctl restart wings; systemctl status wings --no-pager; pause ;;
      3) systemctl status wings --no-pager; journalctl -u wings -n 60 --no-pager; pause ;;
      4) uninstall_wings ;;
      5) break ;;
      *) echo -e "${RED}Invalid option.${RESET}"; sleep 1 ;;
    esac
  done
}

install_wings() {
  banner
  echo -e "${CYAN}Wings Installer${RESET}"
  echo
  echo "After install, paste your Wings config from Pterodactyl panel."
  echo

  curl -sSL https://get.docker.com/ | CHANNEL=stable bash
  systemctl enable --now docker

  mkdir -p /etc/pterodactyl
  curl -L -o /usr/local/bin/wings https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_amd64
  chmod u+x /usr/local/bin/wings

  cat > /etc/systemd/system/wings.service <<'EOF'
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
EOF

  systemctl enable wings

  echo -e "${GREEN}Wings installed.${RESET}"
  echo "Now paste node config:"
  echo "nano /etc/pterodactyl/config.yml"
  echo "Then run: systemctl restart wings"
  pause
}

uninstall_wings() {
  banner
  read -p "Type DELETE to remove Wings: " CONFIRM

  if [ "$CONFIRM" != "DELETE" ]; then
    echo "Cancelled."
    pause
    return
  fi

  systemctl stop wings 2>/dev/null || true
  systemctl disable wings 2>/dev/null || true
  rm -f /usr/local/bin/wings
  rm -f /etc/systemd/system/wings.service
  systemctl daemon-reload

  echo -e "${GREEN}Wings removed. Config folder kept at /etc/pterodactyl${RESET}"
  pause
}

blueprint_menu() {
  while true; do
    banner
    echo -e "${CYAN}BLUEPRINT MANAGER${RESET}"
    echo
    echo -e "${WHITE}1)${RESET} Install Blueprint Framework"
    echo -e "${WHITE}2)${RESET} Install Local Blueprint File"
    echo -e "${WHITE}3)${RESET} List Blueprint Files"
    echo -e "${WHITE}4)${RESET} Back"
    echo
    read -p "Select option [1-4]: " opt

    case "$opt" in
      1) install_blueprint_framework ;;
      2) install_local_blueprint ;;
      3) ls -lah "$BLUEPRINT_DIR"; pause ;;
      4) break ;;
      *) echo -e "${RED}Invalid option.${RESET}"; sleep 1 ;;
    esac
  done
}

install_blueprint_framework() {
  banner
  echo -e "${YELLOW}Put your Blueprint framework install command here.${RESET}"
  echo
  echo "Edit this function in:"
  echo "/opt/hexhost-manager/hexhost-manager.sh"
  pause
}

install_local_blueprint() {
  banner
  echo -e "${CYAN}Local Blueprint Installer${RESET}"
  echo

  mkdir -p "$BLUEPRINT_DIR"

  echo "Upload your .blueprint files to:"
  echo "$BLUEPRINT_DIR"
  echo
  ls -1 "$BLUEPRINT_DIR"/*.blueprint 2>/dev/null || true
  echo

  read -p "Enter blueprint filename example theme.blueprint: " FILE

  if [ ! -f "$BLUEPRINT_DIR/$FILE" ]; then
    echo -e "${RED}File not found: $BLUEPRINT_DIR/$FILE${RESET}"
    pause
    return
  fi

  cd "$PANEL_DIR"

  echo -e "${YELLOW}Installing $FILE ...${RESET}"

  # Change this line to your real custom command if different.
  blueprint -install "$BLUEPRINT_DIR/$FILE" || true

  php artisan optimize:clear || true
  chown -R www-data:www-data "$PANEL_DIR"

  echo -e "${GREEN}Blueprint install command executed.${RESET}"
  pause
}

extension_menu() {
  while true; do
    banner
    echo -e "${CYAN}EXTENSION MANAGER${RESET}"
    echo
    echo -e "${WHITE}1)${RESET} Install Local Extension"
    echo -e "${WHITE}2)${RESET} List Extension Files"
    echo -e "${WHITE}3)${RESET} Back"
    echo
    read -p "Select option [1-3]: " opt

    case "$opt" in
      1) install_local_extension ;;
      2) ls -lah "$EXT_DIR"; pause ;;
      3) break ;;
      *) echo -e "${RED}Invalid option.${RESET}"; sleep 1 ;;
    esac
  done
}

install_local_extension() {
  banner
  mkdir -p "$EXT_DIR"

  echo "Upload extension files to:"
  echo "$EXT_DIR"
  echo
  ls -lah "$EXT_DIR"
  echo

  read -p "Enter extension file/folder name: " EXT

  if [ ! -e "$EXT_DIR/$EXT" ]; then
    echo -e "${RED}Extension not found.${RESET}"
    pause
    return
  fi

  cd "$PANEL_DIR"

  echo -e "${YELLOW}Running custom extension install command...${RESET}"

  # Put your real extension command here.
  # Example:
  # blueprint -install "$EXT_DIR/$EXT"

  blueprint -install "$EXT_DIR/$EXT" || true

  php artisan optimize:clear || true
  chown -R www-data:www-data "$PANEL_DIR"

  echo -e "${GREEN}Extension command executed.${RESET}"
  pause
}

system_info() {
  banner
  hostnamectl
  echo
  free -h
  echo
  df -h
  echo
  curl -4 ifconfig.me 2>/dev/null || true
  echo
  pause
}

check_root
main_menu
