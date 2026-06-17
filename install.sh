#!/bin/bash
set -e

echo "Installing HexHost Manager..."

mkdir -p /opt/hexhost-manager/{blueprints,extensions,logs}

curl -sSL https://raw.githubusercontent.com/HexHost403/hexhost-manager/main/hexhost-manager.sh \
  -o /opt/hexhost-manager/hexhost-manager.sh

chmod +x /opt/hexhost-manager/hexhost-manager.sh

cat > /usr/local/bin/hexhost <<'CMD'
#!/bin/bash
bash /opt/hexhost-manager/hexhost-manager.sh
CMD

chmod +x /usr/local/bin/hexhost

echo "HexHost Manager installed successfully!"
echo "Run command: hexhost"
