# Howto

## Zeebe

### Status

- Set the bridge from your computer to the broker to use the gateway

        oc port-forward pod/zeebe-0-0 26501:26500
 
- See the status of the quorum

        watch zbctl status --insecure --port 26501

### Backups
#### Setup

- Set the bridge from your computer to the broker to use the management api

        oc port-forward service/zeebe-quorum-0 9600:9600
 
- List backups

        curl --request GET --url http://localhost:9600/actuator/backups

#### Restore

- ⚠ Assert you are ready to lose data on the volume you will operate on ⚠
- Asset you are running the same version / brokers number
- Have the ID of the backup you want to restore. See previous section.

---

- Start x brokers, x being the same number as the backup source
- On every broker, clean the data:
  
        rm -rf /usr/local/zeebe/data/*

- The, on every broker, start the restoration process:

        ./bin/restore --backupId=<backupId>

- Restart the brokers (by deleting the pods if some Statefulsets are in usage)

#### Reference

See https://docs.camunda.io/docs/self-managed/operational-guides/backup-restore/zeebe-backup-and-restore/
