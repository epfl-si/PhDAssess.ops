#!/usr/bin/env -S npm exec --yes --package=zx@latest zx --
import deployProcess from './scripts/deployProcess.mjs'

$.verbose = false

if (argv.help || argv._[0] === 'help') {
  argv._[0] === 'help' && argv._[1] && await help(...argv._.slice(1))  // called with help + something
  argv._[0] === 'help' && !argv._[1] && await help()  // called with help only
  argv._[0] !== 'help' && !argv._[1] && await help(...argv._)  // called with --help
} else if (argv._[0] === 'run') {
  await run(...argv._.slice(1));
} else if (argv._[0] === 'test') {
  await test(...argv._.slice(1));
} else if (argv._[0] === 'clean') {
  await clean(...argv._.slice(1));
} else if (argv._[0] === 'deploy-bpmn') {
  await deployProcess();
} else if (argv._[0] === 'read-snapshot') {
  await readSnapshot(...argv._.slice(1));
} else {
  await help(...argv._);
}

async function help(args) {
  await echo`${chalk.yellow('Helping soon ?')}`;
}

async function run(args) {
  await echo`${__filename}`
}

async function clean(args) {

  if (await question('Move Zeebe partitions to *.bak ? [y/N] ') === 'y') {
    const pathZeebeVolume = path.join(__dirname, `docker/volumes`);

    ['zeebe_data_node_0', 'zeebe_data_node_1', 'zeebe_data_node_2'].forEach((pathVolume) => {
      const partitionInstanceVolumePath = path.join(pathZeebeVolume, pathVolume);
      const bakPartitionInstanceVolumePath = path.join(pathZeebeVolume, `${pathVolume}.bak`);
      fs.pathExistsSync(partitionInstanceVolumePath) &&
        fs.moveSync(partitionInstanceVolumePath, bakPartitionInstanceVolumePath);
      console.log(`Successfully moved ${partitionInstanceVolumePath} to ${bakPartitionInstanceVolumePath}`)
    });
  }

  if (await question('Clean meteor db ? [y/N] ') === 'y') {
    const fillFormPath = path.join(__dirname, `apps/fillForm`);
    cd(fillFormPath);
    await $`meteor reset`;
    console.log(`Successfully reset the meteor db`)
  }

  if (await question('Clean simple monitor data ? [y/N] ') === 'y') {
    const simpleMonitorVolumePath = path.join(__dirname, `docker/volumes/simple_monitor_h2_db`);
    await fs.remove(path.join(simpleMonitorVolumePath, 'simple-monitor.mv.db'));
    console.log(`Successfully removed ${path.join(simpleMonitorVolumePath, 'simple-monitor.mv.db')}`)
  }
}

async function test(args) {
  $.verbose = true

  const testServer = process.env.TEST_SERVER ?? '1'
  const testClient = process.env.TEST_CLIENT ?? '0'

  await cd('./apps/fillForm');
  await $`TEST_SERVER=${testServer} TEST_CLIENT=${testClient} meteor test --driver-package meteortesting:mocha --port 3100`;
}

async function readSnapshot(args) {
  if (await question('Do you want to start the docker build of the zeebe_tools first ? [y/N] ') === 'y') {
    const dockerBuild = await $`docker build -t zeebe-tools docker/zeebe-tools`
    //console.log(dockerBuild)
    for await (const chunk of dockerBuild.stderr) {
      echo(chalk.yellow(dockerBuild))
    }
  }

  const snapshotPath = await question('Path to snapshot ? (should have the CURRENT file inside) ')
  const outputFilePath = await question('Full path of the destination file: ')

  if (!snapshotPath || !outputFilePath) {
    console.log('Aborting, no all paths were given for the output file')
  } else {
    await spinner(
      'decompressing the snapshot...', () =>
      $`docker run -v $PWD/scripts:/scripts -v $PWD/docker/zeebe-tools/perllib:/docker/zeebe-tools/perllib -v ${snapshotPath}:/snapshot zeebe-tools perl /scripts/read-snapshot.pl /snapshot > ${outputFilePath}`
    )
    console.log('Done.')
  }
}
