# 🔔 Telegram SSH Login Notifier

Мгновенные уведомления в Telegram при входе и выходе пользователей через SSH.

```
🟢 my-server · `root` · `192.168.1.1`
🛑 my-server · `root` · `192.168.1.1`
```

## Возможности

- 🟢 / 🛑 Уведомления о входе и выходе
- 👤 Имя пользователя, IP-адрес, кастомное имя сервера
- 👥 Несколько получателей одновременно
- 🛠 Удобное управление через `tgnotify`
- 🗑️ Чистое удаление одной командой

---

## Установка

Запустите одну команду на сервере под root:

```bash
curl -fsSL https://raw.githubusercontent.com/volodyatoxic/telegram-ssh-notifier/main/install.sh -o /tmp/tg-install.sh && sudo bash /tmp/tg-install.sh
```

Скрипт запросит:
- **Bot API Token** — получить у [@BotFather](https://t.me/BotFather)
- **User ID(s)** — получить у [@userinfobot](https://t.me/userinfobot), несколько через запятую
- **Название сервера** — любое имя, например `prod-01`

---

## Управление

После установки доступна команда `tgnotify`:

```bash
# Справка
tgnotify help

# Посмотреть текущий конфиг
sudo tgnotify status

# Сменить Bot API Token
sudo tgnotify set-token

# Добавить получателя
sudo tgnotify add-user 123456789

# Удалить получателя
sudo tgnotify remove-user 123456789

# Переименовать сервер
sudo tgnotify set-server "prod-01"

# Отправить тестовое сообщение
sudo tgnotify test

# Полностью удалить программу
sudo tgnotify uninstall
```

---

## Как это работает

Скрипт подключается через [PAM](https://linux.die.net/man/8/pam_exec) (`/etc/pam.d/sshd`) и вызывается при каждой SSH-сессии. Переменные окружения `PAM_TYPE`, `PAM_USER` и `PAM_RHOST` предоставляются системой автоматически.

**Файлы на сервере:**
| Путь | Описание |
|------|----------|
| `/etc/tg-ssh-notifier/config` | Конфиг (token, user IDs, server name) |
| `/usr/local/bin/tg-ssh-notifier` | Скрипт уведомлений (вызывается PAM) |
| `/usr/local/bin/tgnotify` | CLI для управления |

---

## Требования

- Linux с OpenSSH и PAM
- `curl`
- Root-доступ для установки

---

## Лицензия

MIT
