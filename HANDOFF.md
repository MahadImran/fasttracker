# FastTracker Handoff

## Date
2026-03-26

## Completed Today
- Added one-click demo sign-in and demo reset around the seeded `tracker@example.com` account.
- Reworked the product UI into the new Ramadan-themed editorial design across landing, auth, dashboard, detail, history, and form pages.
- Added a reusable theme toggle and full day/night theme support.
- Tightened mobile layout and header behavior after visual review.
- Replaced the browser tab icon with the FastTracker logo.
- Refactored tracker summary/count logic into `app/models/tracker_summary.rb` to cut repeated count/sum work across requests.
- Improved quick make-up date selection by switching lookup checks from array scans to keyed membership checks.
- Moved branded images into the Rails asset pipeline under `app/assets/images/backgrounds`.
- Removed local-only helper artifacts from the repo root and cleaned deployment clutter from the VPS.

## CI Follow-Up
- Updated Rails from `8.1.2` to the patched `8.1.3` line to address the Active Storage advisory flagged by `bundler-audit`.
- Updated GitHub Actions workflow dependencies:
  - `actions/cache` -> `v5`
  - `actions/upload-artifact` -> `v7`
- Changed the `system-test` workflow to skip cleanly when `test/system` does not exist.

## Deployment Status
- GitHub repo: `https://github.com/MahadImran/fasttracker`
- Public site: `https://fasttracker.mahadimran.me`
- VPS app runs in Docker as `fasttracker` behind `nginx`.
- Persistent app data is stored in the `fasttracker_storage` Docker volume.
- A storage backup was created on the VPS at `/root/fasttracker/storage-backups/20260327-013536` before the main redeploy.

## Notes
- The server currently has `nginx`, `ssh`, Docker, and standard Ubuntu services running.
- `ufw` is installed/enabled as a service but currently inactive.
- There is no `test/system` directory in this app at the moment; system workflow is intentionally skip-safe until browser/system tests are added.
