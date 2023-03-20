#!/usr/bin/env zx
/*
  * zx scripts https://github.com/google/zx
  * prerequiste :
  * npm i -g zx
  * npm i -g zbctl
*/

import * as fs from 'fs'
import * as os from 'os'
import * as path from 'path'

const bpmnURL = 'https://raw.githubusercontent.com/epfl-si/PhDAssess-meta/main/bpmn/phdAssessProcess.bpmn'
const bpmnFullPath = path.join(os.tmpdir(), 'phdAssessProcess.bpmn')

let zeebePort = await question('What port is your zeebe instance running on ? [26501] ')
if (!zeebePort) zeebePort = '26501'

fetch(bpmnURL).then(async res => {
  const dest = fs.createWriteStream(bpmnFullPath)
  await res.body.pipe(dest)
  console.log('File downloaded successfully')

  $`zbctl deploy --port ${ zeebePort } --insecure ${ bpmnFullPath };`
  console.log('BPMN deployed successfully')

}).catch(err => console.error(err))
