import {backupEndpoint} from "./main.js";
import {BackupResponse} from "./backup.js";

/**
 * Gets the next available backup ID by fetching the list of existing backups
 * and returning max(existingIds) + 1
 */
export async function findNextFreeBackupId(): Promise<number> {
  const response = await fetch(backupEndpoint, { method: "GET" });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`Failed to fetch existing backups: ${response.status} ${text}`);
  }

  const backups: BackupResponse[] = await response.json() as BackupResponse[];

  const ids: number[] = backups.map((b) => Number(b.backupId))

  const maxId = ids.length ? Math.max(...ids) : 0;
  const nextId = maxId + 1;

  console.log(`Next free backup ID: ${nextId}`);
  return nextId;
}
