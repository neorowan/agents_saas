#!/bin/bash

# =============================================================================
# AGENTS CHAT - DEPLOY SCRIPT PARA PRODUÇÃO DIGITAL OCEAN
# =============================================================================
# Este script automatiza o deploy completo do Agents Chat em produção
# Autor: Agents SAAS Team
# Versão: 1.0.0
# =============================================================================

set -e  # Exit on any error

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para log colorido
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Função para verificar se comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Função para verificar se usuário é root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "Este script não deve ser executado como root"
        exit 1
    fi
}

# Função para atualizar sistema
update_system() {
    log_info "Atualizando sistema..."
    sudo apt update && sudo apt upgrade -y
    log_success "Sistema atualizado"
}

# Função para instalar dependências básicas
install_dependencies() {
    log_info "Instalando dependências básicas..."

    sudo apt install -y \
        curl \
        wget \
        git \
        unzip \
        software-properties-common \
        apt-transport-https \
        ca-certificates \
        gnupg \
        lsb-release \
        htop \
        nginx \
        certbot \
        python3-certbot-nginx \
        ufw \
        fail2ban
}

# Função para instalar Docker
install_docker() {
    log_info "Instalando Docker..."

    if command_exists docker; then
        log_warning "Docker já está instalado"
        return
    fi

    # Adicionar repositório oficial do Docker
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

    # Adicionar usuário ao grupo docker
    sudo usermod -aG docker $USER

    log_success "Docker instalado com sucesso"
    log_warning "Reinicie o terminal ou execute 'newgrp docker' para aplicar as mudanças"
}

# Função para instalar Docker Compose
install_docker_compose() {
    log_info "Instalando Docker Compose..."

    if command_exists docker-compose; then
        log_warning "Docker Compose já está instalado"
        return
    fi

    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose

    log_success "Docker Compose instalado"
}

# Função para configurar firewall
setup_firewall() {
    log_info "Configurando firewall (UFW)..."

    sudo ufw --force reset
    sudo ufw default deny incoming
    sudo ufw default allow outgoing

    # Portas essenciais
    sudo ufw allow ssh
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    sudo ufw allow 3210/tcp  # Porta do Agents Chat

    sudo ufw --force enable
    log_success "Firewall configurado"
}

# Função para configurar Fail2ban
setup_fail2ban() {
    log_info "Configurando Fail2ban..."

    sudo systemctl enable fail2ban
    sudo systemctl start fail2ban

    # Configuração básica do Fail2ban
    sudo tee /etc/fail2ban/jail.local > /dev/null <<EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
EOF

    sudo systemctl restart fail2ban
    log_success "Fail2ban configurado"
}

# Função para criar diretório do projeto
create_project_directory() {
    log_info "Criando diretório do projeto..."

    PROJECT_DIR="/opt/agents-chat"
    sudo mkdir -p $PROJECT_DIR
    sudo chown $USER:$USER $PROJECT_DIR

    cd $PROJECT_DIR
    log_success "Diretório criado: $PROJECT_DIR"
}

# Função para baixar e configurar o projeto
setup_project() {
    log_info "Configurando projeto Agents Chat..."

    # Clonar repositório (substitua pela URL do seu repositório)
    if [ ! -d ".git" ]; then
        git clone https://github.com/lobehub/lobe-chat.git .
    else
        # Atualizar repositório existente
        log_info "Atualizando repositório..."
        git pull origin main
    fi

    # Perguntar se quer usar build personalizado ou imagem oficial
    echo
    read -p "Deseja fazer build da sua versão personalizada? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        USE_CUSTOM_BUILD=true
        log_info "Configurando para build personalizado..."

        # Verificar se Docker está disponível
        if ! command_exists docker; then
            log_error "Docker não está instalado. Instalando..."
            install_docker
        fi

        # Fazer build da imagem personalizada
        log_info "Fazendo build da imagem personalizada..."
        docker build -t agents-chat-custom:latest .

        if [ $? -eq 0 ]; then
            log_success "Build da imagem personalizada concluído"
            CUSTOM_IMAGE_NAME="agents-chat-custom:latest"
        else
            log_error "Erro no build da imagem. Usando imagem oficial."
            CUSTOM_IMAGE_NAME="lobehub/lobe-chat-database:latest"
        fi
    else
        USE_CUSTOM_BUILD=false
        CUSTOM_IMAGE_NAME="lobehub/lobe-chat-database:latest"
        log_info "Usando imagem oficial do Docker Hub"
    fi

    # Criar arquivo .env para produção
    if [ ! -f ".env" ]; then
        log_info "Criando arquivo .env para produção..."
        cat > .env <<EOF
# =============================================================================
# AGENTS CHAT - CONFIGURAÇÃO DE PRODUÇÃO
# =============================================================================

# Configurações do Banco de Dados
LOBE_DB_NAME=agents_chat_prod
POSTGRES_PASSWORD=$(openssl rand -base64 32)

# Configurações do MinIO (S3)
MINIO_PORT=9000
MINIO_ROOT_USER=admin
MINIO_ROOT_PASSWORD=$(openssl rand -base64 32)
MINIO_LOBE_BUCKET=agents-chat-files

# Configurações do Casdoor (Autenticação)
CASDOOR_PORT=8000
AUTH_CASDOOR_ISSUER=http://localhost:8000

# Configurações do LobeChat
LOBE_PORT=3210

# Configurações de Segurança
KEY_VAULTS_SECRET=$(openssl rand -base64 32)
NEXT_AUTH_SECRET=$(openssl rand -base64 32)

# Configurações de API Keys (configure conforme necessário)
OPENAI_API_KEY=your_openai_api_key_here
ANTHROPIC_API_KEY=your_anthropic_api_key_here

# Configurações de Proxy (opcional)
OPENAI_PROXY_URL=
ANTHROPIC_PROXY_URL=

# Configurações de Domínio
NEXT_PUBLIC_SITE_URL=https://your-domain.com

# Configurações de Email (para notificações)
SMTP_HOST=
SMTP_PORT=
SMTP_USER=
SMTP_PASS=

# Configurações de Monitoramento
SENTRY_DSN=

# Configuração da Imagem (não altere)
CUSTOM_IMAGE_NAME=${CUSTOM_IMAGE_NAME}
USE_CUSTOM_BUILD=${USE_CUSTOM_BUILD}
EOF
        log_success "Arquivo .env criado"
    fi

    # Copiar docker-compose.yml para produção
    cp docker-compose-production.yml docker-compose.yml

    log_success "Docker Compose configurado"
}

# Função para configurar Nginx
setup_nginx() {
    log_info "Configurando Nginx..."

    # Copiar configuração do Nginx
    sudo cp nginx-production.conf /etc/nginx/sites-available/agents-chat

    # Habilitar o site
    sudo ln -sf /etc/nginx/sites-available/agents-chat /etc/nginx/sites-enabled/
    sudo rm -f /etc/nginx/sites-enabled/default

    # Testar configuração
    sudo nginx -t

    # Reiniciar Nginx
    sudo systemctl restart nginx
    sudo systemctl enable nginx

    log_success "Nginx configurado"
}

# Função para configurar SSL com Let's Encrypt
setup_ssl() {
    log_info "Configurando SSL com Let's Encrypt..."

    read -p "Digite seu domínio (ex: agents.yourdomain.com): " DOMAIN

    if [ -z "$DOMAIN" ]; then
        log_warning "Domínio não informado. SSL não será configurado."
        return
    fi

    # Atualizar configuração do Nginx com o domínio
    sudo sed -i "s/your-domain.com/$DOMAIN/g" /etc/nginx/sites-available/agents-chat
    sudo nginx -t && sudo systemctl reload nginx

    # Obter certificado SSL
    sudo certbot --nginx -d $DOMAIN --non-interactive --agree-tos --email admin@$DOMAIN

    # Configurar renovação automática
    (crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet") | crontab -

    log_success "SSL configurado para $DOMAIN"
}

# Função para iniciar os serviços
start_services() {
    log_info "Iniciando serviços..."

    # Carregar variáveis de ambiente
    set -a
    source .env
    set +a

    # Iniciar containers
    docker-compose up -d

    # Aguardar serviços ficarem prontos
    log_info "Aguardando serviços ficarem prontos..."
    sleep 30

    # Verificar status dos containers
    docker-compose ps

    log_success "Serviços iniciados"
}

# Função para configurar backup automático
setup_backup() {
    log_info "Configurando backup automático..."

    # Criar script de backup
    cat > /opt/agents-chat/backup.sh <<'EOF'
#!/bin/bash

BACKUP_DIR="/opt/agents-chat/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="agents-chat-backup-$DATE.tar.gz"

mkdir -p $BACKUP_DIR

# Backup dos volumes Docker
docker run --rm -v agents-chat_postgres_data:/data -v $BACKUP_DIR:/backup alpine tar czf /backup/postgres-$BACKUP_FILE -C /data .
docker run --rm -v agents-chat_minio_data:/data -v $BACKUP_DIR:/backup alpine tar czf /backup/minio-$BACKUP_FILE -C /data .

# Backup do arquivo .env
cp /opt/agents-chat/.env $BACKUP_DIR/env-backup-$DATE

# Manter apenas os últimos 7 backups
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete
find $BACKUP_DIR -name "env-backup-*" -mtime +7 -delete

echo "Backup concluído: $BACKUP_FILE"
EOF

    chmod +x /opt/agents-chat/backup.sh

    # Adicionar ao crontab (backup diário às 2h da manhã)
    (crontab -l 2>/dev/null; echo "0 2 * * * /opt/agents-chat/backup.sh >> /opt/agents-chat/backup.log 2>&1") | crontab -

    log_success "Backup automático configurado"
}

# Função para configurar monitoramento
setup_monitoring() {
    log_info "Configurando monitoramento básico..."

    # Criar script de monitoramento
    cat > /opt/agents-chat/monitor.sh <<'EOF'
#!/bin/bash

LOG_FILE="/opt/agents-chat/monitor.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

# Verificar se os containers estão rodando
if ! docker-compose ps | grep -q "Up"; then
    echo "[$DATE] ERRO: Containers não estão rodando!" >> $LOG_FILE
    # Reiniciar serviços
    docker-compose restart
    echo "[$DATE] Serviços reiniciados" >> $LOG_FILE
fi

# Verificar uso de disco
DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ $DISK_USAGE -gt 80 ]; then
    echo "[$DATE] ALERTA: Uso de disco alto: ${DISK_USAGE}%" >> $LOG_FILE
fi

# Verificar uso de memória
MEM_USAGE=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
if [ $MEM_USAGE -gt 80 ]; then
    echo "[$DATE] ALERTA: Uso de memória alto: ${MEM_USAGE}%" >> $LOG_FILE
fi
EOF

    chmod +x /opt/agents-chat/monitor.sh

    # Adicionar ao crontab (verificação a cada 5 minutos)
    (crontab -l 2>/dev/null; echo "*/5 * * * * /opt/agents-chat/monitor.sh") | crontab -

    log_success "Monitoramento configurado"
}

# Função para mostrar informações finais
show_final_info() {
    log_success "Deploy concluído com sucesso!"
    echo
    echo "=============================================================================="
    echo "AGENTS CHAT - INFORMAÇÕES DE PRODUÇÃO"
    echo "=============================================================================="
    echo
    echo "📁 Diretório do projeto: /opt/agents-chat"
    echo "🌐 URL da aplicação: https://your-domain.com (configure seu domínio)"
    echo "🔧 Porta da aplicação: 3210"
    echo "🗄️  Porta do MinIO: 9000"
    echo "🔐 Porta do Casdoor: 8000"
    echo
    echo "📋 Comandos úteis:"
    echo "  - Ver logs: cd /opt/agents-chat && docker-compose logs -f"
    echo "  - Reiniciar: cd /opt/agents-chat && docker-compose restart"
    echo "  - Parar: cd /opt/agents-chat && docker-compose down"
    echo "  - Backup manual: /opt/agents-chat/backup.sh"
    echo
    echo "🔧 Próximos passos:"
    echo "  1. Configure seu domínio no arquivo .env"
    echo "  2. Configure suas API keys no arquivo .env"
    echo "  3. Configure SSL com Let's Encrypt"
    echo "  4. Teste a aplicação"
    echo
    echo "📚 Documentação: https://lobehub.com/docs"
    echo "=============================================================================="
}

# Função principal
main() {
    echo "=============================================================================="
    echo "AGENTS CHAT - DEPLOY PARA PRODUÇÃO DIGITAL OCEAN"
    echo "=============================================================================="
    echo

    # Verificações iniciais
    check_root

    # Instalação e configuração
    update_system
    install_dependencies
    install_docker
    install_docker_compose
    setup_firewall
    setup_fail2ban
    create_project_directory
    setup_project
    setup_nginx

    # Perguntar sobre SSL
    read -p "Deseja configurar SSL com Let's Encrypt? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        setup_ssl
    fi

    # Configurações finais
    setup_backup
    setup_monitoring
    start_services
    show_final_info
}

# Executar função principal
main "$@"
