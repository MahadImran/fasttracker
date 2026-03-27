# FastTracker

FastTracker is a Rails 8 + Hotwire app for tracking missed Ramadan fasts and completed make-up fasts.

## Current stack

- Rails 8.1
- Hotwire with Turbo + Stimulus
- SQLite for development, test, and production defaults

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
