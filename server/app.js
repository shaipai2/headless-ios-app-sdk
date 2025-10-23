const express = require('express')
const jwt = require('jsonwebtoken')
const fs = require('fs')
require('dotenv').config()

// Validate required environment variables
const requiredEnvVars = ['PORT', 'COMPANY_SECRET']
for (const envVar of requiredEnvVars) {
  if (!process.env[envVar]) {
    console.error(`${envVar} is not defined in the environment. Exiting...`)
    process.exit(1)
  }
}

const port = process.env.PORT
const secret = process.env.COMPANY_SECRET
const issuer = "ccai-mobile-sdk-example"
const tokenExpireTime = 600

function signToken(payload) {
  payload['iss'] = issuer
  const iat = parseInt(Date.now() / 1000, 10)
  payload['iat'] = iat
  payload['exp'] = iat + tokenExpireTime
  const token = jwt.sign(payload, secret, { algorithm: 'HS384' })
  console.log(`Token: ${token}`)
  return token
}

const app = express()
app.use(express.json())

app.post('/ccai/auth', function (req, res) {
  try {
    const token = signToken(req.body)
    res.json({ token })
  } catch (error) {
    console.error(error)
    res.status(500).send({ error: 'Internal Server Error' })
  }
})

app.get('/ccai/custom_data', function (req, res) {
  try {
    const payload = JSON.parse(fs.readFileSync('./custom_data.json', 'utf8'))
    const token = signToken(payload)
    res.json({ token })
  } catch (error) {
    console.error(error)
    res.status(500).send({ error: 'Internal Server Error' })
  }
})

app.listen(port, function () {
  console.log(`CCAI signing server is running at http://localhost:${port}`)
})