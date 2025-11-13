const ZB = require('zeebe-node')

const processFile = './bpmn-model/phdAssessProcess.bpmn'

void (async () => {
  console.log(await ZB.BpmnParser.generateConstantsForBpmnFiles(processFile))
})()
