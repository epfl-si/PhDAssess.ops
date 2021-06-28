const ZB = require('zeebe-node')

void (async () => {
  const zbc = new ZB.ZBClient() // localhost:26500 || ZEEBE_GATEWAY_ADDRESS

  const res = await zbc.deployProcess('bpmn-model/phdAssessProcess.bpmn')
  console.log(res)
})()
