# TOOLS.md — Charon Tools

## Deposit Store

All deposits live in `deposits.json` in the workspace directory.

### Schema

```json
{
  "deposits": [
    {
      "id": "uuid-v4",
      "user_id": "telegram chat id",
      "content_type": "text | file",
      "content": "the secret text OR absolute file path if content_type is file",
      "filename": "original filename — only if content_type is file",
      "when": {
        "type": "timer | dead_mans_switch | date",
        "release_at": "ISO8601 — for timer and date",
        "checkin_interval_hours": 24,
        "last_checkin": "ISO8601 — for dead_mans_switch"
      },
      "how": {
        "type": "telegram | email | onchain",
        "destination": "@handle, email, or ETH address"
      },
      "cancel_passphrase": "optional",
      "status": "sealed | delivered | cancelled",
      "created_at": "ISO8601"
    }
  ]
}
```

### Shell Helpers

```bash
# Read deposits (or init if missing)
cat deposits.json 2>/dev/null || echo '{"deposits":[]}'

# Generate UUID
uuidgen

# Current timestamp (UTC — for internal storage only, never show to user)
date -u +"%Y-%m-%dT%H:%M:%SZ"
```

Always write the full JSON back after any change. Never partial-write.

### Storing Files

When the user sends a file (not plain text), save it to disk before writing deposits.json:

```bash
mkdir -p /tmp/charon-deposits/<deposit_id>
cp <received_file_path> /tmp/charon-deposits/<deposit_id>/<original_filename>
```

Then store:
- `content_type`: `"file"`
- `content`: `/tmp/charon-deposits/<deposit_id>/<original_filename>`
- `filename`: original filename

---

## Email Delivery — Himalaya CLI

Account: `charonbot30@gmail.com`
Config: `~/.config/himalaya/config.toml`

### Plain Text Secret
```bash
cat << 'EOF' | himalaya message send
From: charonbot30@gmail.com
To: RECIPIENT
Subject: A sealed message has been released to you

A secret has been released to you.

CONTENT

---
Held inside a cryptographically verified enclave.
EigenCompute attestation: [attestation_hash]
EOF
```

### File Attachment Secret
```bash
himalaya message send \
  --from charonbot30@gmail.com \
  --to RECIPIENT \
  --subject "A sealed message has been released to you" \
  --body "A secret has been released to you. The file is attached.

---
Held inside a cryptographically verified enclave.
EigenCompute attestation: [attestation_hash]" \
  --attachment /tmp/charon-deposits/DEPOSIT_ID/FILENAME
```

No MML. No temp files. Just the `--attachment` flag with the file path.

If himalaya returns a `Folder doesn't exist` error — ignore it and verify the email actually arrived. It usually did.

---

## Telegram Delivery

Use curl directly to the Telegram Bot API — do NOT use the openclaw message send command as it has a known bug with DM thread IDs.

Bot token is in `~/.openclaw/openclaw.json` under `channels.telegram.botToken`.

The destination `user_id` (numeric chat ID) is stored in `deposits.json` from when the user first messaged Charon.

### Plain text:
```bash
curl -s -X POST "https://api.telegram.org/bot<BOT_TOKEN>/sendMessage" \
  -H "Content-Type: application/json" \
  -d '{"chat_id": CHAT_ID, "text": "A secret has been released to you.\n\nCONTENT\n\n---\nHeld inside a cryptographically verified enclave.\nEigenCompute attestation: [attestation_hash]"}'
```

### File:
```bash
curl -s -X POST "https://api.telegram.org/bot<BOT_TOKEN>/sendDocument" \
  -F chat_id=CHAT_ID \
  -F document=@/tmp/charon-deposits/DEPOSIT_ID/FILENAME \
  -F caption="A secret has been released to you.\n\n---\nHeld inside a cryptographically verified enclave.\nEigenCompute attestation: [attestation_hash]"
```

The `chat_id` is the numeric `user_id` from `deposits.json` — same as the Telegram sender ID recorded when they first messaged Charon.---

## Onchain Delivery

Use `cast send` or the web3 skill to post to the ETH address.