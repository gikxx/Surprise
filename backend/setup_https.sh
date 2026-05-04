#!/bin/bash
# Запускать на сервере с Ubuntu 22.04
# Использование: bash setup_https.sh YOUR_DOMAIN.duckdns.org your@email.com

set -e

DOMAIN=${1:?"Usage: $0 <domain> <email>"}
EMAIL=${2:?"Usage: $0 <domain> <email>"}

echo "==> Устанавливаем nginx и certbot..."
apt update -q
apt install -y nginx certbot python3-certbot-nginx

echo "==> Копируем конфиг nginx..."
# Заменяем плейсхолдер на реальный домен
sed "s/YOUR_DOMAIN.duckdns.org/$DOMAIN/g" "$(dirname "$0")/nginx.conf" \
    > /etc/nginx/sites-available/surprise

ln -sf /etc/nginx/sites-available/surprise /etc/nginx/sites-enabled/surprise
rm -f /etc/nginx/sites-enabled/default

echo "==> Проверяем конфиг nginx..."
nginx -t

echo "==> Запускаем nginx..."
systemctl enable nginx
systemctl restart nginx

echo "==> Получаем SSL-сертификат от Let's Encrypt..."
certbot --nginx \
    -d "$DOMAIN" \
    --email "$EMAIL" \
    --agree-tos \
    --non-interactive \
    --redirect

echo "==> Настраиваем авторебаю сертификата (cron)..."
(crontab -l 2>/dev/null; echo "0 3 * * * certbot renew --quiet && systemctl reload nginx") | crontab -

echo ""
echo "✓ Готово! Бэкенд доступен по адресу: https://$DOMAIN"
echo "  Убедись, что uvicorn запущен на 127.0.0.1:8000"
