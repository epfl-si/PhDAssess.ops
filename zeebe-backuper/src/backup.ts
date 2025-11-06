import chalk from "chalk";

import {findNextFreeBackupId} from "./check.js";
import {logError, logInfo, logSuccess, logWarning} from "./utils/logs.js";
import {backupEndpoint, MAX_POLL_MINUTES, MAX_POLLS, POLL_INTERVAL_MS} from "./main.js";


export interface BackupResponse {
  backupId: number;
  state?: string;
  details: {
    partitionId: number;
    state: string;
    createdAt: string;
    brokerVersion?: string;
    lastUpdatedAt?: string;
    snapshotId?: string;
  }[]
}

/**
 * Starts a new backup by calling Zeebe's backup endpoint.
 * @return: the backup id started
 */
export async function startBackup(): Promise<number> {
  console.log(`[${new Date().toISOString()}] Finding next free backup ID...`);
  const nextId = await findNextFreeBackupId();

  console.log(`[${new Date().toISOString()}] Starting Zeebe backup with ID ${nextId}...`);

  const response = await fetch(backupEndpoint, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ backupId: nextId })
  });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`Backup failed to start: ${response.status} ${text}`);
  }

  const data = await response.json() as { message: string };

  console.log(`✅ Backup started with ID: ${nextId}. Log: ${data.message}`);
  return nextId;
}


/**
 * Fetches backup status for a given backup ID.
 */
async function getBackupStatus(id: number): Promise<BackupResponse> {
  const url = `${backupEndpoint}/${id}`;
  const response = await fetch(url, { method: "GET" });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`Failed to get backup status: ${response.status} ${text}`);
  }

  return await response.json() as BackupResponse;
}
/**
 * Polls the backup status until it completes or fails.
 */
export async function waitForBackupCompletion(id: number): Promise<void> {
  logInfo(`Waiting for backup ${chalk.bold(id)} to complete...`);

  for (let i = 0; i < MAX_POLLS; i++) {
    try {
      const status = await getBackupStatus(id);
      const state = status.state || "UNKNOWN";

      const color =
        state === "COMPLETED" ? chalk.green :
          state === "FAILED" ? chalk.red :
            chalk.yellow;

      logInfo(`Backup ${chalk.bold(id)} state: ${color(state)}`);

      if (state === "COMPLETED") {
        logSuccess(`🎉 Backup ${chalk.bold(id)} completed successfully.`);
        return;
      } else if (state === "FAILED") {
        logError(`❌ Backup ${chalk.bold(id)} failed.`);
        process.exit(1);
      }
    } catch (err) {
      logWarning(`Error polling backup status: ${(err as Error).message}`);
    }

    await new Promise((resolve) => setTimeout(resolve, POLL_INTERVAL_MS));
  }

  logError(`⏰ Backup ${id} did not complete within ${MAX_POLL_MINUTES} minutes.`);
  process.exit(1);
}
