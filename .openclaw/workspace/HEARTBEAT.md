# HEARTBEAT.md — Charon Condition Checker

Runs every 5 minutes.

## Steps

1. Read `deposits.json`
2. For each deposit with `status: "sealed"`:
   - `timer` or `date`: is `now >= release_at`? → fire delivery
   - `dead_mans_switch`: is `(now - last_checkin) > checkin_interval_hours * 3600`? → fire delivery
3. Fire delivery for triggered deposits (see AGENTS.md Delivery section)
4. Update `status` to `"delivered"`, write `deposits.json`
5. No output unless a delivery fires.