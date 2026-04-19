---
name: parts-sourcing
description: How to use DigiKey and Mouser MCP tools for electronics parts sourcing.
user-invocable: false
---

# Parts Sourcing — DigiKey & Mouser

## Always use agents

The DigiKey and Mouser MCP tools consume massive amounts of context. Always run parts searches through agents, never in the main conversation.

## What the tools are good for

- Searching for specific parts by keyword or part number
- Checking stock and pricing
- Finding datasheets and product media
- Finding substitutions for out-of-stock parts
- Comparing options across DigiKey and Mouser

## Workflow

1. User needs a part or has a question about availability/pricing
2. Spawn an agent to do the search
3. Agent comes back with findings
4. Discuss results with user in main conversation

Keep the heavy MCP traffic in agents. Keep the main conversation clean.
