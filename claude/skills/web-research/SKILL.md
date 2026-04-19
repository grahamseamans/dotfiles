---
name: web-research
description: How to research things on the web. Follow this for any questions requiring web lookup.
user-invocable: false
---

# Web Research

## Default: Use Grok

Use Grok (coworker MCP). Always. It's faster and more thorough than your own tools — for both complex research AND simple lookups.

See the coworker-usage skill for which model to use (start with `grok-4-1-fast-reasoning`, escalate to `grok-4.20-multi-agent-beta-0309` only if needed).

Enable web search on the request.

## When WebFetch is okay

A quick fetch for a specific URL the user gave you, or to grab a specific page you already know exists. 1-2 fetches, that's it.

## What to avoid

DO NOT get into long chains of searching and fetching. The pattern of: search → fetch result → search again → fetch another thing → search again — this almost never works and wastes enormous amounts of time. If you find yourself wanting to do more than 2 fetches in a row, stop and use Grok instead.

DO NOT use your own WebSearch tool unless Grok is genuinely unavailable. It is slow and misses things.

## Summary

- Need to know something? → Grok
- Specific URL to read? → WebFetch (1-2 max)
- Tempted to chain searches? → Stop. Use Grok.
