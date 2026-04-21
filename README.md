# 📡 monitor_XLX — Telegram Notifications for XLX Reflector

A Bash monitoring bot for the **xlxd** service that automatically sends **Telegram** notifications whenever:

- A station is **blocked by the Gatekeeper** (unauthorized linking or transmitting attempt)
- A repeater from the **monitoring list** **connects** or **disconnects** from the reflector

> Developed by **PP5KX** for use in the XLX300 reflector infrastructure.

---

## ✨ Features

- 🚫 **Gatekeeper block alerts** — detects any station blocked by xlxd, including callsign, IP, protocol, and action type (linking / transmitting)
- 🔗 **Connect and disconnect events** — monitors specific repeaters from a configurable list
- 🔕 **Built-in anti-spam** — suppresses duplicate notifications (30 s window for transmitting, 15 s for linking)
- 🌐 **QRZ.com link** — every callsign in the message is a clickable hyperlink directly to the station's QRZ profile
- 🃏 **Optional preview card** — displays a QRZ.com preview card with station details directly inside the Telegram message
- 🕐 **Timestamp formatting** — converts syslog format (`Mar 15 20:30:07`) to `DD/MM/YYYY HH:MM:SS`
- 📡 **Protocol mapping** — translates xlxd numeric protocol codes to human-readable names (DExtra, DPlus, DCS, XLX Interlink, DMR+, DMR MMDVM, YSF, ICom G3, IMRS)
- 🐛 **Debug mode** — logs all captured journal lines and regex match groups for troubleshooting
- ⚙️ **Separate config file** — all adjustable parameters live in `monitor_XLX_data`; the main script never needs to be edited
- 🔄 **systemd service** — ready-to-use `.service` file with dependency and automatic restart tied to `xlxd.service`

---

## 📋 Requirements

| Requirement | Minimum version |
|---|---|
| Operating system | Linux with systemd |
| xlxd | Any version with journald support |
| bash | 4.x or higher |
| curl | Any recent version |

The script checks for `curl` at startup and exits with an error message if it is not installed.

---

## 🤖 Creating a Telegram Bot

Before setting up the service you will need two pieces of information: the bot **API token** and the **Chat ID** of the destination.

### 1. Get the token via @BotFather

1. Open Telegram and search for **@BotFather**
2. Start a conversation and send the command `/newbot`
3. Follow the prompts: choose a **display name** and a **username** (must end in `bot`, e.g. `xlx300_monitor_bot`)
4. Once done, BotFather will send you a token in this format:
   ```
   Use this token to access the HTTP API:
   123456789:AAFxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   ```
5. Copy that token — it will be the value of `TELEGRAM_API` in the config file

> ⚠️ Never share your token publicly. Anyone who has it can control your bot.

### 2. Get the Chat ID via @userinfobot

The **Chat ID** tells the bot where to deliver messages. It can be a private chat with you or a group.

**For a private chat:**

1. Search for **@userinfobot** on Telegram and start a conversation
2. Send any message (e.g. `/start`)
3. The bot will reply with your info, including the `Id:` field:
   ```
   Id: 123456789
   ```

**For a group:**

1. Add **@userinfobot** to the group
2. Send `/start@userinfobot` inside the group
3. It will reply with the group ID — a **negative** number (e.g. `-1001234567890`)
4. Once you have the ID, you can remove @userinfobot from the group

> The bot created via @BotFather must also be **added to the group** in order to send messages there.

---

## ⚙️ Configuration file — `monitor_XLX_data`

All adjustable options are centralised in the `monitor_XLX_data` file, installed alongside the script at `/usr/local/bin/`. **The main script never needs to be edited.**

```bash
# Telegram bot credentials
TELEGRAM_API="YOUR_TOKEN_HERE"
CHAT_ID="YOUR_CHAT_ID_HERE"

# Reflector name as it will appear in messages (e.g., XLX300, XLXBRA)
REF_NAME="XLX300"

# QRZ.com preview card in messages: 1 = enabled, 0 = disabled
ENABLE_PREVIEW=0

# Callsigns of repeaters to monitor, separated by |
REPEATER_LIST="PP5CPI|PY2KES|PY4ALV|..."

# Script debug mode: 1 = enabled, 0 = disabled
DEBUG=0
```

### Parameter reference

| Parameter | Values | Description |
|---|---|---|
| `TELEGRAM_API` | token string | Bot token obtained via @BotFather |
| `CHAT_ID` | integer | Destination chat or group ID (groups have a negative value) |
| `REF_NAME` | string | Reflector name displayed in all notification messages (e.g., `XLX300`, `XLXBRA`) |
| `ENABLE_PREVIEW` | `0` or `1` | Controls whether a QRZ.com preview card is shown in messages |
| `REPEATER_LIST` | callsigns separated by `\|` | Repeaters monitored for connect and disconnect events |
| `DEBUG` | `0` or `1` | Enables detailed journal logging for troubleshooting |

### About `ENABLE_PREVIEW`

This parameter controls how the QRZ.com link appears in Telegram messages:

- **`0` — Disabled:** the callsign appears as a plain clickable hyperlink inside the message text
- **`1` — Enabled:** Telegram renders a **preview card** below the message showing the station's image and details from their QRZ.com page

> Preview cards can significantly increase the visual size of messages in busy groups. `0` is recommended for high-volume notification channels.

---

## 🚀 Installation

### 1. Clone the repository

```bash
git clone https://github.com/PP5PK/monitor_XLX.git
cd monitor_XLX
```

### 2. Edit the configuration file

Fill in the token and chat ID obtained in the steps above and adjust any other options as needed:

```bash
nano monitor_XLX_data
```

### 3. Copy the files

```bash
sudo cp monitor_XLX.sh /usr/local/bin/monitor_XLX.sh
sudo cp monitor_XLX_data /usr/local/bin/monitor_XLX_data
sudo chmod +x /usr/local/bin/monitor_XLX.sh
```

### 4. Install the systemd service

```bash
sudo cp monitor_XLX.service /etc/systemd/system/monitor_XLX.service
sudo systemctl daemon-reload
sudo systemctl enable --now monitor_XLX.service
```

> `enable --now` registers the service to start automatically at boot **and** starts it immediately, eliminating the need for a separate `start` command.

### 5. Check the status

```bash
sudo systemctl status monitor_XLX.service
```

---

## 📩 Message examples

All messages are sent as **HTML** with a clickable hyperlink on the callsign.

**Block — linking attempt:**
```
15/03/2025 20:30:07 - PY9XYZ, IP 177.x.x.x (DPlus) - Connection attempt on XLX300
```

**Block — transmitting attempt:**
```
15/03/2025 20:30:07 - PY9XYZ/B, IP 177.x.x.x (YSF) - Transmission attempt on XLX300
```

**Monitored repeater connected:**
```
15/03/2025 21:00:00 - Repeater PP5CPI, IP 200.x.x.x (DCS) - Connected to XLX300-C
```

**Monitored repeater disconnected:**
```
15/03/2025 22:45:00 - Repeater PP5CPI, IP 200.x.x.x (DCS) - Disconnected from XLX300-C
```

With `ENABLE_PREVIEW=1`, each message additionally shows a preview card with the station's QRZ.com page.

---

## 🗂 Repository structure

```
monitor_XLX/
├── monitor_XLX.sh          # Main script (do not edit)
├── monitor_XLX_data        # User configuration file
├── monitor_XLX.service     # systemd unit file
└── README.md
```

The script uses `/tmp/xlxd_last_events` as a temporary file to track duplicate events (automatically trimmed to 100 lines).

---

## 🔄 How it works

```
journalctl -u xlxd.service -f
        │
        ▼
┌───────────────────────┐
│    Journal line       │
└───────────┬───────────┘
            │
     ┌──────┴──────────────┐
     ▼                     ▼                    ▼
Gatekeeper?           Connect?            Disconnect?
(any callsign)        (REPEATER_          (REPEATER_
                       LIST)               LIST)
     │                     │                    │
     ▼                     ▼                    ▼
Anti-spam             Format              Format
(15/30 s)             message             message
     │                     │                    │
     └──────────┬───────────┘                   │
                ▼                               │
   send_telegram_message(msg, callsign) ◄───────┘
                │
                ▼
   ENABLE_PREVIEW=1 → QRZ.com card shown in message
   ENABLE_PREVIEW=0 → plain clickable link in text only
```

The main loop reads the journal in real time via `journalctl -f`. Each line is tested against three regular expressions in this order:

1. `REGEX_GATEKEEPER` — Gatekeeper blocks (any callsign)
2. `REGEX_CONNECT` — new clients present in `REPEATER_LIST`
3. `REGEX_DISCONNECT` — removed clients present in `REPEATER_LIST`

---

## 🛡 systemd service

The `monitor_XLX.service` file configures:

| Directive | Value | Description |
|---|---|---|
| `After` | `xlxd.service` | Starts only after xlxd is running |
| `BindsTo` | `xlxd.service` | Stops together with xlxd |
| `Restart` | `always` | Restarts automatically on failure |
| `User` | `root` | Required for journal access |

---

## 🐛 Debug

To enable debug mode, edit the configuration file and set `DEBUG` to `1`:

```bash
sudo nano /usr/local/bin/monitor_XLX_data
# Change to: DEBUG=1
sudo systemctl restart monitor_XLX.service
```

To follow the output in real time:

```bash
sudo journalctl -u monitor_XLX.service -f
```

With debug enabled, every captured journal line and all regex match groups are logged to the journal.

---

## 📋 Changelog

### v1.2.0
- **External configuration file** (`monitor_XLX_data`) — all user-adjustable parameters are now fully separated from the main script, which no longer needs to be edited
- **Configurable reflector name** (`REF_NAME`) — the reflector name displayed in all Telegram notifications is now a parameter, making the script reusable across any XLX reflector without code changes
- **QRZ.com preview card** (`ENABLE_PREVIEW`) — optional inline station preview card rendered directly in the Telegram message

### v1.0.0
- Initial release

---

## 📜 License

Distributed under the **MIT** License.  
Developed by [PP5KX](https://pp5kx.net) — Mafra, Santa Catarina, Brazil.
