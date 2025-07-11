#!/bin/bash

echo "🔧 Corrigindo erro 403 do MinIO..."

# Verificar se está no servidor correto
if [[ ! -f /opt/agents_saas/docker-compose.yml ]]; then
    echo "❌ Este script deve ser executado no servidor onde o MinIO está rodando"
    exit 1
fi

# 1. Configurar CORS no MinIO
echo "📝 Configurando CORS no MinIO..."

# Tentar diferentes locais para o arquivo .env
ENV_FILE=""
if [[ -f /opt/agents_saas/.env ]]; then
    ENV_FILE="/opt/agents_saas/.env"
elif [[ -f /root/agents_saas/.env ]]; then
    ENV_FILE="/root/agents_saas/.env"
else
    echo "⚠️ Arquivo .env não encontrado, usando senha padrão do MinIO"
    MINIO_PASSWORD="minioadmin"
fi

if [[ -n "$ENV_FILE" ]]; then
    MINIO_PASSWORD=$(grep MINIO_ROOT_PASSWORD "$ENV_FILE" | cut -d'=' -f2)
    if [[ -z "$MINIO_PASSWORD" ]]; then
        MINIO_PASSWORD="minioadmin"
    fi
else
    MINIO_PASSWORD="minioadmin"
fi

docker exec agents-chat-minio mc alias set myminio http://localhost:9000 minioadmin "$MINIO_PASSWORD" --api S3v4

# Configurar CORS diretamente via mc
echo "📝 Configurando CORS no MinIO..."
docker exec agents-chat-minio mc anonymous set public myminio/lobe

# Configurar CORS via API do MinIO
docker exec agents-chat-minio mc admin config set myminio cors:lobe <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<CORSConfiguration xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
    <CORSRule>
        <AllowedOrigin>https://app.ai4learning.com.br</AllowedOrigin>
        <AllowedOrigin>https://app.ai4learning.com.br:3210</AllowedOrigin>
        <AllowedMethod>GET</AllowedMethod>
        <AllowedMethod>PUT</AllowedMethod>
        <AllowedMethod>POST</AllowedMethod>
        <AllowedMethod>DELETE</AllowedMethod>
        <AllowedMethod>HEAD</AllowedMethod>
        <AllowedHeader>*</AllowedHeader>
        <ExposeHeader>ETag</ExposeHeader>
        <ExposeHeader>x-amz-server-side-encryption</ExposeHeader>
        <ExposeHeader>x-amz-request-id</ExposeHeader>
        <ExposeHeader>x-amz-id-2</ExposeHeader>
        <MaxAgeSeconds>3000</MaxAgeSeconds>
    </CORSRule>
</CORSConfiguration>
EOF

# Aplicar configuração
docker exec agents-chat-minio mc admin service restart myminio

# 2. Verificar e ajustar configuração do Nginx
echo "📝 Ajustando configuração Nginx para MinIO..."
sudo tee /etc/nginx/sites-available/minio > /dev/null <<'EOF'
server {
    listen 9443 ssl;
    server_name app.ai4learning.com.br;

    ssl_certificate /etc/letsencrypt/live/app.ai4learning.com.br/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/app.ai4learning.com.br/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    # Aumentar limite para uploads
    client_max_body_size 1000M;
    client_body_buffer_size 128k;

    # Timeouts para uploads grandes
    proxy_connect_timeout 300;
    proxy_send_timeout 300;
    proxy_read_timeout 300;
    send_timeout 300;

    location / {
        proxy_pass http://localhost:9000;
        proxy_set_header Host $host:9443;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header X-Forwarded-Host $host:9443;

        # Headers importantes para MinIO
        proxy_buffering off;
        proxy_request_buffering off;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        chunked_transfer_encoding off;

        # CORS headers
        proxy_hide_header Access-Control-Allow-Origin;
        proxy_hide_header Access-Control-Allow-Methods;
        proxy_hide_header Access-Control-Allow-Headers;
        proxy_hide_header Access-Control-Allow-Credentials;

        add_header Access-Control-Allow-Origin "https://app.ai4learning.com.br" always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "Authorization, Content-Type, X-Requested-With, X-Amz-Date, Authorization, X-Api-Key, X-Amz-Security-Token" always;
        add_header Access-Control-Allow-Credentials "true" always;

        # Handle preflight requests
        if ($request_method = 'OPTIONS') {
            add_header Access-Control-Allow-Origin "https://app.ai4learning.com.br" always;
            add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
            add_header Access-Control-Allow-Headers "Authorization, Content-Type, X-Requested-With, X-Amz-Date, Authorization, X-Api-Key, X-Amz-Security-Token" always;
            add_header Access-Control-Max-Age 86400;
            add_header Content-Length 0;
            add_header Content-Type text/plain;
            return 204;
        }
    }
}
EOF

# 3. Verificar se o MinIO está configurado corretamente
echo "📝 Verificando configuração do MinIO..."

# Definir política pública para o bucket (temporário para teste)
docker exec agents-chat-minio mc anonymous set public myminio/lobe

# Recarregar Nginx
sudo nginx -t && sudo systemctl reload nginx

echo "✅ Configurações aplicadas!"
echo ""
echo "📋 Próximos passos:"
echo "1. Teste o upload novamente"
echo "2. Se ainda der erro 403, verifique os logs:"
echo "   - Nginx: sudo tail -f /var/log/nginx/error.log"
echo "   - MinIO: docker logs -f agents-chat-minio"
echo ""
echo "🔐 Para reverter acesso público do bucket (após resolver):"
echo "   docker exec agents-chat-minio mc anonymous set none myminio/lobe"
