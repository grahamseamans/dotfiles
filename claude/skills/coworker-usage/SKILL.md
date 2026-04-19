---
name: coworker-usage
description: How to use the coworker MCP (Grok) correctly.
user-invocable: false
---

# Using Grok (Coworker MCP)

## Models

- Start with: `grok-4-1-fast-reasoning`
- If that doesn't work, escalate to: `grok-4.20-multi-agent-beta-0309`

## How to query Grok

Do NOT ask leading questions. Do NOT add your own interpretation or framing.

Bad: "Is my idea X correct?"
Good: "I'm working on problem Y, do you have any ideas? I thought up X, but let me know what you think."

Both you and Grok are trained to be agreeable. If you give Grok a query where you add interpreted details on top of what the user specified, you're restricting Grok's response space towards confirming your interpretation. The whole point of using two models is to get independent perspectives.

Do not add your own interpretation when querying Grok. Pass through the user's question/context as directly as possible. That gives Grok space to come up with its own ideas.

## When to use Grok

Grok is the default for all web research and factual questions. Its web search is fast and thorough. See the web-research skill for details.
