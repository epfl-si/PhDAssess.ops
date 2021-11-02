// Watch interesting things (such as disk space usage) and serve them at /metrics.

import express from 'express'
import * as prom from 'prom-client'
import dotenv from 'dotenv'
import { spawn } from 'child_process'

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
    } catch (e) {
      console.error(e)
    } finally {
      diskUsageRunning = false
    }
  }
}, 1000 * Number(process.env.DISK_USAGE_PERIOD_SECONDS || 10))

async function measureDiskUsage() {
  const usage = await getDiskUsage(process.env.DISK_USAGE_TARGET || ".")
  console.log(usage)
}

async function getDiskUsage(path : string) {
  const out : Array<Buffer> = []
  await new Promise<void>((resolve, reject) => {
    const du = spawn("du", ["-s", path],
                     {stdio: ['ignore', 'pipe', 'inherit']})
    du.on("error", reject)

    du.stdout.on("data", (data : string) => { out.push(Buffer.from(data)) })

    du.on("close", (code : Number) => {
      if (code === 0) {
        resolve()
      } else {
        reject(`du exited with code ${code}`)
      }
    })
  })

  const stdout = Buffer.concat(out).toString("ascii")
  return stdout ? Number(stdout.match(/^\d+/)[0]) : undefined
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
