# Zeebe Backup Automation
A TypeScript-based Node.js utility for automating Zeebe backups creation.

## Overview
This tool provides an automated solution for creating and monitoring Zeebe backups. It connects to a Zeebe cluster via its REST API, initiates backups with auto-incremented IDs, and polls the backup status until completion or failure.

## Configuration

- Assert your Zeebe cluster is running and the Env. variable for the backup are set.

- Configure the tool using environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `ZEEBE_API_URL` | `http://localhost:9600` | Zeebe API endpoint |
| `POLL_INTERVAL_MS` | `10000` | Polling interval in milliseconds (10 seconds) |
| `MAX_POLL_MINUTES` | `4` | Maximum time to wait for backup completion (4 minutes) |

- Start the tool:
  `ZEEBE_API_URL=http://localhost:9600 npm run build && npm start`
