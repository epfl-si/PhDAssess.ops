export default async function generateActivityLogs(argv) {
  if (!argv) {
    console.log('Aborting, no path given to the file with the list of tasks')
    return
  }

  const tasksListPath = (argv._[1] && await fs.pathExists(argv._[1] )) ? argv._[1] :
    await question(`${argv._[1]} was not a valid entry. Path to the json file of exported tasks ?`)

  if (!tasksListPath) {
    console.log('Aborting, no path given to the file with the list of tasks')
    return
  }

  let activityLogs = []
  let tasks

  try {
    tasks = await fs.readJson(tasksListPath)
  } catch (err) {
    console.error("Failed to read the file", err);
  }

  tasks.forEach(task => {
    const log = {
      "jobKey": task._id,
      "elementId": task.elementId,
      "event": "started",
      "datetime": task.updated_at
    }

    const processInstanceExistsInPosition = activityLogs.findIndex( activity => activity['_id'] === task.processInstanceKey)

    if (processInstanceExistsInPosition !== -1) {
      const currentLogs = activityLogs[processInstanceExistsInPosition].logs

      activityLogs[processInstanceExistsInPosition] = {
        '_id': task.processInstanceKey,
        'logs': [...currentLogs, log]
      }
    } else {
      activityLogs.push({
        '_id': task.processInstanceKey,
        'logs': [log]
      })
    }
  });

  console.log(JSON.stringify(activityLogs, null, 2))
}
