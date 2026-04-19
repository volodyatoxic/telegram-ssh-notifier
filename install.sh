#!/bin/bash

# ─────────────────────────────────────────────
#   Telegram SSH Login Notifier — Installer
# ─────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

REPO_RAW="https://raw.githubusercontent.com/volodyatoxic/telegram-ssh-notifier/main"
CONFIG_DIR="/etc/tg-ssh-notifier"
CONFIG_FILE="$CONFIG_DIR/config"
NOTIFY_BIN="/usr/local/bin/tg-ssh-notifier"
CLI_BIN="/usr/local/bin/tgnotify"

print_banner() {
    echo -e ""
    echo -e "${BLUE}${BOLD}  ╔══════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}${BOLD}  ║    🔔 Telegram SSH Login Notifier        ║${NC}"
    echo -e "${BLUE}${BOLD}  ║       Installer v1.1║${NC}"
    echo -e "${BLUE}${BOLD}  ╚══════════════════════════════════════════╝${NC}"
    echo -e ""
}

print_step() {
    echo -e "  ${CYAN}▸${NC} $1"
}

print_ok() {
    echo -e "  ${GREEN}✔${NC}  $1"
}

print_err() {
    echo -e "  ${RED}✖${NC}  $1"
}

print_banner

# Root check
if [ "$EUID" -ne 0 ]; then
    print_err "Требуются права root. Запустите через sudo."
    exit 1
fi

echo -e "  ${YELLOW}${BOLD}Настройка параметров${NC}"
echo -e "  ${DIM}──────────────────────────────────────────${NC}"
echo ""

exec < /dev/tty
read -p "  🤖  Bot API Token: " TOKEN
read -p "  👤  User ID(s) (через запятую): " USER_IDS
read -p "  🖥️   Название сервера: " SERVER_NAME
echo ""

if [[ -z "$TOKEN" || -z "$USER_IDS" || -z "$SERVER_NAME" ]]; then
    print_err "Все поля обязательны для заполнения."
    exit 1
fi

echo -e "  ${YELLOW}${BOLD}Установка...${NC}"
echo -e "  ${DIM}──────────────────────────────────────────${NC}"
echo ""

# 1. Config directory
mkdir -p "$CONFIG_DIR"
chmod 700 "$CONFIG_DIR"
cat > "$CONFIG_FILE" <<CONF
TOKEN="$TOKEN"
USER_IDS="$USER_IDS"
SERVER_NAME="$SERVER_NAME"
CONF
chmod 600 "$CONFIG_FILE"
print_ok "Конфиг сохранён в $CONFIG_FILE"

# 2. PAM notify script
cat > "$NOTIFY_BIN" <<'NOTIFY'
#!/bin/bash
CONFIG_FILE="/etc/tg-ssh-notifier/config"
[ -f "$CONFIG_FILE" ] && source "$CONFIG_FILE"

[ -z "$TOKEN" ] && exit 0

if [ "$PAM_TYPE" = "close_session" ]; then
    ICON="🛑"
else
    ICON="🟢"
fi

IP="$PAM_RHOST"
[ -z "$IP" ] && IP=$(echo $SSH_CLIENT | awk '{print $1}')
[ -z "$IP" ] && IP="local"

USER_NAME="$PAM_USER"
[ -z "$USER_NAME" ] && USER_NAME=$(whoami)

[ -z "$SERVER_NAME" ] && SERVER_NAME=$(hostname)

MESSAGE="${ICON} *${SERVER_NAME}* · \`${USER_NAME}\` · \`${IP}\`"

IFS=',' read -ra ADDR <<< "$USER_IDS"
for id in "${ADDR[@]}"; do
    id="$(echo "$id" | tr -d ' ')"
    curl -s -X POST "https://api.telegram.org/bot${TOKEN}/sendMessage" \
        -d chat_id="$id" \
        -d parse_mode="Markdown" \
        -d text="$MESSAGE" > /dev/null 2>&1
done
NOTIFY
chmod +x "$NOTIFY_BIN"
print_ok "Notify-скрипт установлен: $NOTIFY_BIN"

# 3. Download tgnotify CLI
if curl -fsSL "$REPO_RAW/tgnotify" -o "$CLI_BIN" 2>/dev/null; then
    chmod +x "$CLI_BIN"
    print_ok "CLI установлен: tgnotify"
else
    # Fallback: embed minimal CLI inline if download fails
    cat > "$CLI_BIN" <<'CLISCRIPT'
#!/bin/bash
echo "tgnotify: не удалось загрузить полный CLI. Переустановите проект."
CLISCRIPT
    chmod +x "$CLI_BIN"
    print_err "Не удалось загрузить tgnotify CLI (нет интернета?)"
fi

# 4. PAM config
if ! grep -q "tg-ssh-notifier" /etc/pam.d/sshd 2>/dev/null; then
    echo "session optional pam_exec.so $NOTIFY_BIN" >> /etc/pam.d/sshd
    print_ok "PAM настроен: /etc/pam.d/sshd"
else
    print_ok "PAM уже настроен (пропущено)"
fi

# 5. Test notification
echo ""
echo -e "  ${YELLOW}${BOLD}Проверка соединения...${NC}"
echo ""

TEST_RESULT=$(curl -s -X POST "https://api.telegram.org/bot${TOKEN}/sendMessage" \
    -d "chat_id=$(echo "$USER_IDS" | cut -d',' -f1 | tr -d ' ')" \
    -d "parse_mode=Markdown" \
    -d "text=✅ *${SERVER_NAME}* подключён к Telegram SSH Notifier\!" 2>&1)

if echo "$TEST_RESULT" | grep -q '"ok":true'; then
    print_ok "Тестовое сообщение отправлено в Telegram!"
else
    print_err "Не удалось отправить тест (проверьте токен и ID)"
fi

echo ""
echo -e "  ${BLUE}${BOLD}  ╔══════════════════════════════════════════╗${NC}"
echo -e "  ${GREEN}${BOLD}  ║   🎉  Установка завершена успешно!       ║${NC}"
echo -e "  ${BLUE}${BOLD}  ╚══════════════════════════════════════════╝${NC}"
echo ""
echo -e "  Управление: ${BOLD}tgnotify help${NC}"
echo ""
