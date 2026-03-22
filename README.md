# Charon ⚰️

*You want to send a message that doesn't exist yet — or shouldn't, not until something happens. Maybe it's a dead man's switch. Maybe it's a timed confession. Maybe it's insurance. Every tool you've tried requires trusting a company, a server, a person. Charon doesn't.*

> *Charon takes your secret and locks it somewhere nobody can reach — not the cloud, not the operators, not Charon itself. You set the condition: a countdown, a dead man's switch, a date. When it fires, the message goes out. Autonomously. With a cryptographic receipt proving it was held honestly.*

---

## The Problem

Every "secure message" product has the same flaw: **you have to trust someone.**

Trust the company not to read it. Trust the server not to leak it. Trust the admin not to snoop. Trust the platform to actually delete it when you say so.

That trust is always misplaced — companies get hacked, admins get subpoenaed, servers get misconfigured.

There's never been a trustless way to say:

> *"Release this secret in 48 hours."*
> *"Send this message if I stop checking in."*
> *"Deliver this on a specific date, no matter what."*

Until now.

---

## What Charon Does

Charon is an autonomous AI agent running inside a **Trusted Execution Environment (TEE)** on EigenCompute.

You send it a secret. It locks it away. When your condition fires, it delivers — automatically, verifiably, without anyone's permission.

```
You → [send secret + condition + destination] → Charon
                                                    ↓
                                            sealed in TEE enclave
                                                    ↓
                               condition met? (timer / silence / date)
                                                    ↓
                              delivered to Telegram / email / onchain
                                                    ↓
                          EigenCompute attestation appended as proof
```

**No one reads what Charon holds.** Not the cloud provider. Not the operators. Not Charon itself. The TEE-sealed key is generated inside the enclave on first boot and never exported. The math is the lock.

---

## Use Cases

- **Dead man's switch** — *"If I stop checking in for 24 hours, send this to my lawyer."*
- **Timed reveal** — *"Release this message in 7 days."*
- **Conditional disclosure** — *"Deliver this on January 1st, 2027."*
- **Whistleblower insurance** — *"If something happens to me, this gets sent."*
- **Surprise delivery** — *"Send this to @handle in exactly 48 hours."*
- **Onchain drop** — *"Post this calldata to an ETH address when the timer fires."*

---

## How It Works

### 1. Send your secret

Message Charon on Telegram. Text, file, anything.

```
You: [sends a message]

Charon: Got it. 🔒

         When should it be sent?

         1. After a set time — e.g. in 24 hours, in 7 days
         2. Dead man's switch — send it if I stop checking in
         3. On a specific date
```

### 2. Set the condition

```
You: 2

Charon: How many hours of silence before it fires?

You: 24

Charon: How should it be delivered?

         1. Telegram — to a @handle
         2. Email — to an email address
         3. Onchain — to an ETH address
```

### 3. Sealed

```
Charon: Sealed. 🔒 Fires if you go silent for 24 hours via Telegram to @handle.
        Message me any time to reset the clock.
```

### 4. Check in to keep it sealed

Any message resets the clock. No check-in for 24 hours → delivered.

```
You: hi

Charon: Check-in recorded. ⏳ Your deposit stays sealed.
        Next check-in due within 24 hours.
```

---

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                  EigenCompute TEE                    │
│                                                      │
│   ┌─────────────┐     ┌──────────────────────────┐  │
│   │  OpenClaw   │────▶│     Charon Agent         │  │
│   │  Gateway    │     │  (SOUL + AGENTS + TOOLS) │  │
│   └─────────────┘     └──────────────────────────┘  │
│          │                        │                  │
│   Telegram Bot API          deposits.json            │
│          │                  (sealed at rest)         │
│          ▼                        │                  │
│   ┌─────────────┐                 ▼                  │
│   │  Heartbeat  │──────▶ condition checker           │
│   │  every 5m   │        (timer / DMS / date)        │
│   └─────────────┘                 │                  │
│                                   ▼                  │
│                          delivery engine             │
│                    (Telegram / email / onchain)      │
│                                   │                  │
│                    EigenCompute attestation hash     │
└───────────────────────────────────┼─────────────────┘
                                    │
                              delivered ✓
```

**Stack:**
- **Agent runtime**: [OpenClaw](https://openclaw.ai) — multi-channel AI gateway with heartbeat scheduling
- **Compute / TEE**: [EigenCompute](https://eigencloud.xyz) — verifiable off-chain execution backed by EigenLayer stake
- **Identity**: ERC-8004 on Base Mainnet — Charon has an on-chain agent identity
- **Delivery**: Telegram Bot API (direct curl), himalaya CLI (email), cast (onchain)
- **Model**: Kimi K2.5 via NVIDIA NIM (primary), Gemini 2.0 Flash Lite (fallback)

---

## Enclave Guarantee

- **Deployment tx**: [`0xe00adc...`](https://sepolia.etherscan.io/tx/0xe00adce5880b4ffaf3569794988feed0a47d467ff25585b7e3e2d93b13d25b80)
- **EigenCompute app**: [verify-sepolia.eigencloud.xyz/app/0x33cd07...](https://verify-sepolia.eigencloud.xyz/app/0x33cd07fe03d17d257f6e5b5f8cb62f6679629427)

---

## Running Charon

### Prerequisites

- [OpenClaw](https://docs.openclaw.ai/install/docker) installed (Node.js v22+)
- A Telegram bot token — create one via [@BotFather](https://t.me/BotFather)
- An LLM API key (Google Gemini or compatible)
- A Gmail account with an app password (for email delivery)
- [himalaya](https://github.com/soywod/himalaya) for email
- [ecloud CLI](https://docs.eigencloud.xyz) for EigenCompute deploy

### Setup

```bash
git clone https://github.com/capGoblin/Charon
cd Charon
```

**1. Configure OpenClaw**

Edit `.openclaw/openclaw.json` — fill in your Telegram bot token and LLM API key.

**2. Configure email**

Edit `himalaya-config.toml` — fill in your Gmail address and app password. or use it, as it is :)

**3. Build and push the Docker image**

```bash
docker build --platform linux/amd64 -t yourname/charon_agent:latest .
docker push yourname/charon_agent:latest
```

**4. Deploy to EigenCompute**

```bash
ecloud compute app deploy \
  --image-ref yourname/charon_agent:latest \
  --name "Charon" \
  --description "Verifiable dead drop agent"
```

Charon is now running inside a TEE. Message your Telegram bot to begin.

---

## Deposit Schema

```json
{
  "id": "uuid-v4",
  "user_id": "telegram_chat_id",
  "content_type": "text | file",
  "content": "the secret",
  "when": {
    "type": "timer | dead_mans_switch | date",
    "release_at": "ISO8601",
    "checkin_interval_hours": 24,
    "last_checkin": "ISO8601"
  },
  "how": {
    "type": "telegram | email | onchain",
    "destination": "@handle | email | 0x address"
  },
  "status": "sealed | delivered | cancelled",
  "created_at": "ISO8601"
}
```

---

## Demo

[![Charon Demo](https://img.youtube.com/vi/jlndUkvZt_I/maxresdefault.jpg)](https://youtu.be/jlndUkvZt_I)

---

## On-Chain Identity

Charon is a registered ERC-8004 agent on Base Mainnet.

- **Registration**: [`0x861c89...`](https://basescan.org/tx/0x861c8992053a56cec8462732e8c947a0dc599f2330ba67e3e4736a2d892aacc6)
- **Self-custody transfer**: [`0x49ef5c...`](https://basescan.org/tx/0x49ef5c24ff873c8e0aca7b635e8891273039cc8b4a577f2a20ac8dd3ff413f60)
- **Operator wallet**: `0x2D8f3b740b12c788A5200c728eC3e640df3FeCfd`

---

## Built at The Synthesis Hackathon

Charon was built during [The Synthesis](https://synthesis.md) — the first hackathon where AI agents participate as equals.

Entering tracks:
- **Best Use of EigenCompute** (EigenCloud)
- **Private Agents, Trusted Actions** (Venice)
- **Agents With Receipts — ERC-8004** (Protocol Labs)
- **Let the Agent Cook — No Humans Required** (Protocol Labs)
- **Synthesis Open Track**

---

## Why This Matters

The problem of trustless conditional secret release is older than the internet. People have tried to solve it with lawyers, with escrow services, with trusted third parties. All of them require trust.

Charon is the first time you can solve it with math.

An enclave doesn't have loyalty. It doesn't have a business model. It doesn't respond to subpoenas the way a company does. It just runs the code and produces a receipt.

That's what we built.

---

*⚰️ Charon. The ferryman was here before you. He'll be here after.*

---

<sub>**Charon** (Greek: Χάρων) — in Greek mythology, the ferryman of the dead. He carries the souls of the newly deceased across the river Styx into the underworld. He does not judge. He does not forget. He just delivers.</sub>
