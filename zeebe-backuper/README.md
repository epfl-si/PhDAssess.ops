# Zeebe Backup Automation
A TypeScript-based Node.js utility for automating Zeebe and Elasticsearch backups.

## Overview
This tool provides an automated solution for creating and monitoring Zeebe and Elasticsearch backups. It connects to a Zeebe cluster via its REST API, initiates backups with auto-incremented IDs, polls the backup status until completion, then triggers an Elasticsearch snapshot to S3.

## Configuration

- Assert your Zeebe cluster is running and the Env. variable for the backup are set.
- Assert your Elasticsearch cluster is running with the S3 snapshot repository registered.

- Configure the tool using environment variables:

| Variable | Default | Description                                                      |
|----------|---------|------------------------------------------------------------------|
| `ZEEBE_API_URL` | `http://localhost:9600` | Zeebe API endpoint                                               |
| `ES_API_URL` | `http://elasticsearch:9200` | Elasticsearch API endpoint                                       |
| `ES_SNAPSHOT_REPO` | `zeebe-es-snapshots` | Name of the S3 snapshot repository in ES                         |
| `POLL_INTERVAL_MS` | `10000` | Polling interval in milliseconds (10 seconds)                    |
| `MAX_POLL_MINUTES` | `4` | Maximum time to wait for the Zeebe backup completion (4 minutes) |

- Start the tool:
  `ZEEBE_API_URL=http://localhost:9600 npm run build && npm start`

## Backup flow

1. Find next free backup ID via Zeebe API
2. Start Zeebe backup
3. Poll Zeebe backup status until COMPLETED
4. Trigger Elasticsearch snapshot on S3 (if `ES_API_URL` is set)
5. Wait for ES snapshot to complete (via `wait_for_completion=true`)
