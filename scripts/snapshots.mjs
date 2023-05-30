export async function stringifySnapshot(args) {
  if (await question('Do you want to start the docker build of the zeebe_tools first ? [y/N] ') === 'y') {
    const dockerBuild = await $`docker build -t zeebe-tools docker/zeebe-tools`
    //console.log(dockerBuild)
    for await (const chunk of dockerBuild.stderr) {
      echo(chalk.yellow(dockerBuild))
    }
  }

  const snapshotPath = await question('Path to snapshot ? (should have the CURRENT file inside) ')
  const defaultOutputFilePath = `${ path.join(__dirname, `snapshot-${ new Date().toJSON().slice(0,19) }`) }.json`
  let outputFile = await question(`Full path of the destination file: [${defaultOutputFilePath}] `)
  if (outputFile === '') outputFile = defaultOutputFilePath;

  if (!snapshotPath) {
    console.log('Aborting, no snapshot path given')
  } else {
    await spinner(
      'decompressing the snapshot...', () =>
        $`docker run -v $PWD/scripts:/scripts -v $PWD/docker/zeebe-tools/perllib:/docker/zeebe-tools/perllib -v ${snapshotPath}:/snapshot zeebe-tools perl /scripts/read-snapshot.pl /snapshot > ${outputFile}`
    )
    console.log('Done.')
  }
}
