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

function addDiskUsageGauge (register : prom.Registry, path : string, everySeconds: number) {
  const diskGauge = new prom.Gauge({
    name: 'disk_usage_kilobytes',
    help: 'Disk usage in a particular directory, in kilobytes',
    labelNames: ['path']
  })
  register.registerMetric(diskGauge)

  let running = false
  setInterval(async function() {
    if (! running) {
      running = true
      try {
        await measureDiskUsage(diskGauge, path)
      } catch (e) {
        console.error(e)
      } finally {
        running = false
      }
    }
  }, 1000 * everySeconds)
}

/////////////////////////////////////////////////////////////////////////////////////

async function measureDiskUsage(diskGauge: prom.Gauge<string>, path: string) {
  diskGauge.set({ path }, await getDiskUsage(path))
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
  if (stdout === null) throw new Error("du returned no text")

  const matched = stdout.match(/^\d+/)
  if (! matched) throw new Error(`Bad format for 'du' output: ${stdout}`)

  return Number(matched[0])
}

/////////////////////////////////////////////////////////////////////////////////////

function serve(register : prom.Registry) {
  const app = express()
  app.get('/metrics', async (_req, res) => {
    res.contentType('text/plain; version=0.0.4')
    res.send(await register.metrics())
  })

  app.listen(3000, () => console.log("Please visit http://localhost:3000/metrics/"))
}

/////////////////////////////////////////////////////////////////////////////////////

for(const path of (process.env.DISK_USAGE_TARGET || ".").split(";")) {
  addDiskUsageGauge(
    register,
    path,
    Number(process.env.DISK_USAGE_PERIOD_SECONDS || "10"))
}
serve(register)
