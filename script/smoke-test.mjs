import assert from "node:assert/strict"
import { randomUUID } from "node:crypto"

const base = new URL(process.argv[2])
const cookies = new Map()
let csrf

async function request(path, params) {
  const headers = { Cookie: [...cookies.values()].join("; ") }
  if (params) {
    assert.ok(csrf, "Expected a Rails CSRF token")
    headers["X-CSRF-Token"] = csrf
  }
  const response = await fetch(new URL(path, base), {
    method: params ? "POST" : "GET",
    body: params ? new URLSearchParams(params) : undefined,
    headers,
    redirect: "manual",
    signal: AbortSignal.timeout(5000)
  })
  for (const cookie of response.headers.getSetCookie()) {
    const value = cookie.split(";")[0]
    cookies.set(value.split("=")[0], value)
  }
  return response
}

async function page(path) {
  const response = await request(path)
  assert.equal(response.status, 200, `Expected a page at ${path}`)
  const html = await response.text()
  csrf = html.match(/name="csrf-token" content="([^"]+)"/)?.[1]
  return html
}

async function submit(path, params, expectedPath) {
  const response = await request(path, params)
  assert.ok([302, 303].includes(response.status), `Unexpected response at ${path}: ${response.status}`)
  assert.equal(new URL(response.headers.get("location"), base).pathname, expectedPath)
}

await page("/")
await submit("/session/demo", {}, "/dashboard")
assert.match(await page("/dashboard"), /Signed in to the demo tracker/)
cookies.clear()

const email = `smoke-${randomUUID()}@example.com`
const password = "smoke-test-password"
await page("/registrations/new")
await submit("/registrations", {
  "user[email_address]": email,
  "user[password]": password,
  "user[password_confirmation]": password
}, "/onboarding")

await page("/onboarding")
await submit("/onboarding", { owed_count: "3" }, "/dashboard")
assert.match(await page("/dashboard"), /3 still owed/)
await submit("/makeup_fasts", {
  "makeup_fast[fasted_on]": "2025-04-01",
  "makeup_fast[notes]": "Production smoke test"
}, "/dashboard")
assert.match(await page("/dashboard"), /2 still owed/)

cookies.clear()
await page("/session/new")
await submit("/session", { email_address: email, password }, "/dashboard")
assert.match(await page("/dashboard"), /2 still owed/)
assert.match(await page("/history"), /Production smoke test/)
console.log("Demo access, signup, sign-in, and saved fast history passed")
