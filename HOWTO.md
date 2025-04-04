# Howto

## web-app Meteor
### Update the image

- Building the image directly from Openshift is stuck behind a custom NPM repository permissions.
- Temporary solution:
        
        cd PhDAssess/fillForm
        docker build . -t quay-its.epfl.ch/svc1394/meteor-web-app --build-arg BASE_IMAGE=quay-its.epfl.ch/svc1394/ubuntu-node-14
        docker push quay-its.epfl.ch/svc1394/meteor-web-app

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
 
- Test by listing the backups

        curl --request GET --url http://localhost:9600/actuator/backups

#### Generate

- Identify the 'Leader' number:

        oc port-forward service/zeebe-gateway 26501:26500
        watch zbctl status --insecure --port 26501

- Open a port forward to the 'Leader':

        oc -n phd-assess port-forward pod/zeebe-1-0 9600:9600

- Set yourself a backup ID. You should take the bigger number of the list of all backups and add 1

- Adapt the next command with your new backup ID and launch the backup process:

        curl --request POST 'http://localhost:9600/actuator/backups' -H 'Content-Type: application/json' -d '{ "backupId": "<backupId>" }'

- Adapt the next command with your new backup ID and follow the process:

        curl --request GET --url http://localhost:9600/actuator/backups/<backupId>

#### Restore

- ⚠ Assert you are ready to lose data on the volume you will operate on ⚠
- Asset you are running the same version / brokers number
- Have the ID of the backup you want to restore. See previous section.

---

- Start x brokers, x being the same number as the backup source
- Assert you are on the right project

        oc project

- On every broker, clean the data:
  
        oc exec pod/zeebe-0-0 -- bash -c "rm -rf /usr/local/zeebe/data/*"
        oc exec pod/zeebe-1-0 -- bash -c "rm -rf /usr/local/zeebe/data/*"
        oc exec pod/zeebe-2-0 -- bash -c "rm -rf /usr/local/zeebe/data/*"

- The, on every broker, start the restoration process:
 
        oc exec pod/zeebe-0-0 -- bash -c "./bin/restore --backupId=<backupId>"
        oc exec pod/zeebe-1-0 -- bash -c "./bin/restore --backupId=<backupId>"
        oc exec pod/zeebe-2-0 -- bash -c "./bin/restore --backupId=<backupId>"
  
- Restart the brokers (if some Statefulsets are in usage -> by deleting the pods)

#### References

https://docs.camunda.io/docs/self-managed/operational-guides/backup-restore/zeebe-backup-and-restore/
