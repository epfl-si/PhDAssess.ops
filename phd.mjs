#!/usr/bin/env -S npm exec --yes --package=zx@latest zx --
import { userInfo } from 'os';
import { stat } from 'fs/promises'

import deployProcess from './cli/deployProcess.mjs'
import { stringifySnapshot } from './cli/snapshots.mjs'
import generateActivityLogs from './cli/generateActivityLogs.mjs'

$.verbose = false

if (argv.help || argv._[0] === 'help') {
  argv._[0] === 'help' && argv._[1] && await help(...argv._.slice(1))  // called with help + something
  argv._[0] === 'help' && !argv._[1] && await help()  // called with help only
  argv._[0] !== 'help' && !argv._[1] && await help(...argv._)  // called with --help
} else if (argv._[0] === 'run' || argv._[0] === 'start') {
  await dockerRunZeebe();
  await dockerRunMicroservices();
  await dockerRunMonitoring();
} else if (argv._[0] === 'zeebe') {
  if (argv._[1] === 'start') await dockerRunZeebe();
  if (argv._[1] === 'stop') await dockerStop();
  if (argv._[1] === 'status') await $`zbctl status --port 29501 --insecure`.pipe(process.stdout);;
  if (argv._[1] === 'restore') await restore();
  if (argv._[1] === 'deploy-bpmn') await deployProcess();
} else if (argv._[0] === 'monitoring') {
  if (argv._[1] === 'start') await dockerRunMonitoring();
  if (argv._[1] === 'stop') await dockerStop();
} else if (argv._[0] === 'stop') {
  await dockerStop(...argv._.slice(1));
} else if (argv._[0] === 'logs') {
  await showLatestDockerLogs(...argv._.slice(1));
} else if (argv._[0] === 'test') {
  await test(...argv._.slice(1));
} else if (argv._[0] === 'clean') {
  await clean(...argv._.slice(1));
} else if (argv._[0] === 'stringify-snapshot') {
  await stringifySnapshot(argv);
} else if (argv._[0] === 'git-pull-all') {
  await gitPullAll(...argv._.slice(1));
} else if (argv._[0] === 'generate-activity-logs') {
  await generateActivityLogs(argv);
} else {
  await help(...argv._);
}

async function help(args) {
  await echo`
Usage:
  phd help                    Show this message
  phd start                   Start the docker stack. You can use 'phd run' too
  phd zeebe start             Start the docker stack, but only the Zeebe part
  phd zeebe stop              Stop the docker stack
  phd zeebe status            Show the status of the Zeebe stack
  phd zeebe restore           Restore data from S3. Be sure to have set the .env correctly
  phd zeebe deploy-bpmn       Interactively deploy a BPMN
  phd monitoring start        Start the monitoring stack
  phd monitoring stop         Stop the monitoring stack
  phd logs                    Show the latest docker logs, since 5min
  phd stop                    Stop the docker stack
  phd clean                   Wipe all data. All steps have to be confirmed
  phd test                    Launch tests
  phd test e2e                Launch e2e tests with a headless browser
  phd test load-fixtures      Load locally task fixtures
  phd stringify-snapshot      Use the PERL-tools to export a DB to a *.txt. Use --path=PATH_TO_CURRENT
  phd generate-activity-logs  Initiate the activityLogs table for the new dashboard milestone (temp)
  `
}

async function checkForDockerVolumePermissions(volumeFolder) {
  const neededGroup = 1000;
  const stats = await stat(volumeFolder);
  console.debug(`fstated ${volumeFolder}: ${JSON.stringify(stats)}`)

  const isGroupGood = stats.gid == neededGroup
  console.debug(`group ${volumeFolder}: ${JSON.stringify(stats.gid)}`)
  const isReadable = !!(stats.mode & 0o040)
  console.debug(`readable ${volumeFolder}: ${isReadable} ${JSON.stringify(stats.mode)}`)
  const isWritable = !!(stats.mode & 0o020)
  console.debug(`writable ${volumeFolder}: ${isWritable} ${JSON.stringify(stats.mode)}`)

  if (!isGroupGood) {
    console.warn(`The docker volume folder (${volumeFolder}) is owned by the group ${stats.gid}.`);
    console.warn(`It is expected to be owned by the group ${neededGroup}.`);
    console.warn(`Please run the following command to fix the permissions:`);
    console.warn(`  sudo chgrp -R ${neededGroup} ${volumeFolder}`);
    return false;
  }

  if (!isReadable || !isWritable) {
    console.warn(`The docker volume folder (${volumeFolder}) is not readable nor writable.`);
    console.warn(`Please run the following command to fix the permissions:`);
    console.warn(`  sudo chmod -R g+rw ${volumeFolder}`);
    return false;
  }

  return true;
}

async function dockerRunZeebe() {
  cd(path.join(__dirname, `docker`));

  console.log('Checking volume permission on the Zeebe stack..')
  const volumeFolder = './volumes';
  if (!( await checkForDockerVolumePermissions(volumeFolder) )) return;

  console.log('Look like the volume permissions are good, continuing..')
  console.log('Starting the Zeebe stack..')
  await $`docker compose --profile zeebe up -d`;
}

async function dockerRunMonitoring() {
  cd(path.join(__dirname, `docker`));
  await $`docker compose --profile monitoring up -d`;
  console.log('Open http://localhost:8082 to monitor the processes. Username: demo, password: demo')
  console.log('Open http://localhost:5601 to see the Zeebe logs')
}

async function dockerRunMicroservices() {
  cd(path.join(__dirname, `docker`));
  console.log('Starting the pdf, notifier, ged, isa..')
  await $`docker compose --profile microservices up -d`;
}

async function dockerStop(args) {
  cd(path.join(__dirname, `docker`));

  await spinner(`Stopping the containers`, async () => {
    await $`docker compose --profile "*" stop`;
  });

  console.log('Containers stopped.')
}

async function showLatestDockerLogs(args) {
  cd(path.join(__dirname, `docker`));

  const p = $`docker compose logs -f --since 5m`
  for await (const chunk of p.stdout) {
    echo(chunk)
  }
}

async function clean(args) {
  if (await question(`Clean Zeebe partitions ? [y/N] `) === 'y') {
    cd(path.join(__dirname, `docker`));
    await $`docker compose down -v zeebe_node_0 zeebe_node_1 zeebe_node_2`;
  }

  console.log(`It is recommended to clean the meteor db too. To do so, run: meteor reset --db in the PhDAsssess project.`)
}

async function restore() {
  console.log(`This command will restore the Zeebe data from S3.`)
  if (await question('Are you sure you want to continue ? The current Zeebe data will be lost [y/N]') === 'y') {
    console.log(`Fetch the list of the available backup ids:`);

    const response = await $`curl --request GET 'http://localhost:19600/actuator/backups' 2>/dev/null`;
    console.log(response.stdout);

    const backupId = await question('Please enter the Id to restore: ')

    if (backupId) {
      console.log(`Starting restore for backupId ${ backupId }`);

      cd(path.join(__dirname, `docker`));
      console.log(`Restoring zeebe_0..`);
      await $`docker compose exec zeebe_node_0 bash -c 'rm -rf /usr/local/zeebe/data/{*,.*} && ./bin/restore --backupId=${ backupId }'`;
      console.log(`Restoring zeebe_1..`);
      await $`docker compose exec zeebe_node_1 bash -c 'rm -rf /usr/local/zeebe/data/{*,.*} && ./bin/restore --backupId=${ backupId }'`;
      console.log(`Restoring zeebe_2..`);
      await $`docker compose exec zeebe_node_2 bash -c 'rm -rf /usr/local/zeebe/data/{*,.*} && ./bin/restore --backupId=${ backupId }'`;
      console.log(`Backup restored successfully!`);
      console.log(`Please stop and restart the Zeebe stack to see the changes.`);
    } else {
      console.log('aborted');
    }
  }
}

async function test(args) {
  $.verbose = true

  if (args === 'load-fixtures') {
    await cd('./apps/fillForm');
    //await $`echo "Meteor.isServer && Meteor.isDevelopment" | meteor shell`
    const p = await $`echo "Meteor.call('loadFixtures')" | meteor shell`.pipe(process.stdout)
    for await (const chunk of p.stdout) {
      echo(chunk)
    }
  } else if (args === 'e2e') {

    await cd(path.join(__dirname, './apps/fillForm/tests/E2E'));

    await $`npx playwright test --ui`;

  } else {

    const testServer = process.env.TEST_SERVER ?? '1'
    const testClient = process.env.TEST_CLIENT ?? '1'

    await cd(path.join(__dirname, './apps/fillForm'));
    await $`TEST_SERVER=${testServer} TEST_CLIENT=${testClient} meteor test --driver-package meteortesting:mocha --port 3100`;

  }
}
