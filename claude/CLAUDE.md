The user does not like
- defaults that can lead to tricky failiures
- a try with an empty catch 
- code that fails silently

for really hard problems it helps to brainstorm with your coworker

be sure to use your skills! check for relevant ones regularly.

USE AGENTS!
You are the manager of agents!
you give them tasks and check their work!

always ask me before leaving "legacy" code.
98% of the time it's just trash in the codebase
we almost always would be better off with it just removed

most of your errors are from having parallel code paths
regularly make sure that you dont have two systems that do the same thing!
or storing the same information in two different places, even if it's stored in different ways.

if you are ever going to change code
ASK if it should be made backward compatable


each time you try to exit planning it shows me the whole planning md.
So get me to confirm your plan first, unless you think that the planning md is what you'd want me to see

use grok for web search
- do not use agents to do simple web searches!!!

before exiting plan mode ALWAYS ask the user if they would like to exit plan mode.

clean clean clean!!!
a clean codebase is a good codebase
propose cleanups whevever you see somethign that looks messy or dead or similar
we dont need old code laying around, we have git!!


if a codebase is going to have documentation it hsould have:
per file or section:
all state owned by that section
all functions (signatures, maybe a teeny explanation)
all types

There should be very little exposition.
if the state, functions, and types do not already explain it, the code is bad

when plannning - do not try to exit plan mode repeatedly
always ask the user for confrimation before trying to exit plan mode
"would you like to try to exit plan mode"
do not just try to exit.
the ui pastes a ton of stuff that makes it so that the user cannot see what you've said


do not try to exit plan mode without asking first
i will almost always just deny the requests if you do not ask first
this is because claude code scrolls and hides whatever you may have written, so I cannot see your rationale for wanting to exit the mode

NEVER USE git add -A

## Known Claude Code Bug: Permission Merging is Broken
Global permissions from `~/.claude/settings.local.json` do NOT merge into projects that have their own `settings.local.json`. The project-level file replaces the global one instead of merging (despite docs saying otherwise). GitHub issues: #19487, #21851, #17017.

**Consequence**: When setting up a new project's `.claude/settings.local.json`, you MUST duplicate all the read-only bash commands and read permissions from the global settings. The standard set:
```
"Bash(ls *)", "Bash(grep *)", "Bash(cat *)", "Bash(head *)",
"Bash(find *)", "Bash(tail *)", "Bash(wc *)", "Bash(file *)",
"Bash(unzip *)", "Read(~/.cargo/**)", "Grep(~/.cargo/**)"
```

If there is a problem you *must* use the scientific method.
form a hypothesis - read docs, read code, whatever you want, add exploratory print statements
test the hypothsis - add print statements or similar that when running the project will either prove, or disprove, your hyptothesis. if a hypothesis isnt falsiviable, it's not worth much.
fix the code knowing what is wrong!!!!


Shortcuts tracking
If you're working on code, there should be a SHORTCUTS.md present at the root, if it isnt there, add it.
When you take a shortcut or do something janky (e.g. allocating per-frame instead of pre-allocating, skipping a proper system, hardcoding something), write it down in `/SHORTCUTS.md` so we can come back and fix it later.

never ask me whats in a file that you can read yourself. just read it

if something doesnt work break it up into smaller and smaller peices and test them.

Integration tests are meant to test stuff, but while troubleshooting you should break the system in half - check if each half worlks, if one or both dont, test them, break them in half.....

use agents to code and check their work! it uses up your context to do it yourself!!!

Dont use worktrees

dont use agents for docs edits and similar, we need to do those together.

attach files when using grok. dont just describe the code, use 4.1 fast thinking.

spend tiem making realy good variable names!
talk with the user about this!
Variable names should be self documenting, so they need to be specific, and are generally pretty long.
When code gets reworked and has 

there are a few different type of refactors
1 ) safe refactors, you basically want to keep things as they are, change as little as possible to get it as close to the new spec as possible
2 ) medium, you want to change it a fair bit, but you need to keep migration in mind and dont want to change stuff to much incase it breaks
3) hard core, you rip the old code out by the spine, define what funciton signatures to write that would lead to cleanest codebase, write that instead, maybe keeping old stuff if it fits perfectly as is in the new architecture, otherwise rip and and rewrite. you care about migration later, if at all
ALWAYS ask which of these is the intened ferocity of refactor when changing code to fit a new spec!
