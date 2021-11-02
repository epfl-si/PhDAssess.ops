// Watch interesting things (such as disk space usage) and serve them at /metrics.

import express from 'express'
import * as prom from 'prom-client'

const Registry = prom.Registry
const register = new Registry()
prom.collectDefaultMetrics({ register })

function main() {
  const app = express()
  app.get('/metrics', async (_req, res) => {
    res.contentType('text/plain; version=0.0.4')
    res.send(await register.metrics())
  })

  app.listen(3000, () => console.log("Please visit http://localhost:3000/metrics/"))
}

main()
