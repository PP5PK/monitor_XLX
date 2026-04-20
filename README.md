# XLX Reflector Monitoring Project

## Description
The XLX Reflector Monitoring Project provides users with tools to monitor the status and performance of XLX reflectors. It enables real-time tracking and notifications, ensuring effective management of reflector connections.

## Features
- **Gatekeeper Blocking Monitoring**: Monitor and manage gatekeeper blockages.
- **Connection/Disconnection Monitoring**: Track when users connect or disconnect from the reflector.
- **Telegram Notifications**: Receive alerts via Telegram for critical events.

## Requirements
- **bash**: A Unix shell and command language.
- **curl**: A command-line tool for transferring data with URLs.
- **systemd**: A system and service manager for Linux.
- **sudo privileges**: Required for executing certain commands during installation.

## Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/PP5PK/monitor_XLX.git
   cd monitor_XLX
   ```
2. Copy the `monitor_XLX.sh` script to `/usr/local/bin/`:
   ```bash
   sudo cp monitor_XLX.sh /usr/local/bin/
   ```
3. Copy the `monitor_XLX.service` file to the systemd directory:
   ```bash
   sudo cp monitor_XLX.service /etc/systemd/system/
   ```
4. Make the script executable:
   ```bash
   sudo chmod +x /usr/local/bin/monitor_XLX.sh
   ```

## Configuration
1. **Get Telegram Bot Token**
   - Search for 'BotFather' on Telegram.
   - Start a chat and use the `/newbot` command to create a new bot.
   - Save the token provided after creation.

2. **Find Your Chat ID**
   - Send any message to your new bot.
   - Access the URL `https://api.telegram.org/bot<YourBotToken>/getUpdates`.
   - Locate your chat ID in the response.

## Usage
To start the monitoring service, enable and start it with:
```bash
sudo systemctl enable --now monitor_XLX.service
```

## Debug Mode
To run in debug mode, edit the `monitor_XLX.sh` script and set the `DEBUG` variable to `true`. This allows for verbose output to help diagnose issues.

## License
This project is licensed under the GPL-3.0 License.