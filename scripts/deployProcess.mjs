//const findUp = require('find-up')
import {findUpSync} from 'find-up'
import ZB from 'zeebe-node'
import dotenv from 'dotenv'

dotenv.config({path: findUpSync(".env")})

void (async () => {
  const zbc = new ZB.ZBClient() // localhost:26500 || ZEEBE_GATEWAY_ADDRESS

  const res = await zbc.deployProcess('bpmn-model/phdAssessProcess.bpmn')
  console.log(res)
})()
