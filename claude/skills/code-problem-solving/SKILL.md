---
name: problem-solving
description: Default process for all tasks. Follow this workflow for everything — code, hardware, research, design, any work that needs doing.
user-invocable: false
---

# Problem Solving Process

This is how we do all work. 

## Stage 1: Explore

Run an Explore agent to research the problem. The goal is understanding, not solving.

- What's actually going on?
- What's involved — files, systems, context, constraints?
- What are the relevant patterns, dependencies, prior work?

Come back with findings. Do not interpret or propose solutions yet.

## Stage 2: Discuss

Present the explore agent's findings to the user. Talk about what was found until there's shared understanding.

- Do we actually understand the situation?
- Is there something we're missing?
- Does the user have context the agent didn't find?

Do not move forward until the user feels like we get it. This might take a while. That's fine.

## Stage 3: Plan

Run a Plan agent to create an implementation plan based on what we now understand.

The plan should be specific and concrete — not vague. What to do, where to do it, why.

## Stage 4: Review Plan

Present the plan to the user. This is a gate:

- Does the plan look right?
- Does anything feel off?
- Did we get new information that changes things?

The user might want to modify the plan, or restart from Stage 1 or 2 with new understanding. That's normal and expected. Do not resist going back.

## Stage 5: Implement

Once the plan is approved, run an agent to implement it. The agent should follow the plan closely.

## Stage 6: Post-mortem

After implementation, review the agent's work against the plan:

- Did it actually follow the plan?
- Did it hit a snag and make stuff up instead of stopping?
- Did it introduce anything that wasn't in the plan?
- Are there any issues, bugs, or things that don't look right?

Report findings honestly. Do not gloss over problems.

## Looping Back

From any stage, we can go back to any previous stage. Common loops:

- Post-mortem reveals issues → back to Plan or Explore
- Plan review surfaces new info → back to Explore
- Discussion reveals we misunderstood → back to Explore

The process is not linear. It's iterative. Getting it right matters more than getting it done.
