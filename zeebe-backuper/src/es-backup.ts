import chalk from "chalk";

import {logError, logInfo, logSuccess, logWarning} from "./utils/logs.js";

export const esUrl: string = process.env.ES_API_URL || "http://elasticsearch:9200";
export const esSnapshotRepo: string = process.env.ES_SNAPSHOT_REPO || "zeebe-es-snapshots";

/**
 * Triggers an Elasticsearch snapshot on the configured S3 repository.
 * Uses wait_for_completion=true so the request returns only after completion.
 */
export async function startEsSnapshot(backupId: number): Promise<void> {
  const snapshotName = `zeebe-backup-${backupId}`;
  const url = `${esUrl}/_snapshot/${esSnapshotRepo}/${snapshotName}?wait_for_completion=true&master_timeout=30s`;

  logInfo(`Starting Elasticsearch snapshot: ${chalk.bold(snapshotName)}...`);

  const response = await fetch(url, {
    method: "PUT",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      indices: "zeebe-record-*",
      ignore_unavailable: true,
      include_global_state: false
    })
  });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`ES snapshot failed: ${response.status} ${text}`);
  }

  const data = await response.json() as {
    snapshot: {
      state: string;
      start_time_in_millis: number;
      end_time_in_millis: number;
      duration_in_millis: number;
    }
  };

  const state = data.snapshot.state;
  const durationMs = data.snapshot.duration_in_millis;
  const durationSec = (durationMs / 1000).toFixed(1);

  if (state === "SUCCESS") {
    logSuccess(`ES snapshot ${chalk.bold(snapshotName)} completed in ${durationSec}s.`);
  } else {
    logWarning(`ES snapshot ${chalk.bold(snapshotName)} finished with state: ${chalk.yellow(state)} (${durationSec}s).`);
  }
}
