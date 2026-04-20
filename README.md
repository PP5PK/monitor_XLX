# Documentation for Monitor XLX

## Chat ID Method
To utilize the @userinfobot method for obtaining the Chat ID, follow these steps:
1. Open Telegram and search for `@userinfobot`.
2. Start the bot and follow the instructions provided to get your Chat ID.

## Installation Instructions
Copy the necessary files to the appropriate directories:

```bash
sudo cp monitor_XLX /usr/local/bin/
sudo cp monitor_XLX.service /etc/systemd/system/
```

## Enable and Start the Service
After copying the files, enable and start the service using the following command:
```bash
sudo systemctl enable --now monitor_XLX.service
```