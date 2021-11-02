// Watch interesting things (such as disk space usage) and serve them at /metrics.

import express from 'express'
import * as prom from 'prom-client'
import dotenv from 'dotenv'

dotenv.config()

const Registry = prom.Registry
const register = new Registry()
prom.collectDefaultMetrics({ register })

/////////////////////////////////////////////////////////////////////////////////////

let diskUsageRunning = false
setInterval(async function() {
  if (! diskUsageRunning) {
    diskUsageRunning = true
    try {
      await measureDiskUsage()
    } finally {
      diskUsageRunning = false
    }
  }
}, 1000 * Number(process.env.DISK_USAGE_PERIOD_SECONDS || 10))

async function measureDiskUsage() {
  console.log("coucou")
  await new Promise((resolve) => setTimeout(resolve, 5000))
}

/////////////////////////////////////////////////////////////////////////////////////

function main() {
  const app = express()
  app.get('/metrics', async (_req, res) => {
    res.contentType('text/plain; version=0.0.4')
    res.send(await register.metrics())
  })

  app.listen(3000, () => console.log("Please visit http://localhost:3000/metrics/"))
}

main()
