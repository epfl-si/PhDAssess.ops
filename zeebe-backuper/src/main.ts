import {startBackup, waitForBackupCompletion} from "./backup.js";
import {startEsSnapshot} from "./es-backup.js";
import {logError, logInfo, logSuccess} from "./utils/logs.js";
import {sleep} from "./utils/sleep.js";

const zeebeUrl: string = process.env.ZEEBE_API_URL || "http://localhost:9600";
export const backupEndpoint: string = `${zeebeUrl}/actuator/backups`;

// Polling configuration
export const POLL_INTERVAL_MS = process.env.POLL_INTERVAL_MS ? Number(process.env.POLL_INTERVAL_MS) : 10_000; // 10 seconds
export const MAX_POLL_MINUTES = process.env.MAX_POLL_MINUTES ? Number(process.env.MAX_POLL_MINUTES) : 4;     // stop polling after 4 minutes
export const MAX_POLLS = (MAX_POLL_MINUTES * 60_000) / POLL_INTERVAL_MS;

async function main(): Promise<void> {
  try {
    const backupId = await startBackup();

    // wait some time before starting the first poll
    await sleep(3_000);

    await waitForBackupCompletion(backupId);

    if (process.env.ES_API_URL) {
      logSuccess("Zeebe backup done. Triggering Elasticsearch snapshot...");
      await startEsSnapshot(backupId);
      logSuccess("Full backup cycle complete (Zeebe + Elasticsearch).");
    } else {
      logInfo("ES_API_URL not set. Skipping Elasticsearch snapshot.");
    }
  } catch (err) {
    logError(`Error running backup job: ${(err as Error).message}`);
    process.exit(1);
  }
}

try {
  await main();
} catch (err) {
  console.error(`❌ Unhandled error in backup job: ${(err as Error).message}`);
  process.exit(1);
}
