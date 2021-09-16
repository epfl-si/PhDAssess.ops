const ZB = require('zeebe-node')
const findUp = require('find-up')

require("dotenv").config({path: findUp.sync(".env")})

void (async () => {
  const zbc = new ZB.ZBClient() // localhost:26500 || ZEEBE_GATEWAY_ADDRESS

  const res = await zbc.deployProcess('bpmn-model/phdAssessProcess.bpmn')
  console.log(res)
})()
