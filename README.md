# FastTracker

[![CI](https://github.com/MahadImran/fasttracker/actions/workflows/ci.yml/badge.svg)](https://github.com/MahadImran/fasttracker/actions/workflows/ci.yml)

FastTracker is a Rails 8 + Hotwire app for tracking missed Ramadan fasts and completed make-up fasts.

## Current stack

- Rails 8.1
- Hotwire with Turbo + Stimulus
- SQLite for local development and VPS deployments with a disk
- PostgreSQL for managed hosting

## Core flows

- Create an account with email and password.
- Start with a quick onboarding total if you only know how many fasts are still owed.
- Add exact missed dates when known.
- Add season-based backlog entries when only yearly estimates are known.
- Log each make-up fast and let the app automatically pay down backlog first, then exact dates.

## Local setup

```bash
bundle install
bin/rails db:prepare
bin/rails db:seed
bin/rails server
```

## Demo accounts

After `bin/rails db:seed`, sign in with any of these:

- `newcomer@example.com` / `password123` for an empty first-run account
- `tracker@example.com` / `password123` for mixed backlog, exact dates, and logged make-up fasts
- `caughtup@example.com` / `password123` for a fully completed tracker

## Tests

```bash
bin/rails test
```

## Hosting and CI/CD

GitHub Actions runs Rails tests, lint, dependency audits, and a production Docker
smoke test against PostgreSQL. The smoke test covers demo access, registration, sign-in, and saved fast history.

1. Create a free [Neon](https://console.neon.tech/) project for this app. Copy the
   direct PostgreSQL connection string with TLS enabled.
2. In [Render](https://dashboard.render.com/), choose **New → Blueprint** and connect
   this GitHub repository. The Blueprint selects a free Docker web service and
   prompts for the connection string as `DATABASE_URL`.
3. After the first deploy, open the service URL and check `/up`. Render deploys
   subsequent updates to `main` after GitHub checks pass.

The Docker entrypoint runs `bin/rails db:prepare` before starting Puma.
The first start seeds the demo accounts. Restore the old SQLite account and fast
records into an empty Postgres database before opening a migrated site to users.

Render Free has a shared monthly allowance across services and can take about
a minute to start after going idle. See [Render's free tier](https://render.com/docs/free)
and [Neon plans](https://neon.com/pricing).
