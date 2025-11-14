#!/usr/bin/env -S npm exec --yes --package=zx@latest zx --
import { userInfo } from 'os';

import deployProcess from './cli/deployProcess.mjs'
import { stringifySnapshot } from './cli/snapshots.mjs'
import generateActivityLogs from './cli/generateActivityLogs.mjs'

$.verbose = false

if (argv.help || argv._[0] === 'help') {
  argv._[0] === 'help' && argv._[1] && await help(...argv._.slice(1))  // called with help + something
  argv._[0] === 'help' && !argv._[1] && await help()  // called with help only
  argv._[0] !== 'help' && !argv._[1] && await help(...argv._)  // called with --help
} else if (argv._[0] === 'run' || argv._[0] === 'start') {
  await dockerRun(...argv._.slice(1));
} else if (argv._[0] === 'stop') {
  await dockerStop(...argv._.slice(1));
} else if (argv._[0] === 'logs') {
  await showLatestDockerLogs(...argv._.slice(1));
} else if (argv._[0] === 'test') {
  await test(...argv._.slice(1));
} else if (argv._[0] === 'clean') {
  await clean(...argv._.slice(1));
} else if (argv._[0] === 'restore') {
  await restore(...argv._.slice(1));
} else if (argv._[0] === 'deploy-bpmn') {
  await deployProcess();
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
  phd start zeebe             Start the docker stack, but only the zeebe stack
  phd logs                    Show the latest docker logs, since 5min
  phd stop                    Stop the docker stack
  phd clean                   Wipe all data. All steps have to be confirmed
  phd restore                 Restore data from S3. Be sure to have set the .env correctly
  phd test                    Launch tests
  phd test e2e                Launch e2e tests with a headless browser
  phd test load-fixtures      Load locally task fixtures
  phd git-pull-all            Git refresh all the known modules / submodules
  phd deploy-bpmn             Interactively deploy a BPMN
  phd stringify-snapshot      Use the PERL-tools to export a DB to a *.txt. Use --path=PATH_TO_CURRENT
  phd generate-activity-logs  Initiate the activityLogs table for the new dashboard milestone (temp)
  `
}

async function dockerRun(args) {
  cd(path.join(__dirname, `docker`));

  console.log('Starting the zeebe stack..')
  await $`docker compose --profile zeebe up -d`;

  if (args !== 'zeebe') {
    console.log('Starting the pdf, notifier, ged, isa..')
    await $`docker compose --profile microservices up -d`;
  }

  console.log(`Stack started.`);
  console.log(`To see the logs, use './phd.mjs logs' command`);
  console.log(`To stop, use the './phd.mjs stop' command`);
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

  if (await question('Clean meteor db ? [y/N] ') === 'y') {
    const fillFormPath = path.join(__dirname, `apps/fillForm`);
    cd(fillFormPath);
    await $`meteor reset`;
    await $`meteor npm i`;
    console.log(`Successfully reset the meteor db`)
  }

  if (await question('Clean simple monitor data ? [y/N] ') === 'y') {
    const simpleMonitorVolumePath = path.join(__dirname, `docker/volumes/simple_monitor_h2_db`);
    await fs.remove(path.join(simpleMonitorVolumePath, 'simple-monitor.mv.db'));
    console.log(`Successfully removed ${path.join(simpleMonitorVolumePath, 'simple-monitor.mv.db')}`)
  }
}

async function restore(args) {
  if (await question('Did you clean the partitions ? (phd clean) [y/N] ') === 'y') {
    console.log(`Fetch the list of the available backup ids:`);

    const response = await $`curl --request GET 'http://localhost:9600/actuator/backups' 2>/dev/null`;
    console.log(response.stdout);

    const backupId = await question('Please enter the Id to restore: ')

    if (backupId) {
      console.log(`Starting restore for backupId ${ backupId }`);

      cd(path.join(__dirname, `docker`));
      await $`docker compose exec zeebe_node_0 bash -c './bin/restore --backupId=${ backupId }'`;
      await $`docker compose exec zeebe_node_1 bash -c './bin/restore --backupId=${ backupId }'`;
      await $`docker compose exec zeebe_node_2 bash -c './bin/restore --backupId=${ backupId }'`;
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

async function gitPullAll(args) {
  const projectsPathes = [
    path.join(__dirname, 'apps/fillForm'),
    path.join(__dirname, '..', 'PhDAssess-meta'),
    path.join(__dirname, '..', 'PhDAssess-PDF'),
    path.join(__dirname, '..', 'PhDAssess-Notifier'),
    path.join(__dirname, '..', 'PhDAssess-GED'),
  ];
  for (const projectPath of projectsPathes) {
    if (fs.pathExistsSync(projectPath)) {
      console.log(`Doing ${projectPath}..`)
      cd(projectPath)
      await $`git pull`
      console.log(`${projectPath} done`)
    } else {
      console.log(`skipping inexisting ${projectPath}`)
    }
  }
}
