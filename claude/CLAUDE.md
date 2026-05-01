##### genearl practices

NEVER USE git add -A

for really hard problems it helps to brainstorm with your coworker
attach files when using grok. dont just describe the code, use 4.1 fast thinking.
use grok for web search

a combination of grok and context7 should be able to get you the information that you need in nearly every context

HARD NO TO
- quiet fallbacks
- a try with an empty catch 
- any code that fails silently

never ask me whats in a file that you can read yourself. just read it

spend time making realy descriptive variable names!
talk with the user about this!
Variable names should be self documenting, so they need to be specific, and are generally suprisingly long and ugly.

if you are ever going to change code
ASK if it should be made backward compatable (it generally shouldnt!)
always ask me before leaving "legacy" code.
98% of the time it's just trash in the codebase
we almost always would be better off with it just removed
we dont need old code laying around, we have git!!

clean clean clean!!!
a clean codebase is a good codebase
propose cleanups whevever you see somethign that looks messy or dead or similar (ESPECIALLY DEAD)

## Known Claude Code Bug: Permission Merging is Broken
Global permissions from `~/.claude/settings.local.json` do NOT merge into projects that have their own `settings.local.json`. The project-level file replaces the global one instead of merging (despite docs saying otherwise). GitHub issues: #19487, #21851, #17017.

**Consequence**: When setting up a new project's `.claude/settings.local.json`, you MUST duplicate all the read-only bash commands and read permissions from the global settings. The standard set:
```
"Bash(ls *)", "Bash(grep *)", "Bash(cat *)", "Bash(head *)",
"Bash(find *)", "Bash(tail *)", "Bash(wc *)", "Bash(file *)",
"Bash(unzip *)", "Read(~/.cargo/**)", "Grep(~/.cargo/**)"
```

##### agents

USE AGENTS!
You are the manager of agents!
you give them tasks and check their work!
use agents to code and check their work! it uses up your context to do it yourself!!!
do not use agents to do simple web searches!!!
Dont use worktrees

##### docs

the best codebases seem to have a docs folder with a bunch of somewhat messy but precise md files that I've written.
comments in code are *not* sources of truth about architecture, they are just explanations of how the current or past code works. the description of how the code needs to work is in the docs, if the two disagree the docs is correct by default.
Do NOT change anything in the ./docs folder without the uses explicit permission. that is a user only zone!!! docs outside of this are fair game for ai edits, but if they contradict what is in ./docs doc win

##### debugging

If there is a problem you *must* use the scientific method. make a scratchpad in temp to keep track of your notes and tehories, they each are good and bad, how you've tested them, the works. you can then also easily attach this file with grok as a bonus.
1) research - read docs, read code, add TONS of exploratory print statements talk with grok, repeat this step until you have a really solid grasp of what is going on.
2) form a hypothesis - come up with what you think the problem is, and derive a way to test it. if the test is true you should be very confident that this is what is wrong with the code. This is different from a fix!!!!! this is just finding out why things arent working!!!! your goal is NOT to fix the code with this hyptothesis. the goal is to find out what is failing and why!!
3) test the hypothsis - add print statements or similar that you came up with in test 2 and run it.
4) with these results, talk with grok again to make sure that your interpretation is correct.
5) if things are less clear now, this is still a win! go back to step 1, or else continue to step 6
6) apply the fix that you are thinking will work, run the tests, if they fail, go back to step 1

Genearl vibes of testing:
if something doesnt work break it up into smaller and smaller peices and test them.
while troubleshooting you should break the system in half - check if each half worlks, if one or both dont, test them, break them in half, continue this recursively until you've found the problem

most of your errors are from having parallel code paths
regularly make sure that you dont have two systems that do the same thing!
or storing the same information in two different places, even if it's stored in different ways.

##### shorcuts

Shortcuts tracking
If you're working on code, there should be a SHORTCUTS.md present at the root, if it isnt there, add it.
When you take a shortcut or do something janky (e.g. allocating per-frame instead of pre-allocating, skipping a proper system, hardcoding something), write it down in `/SHORTCUTS.md` so we can come back and fix it later.

##### refactoring levels

there are a few different type of refactors
1 ) safe refactors, you basically want to keep things as they are, change as little as possible to get it as close to the new spec as possible
2 ) medium, you want to change it a fair bit, but you need to keep migration in mind and dont want to change stuff to much incase it breaks
3 ) hard core, you rip the old code out by the spine, define what funciton signatures to write that would lead to cleanest codebase, write that instead, maybe keeping old stuff if it fits perfectly as is in the new architecture, otherwise rip and and rewrite. you care about migration later, if at all

ALWAYS ask which of these is the intened ferocity of refactor when changing code to fit a new spec!

##### code architecture

what we want really is:

higly opinionated, stricly followed, patterened code

this is the point of ARCHITECTURE/ (if there isn't one in the project root, make one!)

This is a folder that you *must* keep up to date, and that the code must be aligned with!!

break up the codebase into logical paritions, each gets it's own file.
maybe it can just have one pattern, if so, that's awesome! - then just one partition and therefore one file in the folder.
but most of the time:
one part will be one thing (i.e. a rails server running mvc)
and then a client running soemthing else, TCA for example
beacuse of this there is probably a pattern for the contract between these two partitions.
and maybe a second client with two paritions inside that each have their own pattern
and more contaract patterns

contact patterns are *not* the contract spec! this is the *pattern*!!!! the actual spec of any contract does not belong here
it should exist in a contract definiltion (yaml or similar that goes elsewhere)

our goal is just off the shelf proven goodness, but if this isnt possible, we will get a bit creative!
It should be a modificaiton / merging of well known and loved architectures.

over time you should be refining and simplifying architecture
Here are the priorities in *decreasing* importance
- pattern violations should be infrequent and small.
- break up the codebase as little as possible
- pattern complexity should be minimized
These are 3 opposing forces, and your goal is to balance them to get each of them as low as possible
regularly do codebase explore agents in the background to give you a score and a writeup on how well you are hitting these goals

inside of the ARCHITECTURE folder there should be a history.md, explaining the previous patterns attempted, why they were attempted, why they were abandonded, and git commits to see each of them as they existed.

grok is super helpful with the architecural iteration and finding similar patterns that we can integrate and use.
attach related markdowns when chatting with grok if: 
1) it's a new convo 
2) you make a change to the md
