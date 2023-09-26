export async function stringifySnapshot(argv) {
  const snapshotPath = (argv._[1] && await fs.pathExists(argv._[1] )) ? argv._[1] :
    await question(`${argv._[1]} was not a valid entry. Path to snapshot ? (should have the CURRENT file inside) `)

  if (!snapshotPath) {
    console.log('Aborting, no snapshot path given')
  } else {
    if (await question('Do you want to start the docker build of the zeebe_tools first ? [y/N] ') === 'y') {
      echo(`Launch the command outside of this prompt then (to get the logs) and relaunch the stringifier`)
      echo('docker build -t zeebe-tools docker/zeebe-tools')
      return
    }

    const defaultOutputFilePath = `${ path.join(path.dirname(snapshotPath), `${ path.basename(snapshotPath) }.txt`)}`
    let outputFile = await question(`Full path of the destination file: [ ${defaultOutputFilePath} ] `)
    if (outputFile === '') outputFile = defaultOutputFilePath;

    let uncompressedColumnFamilies = ''
    await spinner(
      `decompressing the snapshot ${snapshotPath}...`, async () => {
        uncompressedColumnFamilies = await $`docker run -v ./scripts:/scripts -v ./docker/zeebe-tools/perllib:/docker/zeebe-tools/perllib -v ${ snapshotPath }:/snapshot zeebe-tools perl /scripts/read-snapshot.pl /snapshot`
        await fs.writeFile(outputFile, uncompressedColumnFamilies.stdout)
      }
    )
    console.log('Done.')
  }
}
