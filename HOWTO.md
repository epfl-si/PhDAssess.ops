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

#### Usage

See https://docs.camunda.io/docs/self-managed/operational-guides/backup-restore/zeebe-backup-and-restore/
