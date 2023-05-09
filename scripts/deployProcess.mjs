import * as fs from 'fs'
import * as os from 'os'
import * as path from 'path'

export default async function() {
  const bpmnURL = 'https://raw.githubusercontent.com/epfl-si/PhDAssess-meta/main/bpmn/phdAssessProcess.bpmn'
  const bpmnFullPath = path.join(os.tmpdir(), 'phdAssessProcess.bpmn')

  let zeebePort = await question('What port is your zeebe instance running on ? [26501] ')
  if (!zeebePort) zeebePort = '26501'

  const areYouReady = await question(`The bpmn from ${ bpmnURL } will be deployed with 'zbctl deploy'. Continue ? [Y/n] `)
  if (areYouReady && ( areYouReady === 'n' || areYouReady === 'N' )) {
      console.log(`You can manually upload a bpmn with : zbctl deploy --port ${ zeebePort } --insecure path_to_your_bpmn_file; `)
      return
  }

  console.log(`Downloading the BPMN from ${bpmnURL}..`)
  await fetch(bpmnURL).then(
    async res => {
      const dest = fs.createWriteStream(bpmnFullPath)
      await res.body.pipe(dest)
      console.log('File downloaded successfully')

      console.log('Deploying the BPMN on Zeebe..')
      await $`zbctl deploy --port ${ zeebePort } --insecure ${ bpmnFullPath };`
      console.log('BPMN deployed successfully')
    }
  ).catch(err => console.error(err))
}
