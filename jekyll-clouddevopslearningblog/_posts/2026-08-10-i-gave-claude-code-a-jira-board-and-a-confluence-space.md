---
layout: post
title: "I Gave Claude Code a Jira Board and a Confluence Space — Here's How It's Running My Side Projects"
date: 2026-08-10 00:00:00 +1000
categories: claude-code jira confluence ai-agents devops automation
description: How I wired Claude Code into Jira and Confluence with a design-doc → breakdown → work-ticket skill chain so it can drive real feature work end-to-end across my side projects — the gotchas, the guardrails, and what's next.
image: "/media/claude-agent-workflow-architecture.svg"
---

I've got two kids under seven and a full-time job as a corporate senior cloud software engineer, which means my actual engineering hours for anything of my own are whatever's left over between lunch-making, school drop-off, pick-up, and whatever the day job needed today — a window that closes fast and does not care that you were mid-thought. And in that window I'm somehow running [Kids Code Realm](https://coderealm.theclouddevopslearningblog.com), [TypeStar](https://typestar.theclouddevopslearningblog.com), [Breweries Near Me](https://breweriesnearme.theclouddevopslearningblog.com), [StoryReads](https://bedtime.theclouddevopslearningblog.com), [MemeCloud](https://memes.theclouddevopslearningblog.com/?template=181913649), and this blog, all at once. For a while my process for all of them was the same: open the repo, tell Claude Code what I wanted in a paragraph, watch it write code, review the diff, ship it — usually with about eleven minutes to spare before I had to go find shoes. That works fine for small changes. It falls apart the moment a feature needs more than one sitting, or I come back three days later, in the next spare eleven minutes, and can't remember what "add the readiness check thing" was supposed to mean.

So I stopped treating Claude Code like a smart autocomplete and started treating it like a junior engineer on a real team — one with a backlog, a definition of done, and a paper trail. That means Jira for tickets and Confluence for design docs, wired up through Claude's MCP support and a small chain of custom skills. This post is what that setup actually looks like, what broke while I built it, and where I'm taking it next.

---

## The shape of the workflow

Every non-trivial feature now goes through three phases, each backed by its own [Claude Code skill](https://docs.claude.com/en/docs/claude-code/skills): `design-doc`, `breakdown`, and `work-ticket`. The first two run once per feature. The third runs once per `/loop` iteration, chewing through the backlog a ticket at a time.

![Diagram of the design-doc, breakdown, and work-ticket skill chain connecting Claude Code to Jira and Confluence via the Atlassian MCP server, with a test/CI gate before any ticket is marked ready for human review](/media/claude-agent-workflow-architecture.svg)

**`design-doc`** turns a feature request into an architecture doc — affected components, data flow, new API surface, security/performance notes — and publishes it straight to Confluence. It stops there deliberately. Ticket creation is much harder to undo than an edit to a doc, so the skill waits for me to actually read the design and confirm it before anything downstream happens.

**`breakdown`** takes a confirmed design and turns it into a Jira Epic with child Stories, Tasks, and Bugs. Every ticket gets acceptance criteria and a **Test Plan** section — Unit is always required, Integration/E2E/Regression are pulled in based on what the ticket touches. Dependencies become Jira's native "blocks / is blocked by" links, so the next phase picks tickets up in the right order instead of guessing.

**`work-ticket`** is the workhorse. Invoked once per loop iteration, it claims the next unblocked `To Do` ticket, branches, implements the change, writes exactly the tests the Test Plan named, and then runs a full local gate — unit tests, e2e if specified, a full build. Nothing moves past `In Progress` on a self-attestation. If everything passes, it opens a PR and polls `gh pr checks` until CI actually reports green before touching the ticket status again. Only then does it flip Jira to `In Review` — merging is still mine, every time.

If a ticket turns out to be ambiguous, or a test genuinely won't pass after a real attempt, or CI stays red: the skill sets Jira's **Flagged** field to `Impediment`, leaves a comment explaining exactly what it tried, sends me a push notification, and moves on to the next ticket rather than spinning on the same failure. I'd rather get pulled in on a blocked ticket than discover later that a loop quietly skipped a failing test to force a green checkmark.

## What actually broke while I set this up

None of this worked on the first try, which felt worth being honest about given this blog's whole premise.

**The MCP config has to live at the real workspace root.** I opened VS Code with `~/workspace` as the root and each project — coderealm, breweriesnearme, typetastic — as a subfolder underneath it. Dropping `.mcp.json` inside a project subfolder produced no error and no server. Skills get discovered per-subfolder just fine; MCP servers apparently don't use the same resolution and need to sit at the actual opened workspace root. One relocation later, the Atlassian tools showed up and every project shares the same server config.

**Confluence's Mermaid embed is broken on my site.** The design-doc skill originally emitted `language-mermaid` code blocks, which Confluence auto-wraps in a rendering extension — except that extension throws "Error loading the extension!" on this instance and just fails silently on save. I rebuilt diagrams as native Confluence layout HTML instead (`layout-two-equal` sections with panel divs for architecture splits, plain numbered lists for sequences), and now only keep Mermaid source around as inert text for pasting into mermaid.live later. Two early design docs had shipped with the broken embed before I caught it and had to be fixed after the fact.

**Skill names collide across projects.** Both coderealm and breweriesnearme have their own `.claude/skills/design-doc`. Invoking the bare skill name while working in breweriesnearme resolved to *coderealm's* copy — confirmed by the reported base directory — even though a qualified `breweriesnearme:design-doc` form seemed like it should have worked and instead errored as unknown. I haven't found the real fix yet beyond staying alert to which project's skill actually got injected; distinctly-named skills per project is the fallback if it keeps happening.

**A "done" ticket isn't necessarily final.** Kids Code Realm's first real feature was a "Jump to World" button that respected locked-world state — implemented, tested, shipped. Looking at it live, I realised locked worlds should still be reachable, just gated by a readiness check rather than hard-blocked. That produced a whole follow-up Epic that explicitly *removed* the disabled-button state the first ticket had just added. Nothing was wrong with the process — the design was confirmed, the tests passed, CI was green — the requirement itself just didn't fully reveal itself until there was something real to click on.

## The same workflow, adapted per repo

I copied the coderealm setup onto Breweries Near Me expecting a clone, and immediately hit a real difference: that repo has no test runner and no PR-triggered CI at all — its GitHub Actions deploy straight to production S3/CloudFront on push to `master`. Rather than pretend a test gate exists where it doesn't, the adapted `work-ticket` skill's first-ever ticket was "add Jest," and — more importantly — the skill is written to *never* merge its own PR on that repo, because a merge there is an immediate production release. Same three skills, same Jira/Confluence backbone, genuinely different guardrails because the repos are at genuinely different levels of engineering maturity. That's the part I'd underestimated going in: this isn't a template you stamp out once, it's a workflow that has to read the room per project.

## Spec-first beats winging it — most of the time

I've noticed I fall into two different modes with Claude Code, and for a long time I was picking between them by accident rather than on purpose. One is winging it: type a rough ask, get a diff back, correct it, get another diff, and twenty exchanges later something works — except no single decision in there was made on purpose, each one was just a reaction to whatever the last diff got wrong. The other is writing it down first: spend the unglamorous time upfront saying exactly what I want, then let the agent take one real pass at it. Winging it feels faster, because it hands you something to look at within thirty seconds and a small hit of progress every couple of minutes after that. Writing it down first feels slow, because you're sitting there typing while nothing's happening on screen yet. The uncomfortable part: if you can't actually write the spec, you probably don't know what you want yet — and no amount of back-and-forth with a model is going to work that out for you. It'll just generate twenty confident guesses at something you never pinned down.

Sitting with that, I realised the whole Jira/Confluence chain above is basically me building a habit I don't reliably have — writing the spec first — into a process I can't skip on a night when I'm tired and there's twenty minutes before pick-up. `design-doc` isn't supposed to proceed on an ambiguous request — it's meant to ask first, not guess. `breakdown` won't create a ticket without acceptance criteria and an explicit Test Plan. `work-ticket` treats that as the real spec and takes one genuine pass at it: implement, write exactly the named tests, run the full gate, then open a PR. When it can't satisfy the spec, it doesn't quietly negotiate down to something adjacent — it flags itself blocked and stops. There's no chat transcript to reconstruct later; the design doc and the ticket *are* the record of what was decided and why.

It's not a clean win, though. The "Jump to World" story above is the honest counter-example: the design was confirmed, the spec was written down, the tests passed — and the requirement still turned out to be wrong once it was live. Writing the spec first protects you from not knowing what you typed six exchanges ago. It doesn't protect you from a spec that was confidently wrong, especially for UX calls that only really reveal themselves once there's something on screen to click. And for genuinely small, cheap-to-redo changes — a copy tweak, a button colour — I still go straight to winging it, because writing a Confluence page for that would be the actual waste. The line I've landed on: write it down first for anything worth being able to explain later, wing it for anything worth just throwing away.

## Where this is going next

The current setup is solid for one thing: working a backlog inside a single VS Code session, one ticket per loop, with me merging by hand. That's a good floor, not a ceiling. Here's what's next, roughly in the order I'll get to it:

1. **Getting off VS Code as the only place this runs.** Everything today lives inside one IDE session — if the laptop's closed, the loop's not running. I want the design-doc → breakdown → work-ticket chain to run from a headless or cloud session so a backlog can grind forward without a terminal open in front of me.

2. **Voice elaboration for the fuzzy parts.** The weakest link in this whole chain is still *me* writing the first paragraph of a feature request well enough for `design-doc` to work from. Talking through a half-formed idea out loud, with Claude asking clarifying questions back, would probably produce a better starting brief than typing does — especially for the "I want the world map to feel more alive" class of request that doesn't have a crisp shape yet.

3. **Claude on a schedule, not just in a loop.** Right now `/loop` only runs while I've deliberately started a session. Cron-style routines that pick up the next unblocked ticket on a schedule — say, a nightly pass across whichever project has open `To Do` tickets — would turn this from "a thing I run" into "a thing that runs."

4. **More of the deployment path automated.** Every new project already gets a scoped IAM user, a Terraform state bucket, and its GitHub secrets provisioned by a two-script bootstrap pattern, deliberately never sharing one IAM identity across projects. The next step is folding routine infra changes — not just first-time setup — into what `work-ticket` can safely do on its own, instead of infra tickets always needing me at the keyboard.

5. **Agent-reviewed PRs, with real teeth.** `work-ticket` stops at `In Review` today because I don't yet trust an agent to approve and merge its own work unsupervised. I'd rather get there deliberately: a separate reviewing agent — not the same one that wrote the code — checking a PR against the ticket's acceptance criteria and test plan, with merge authority scoped tightly (small diffs, green CI, no infra/auth changes) before it's allowed to touch anything higher-stakes.

6. **Actual orchestration across projects, not just within one.** Five projects, five backlogs, one me. The logical next step is something that looks across all of them and decides where a loop iteration is best spent next, instead of me manually pointing `/loop` at whichever repo I happen to have open.

None of these are a rewrite of what's here — they're extensions of a pattern that's already proven itself on real tickets, with real test gates, and at least one real "actually, wait" moment after something shipped. That last part is the whole point of Test Plans and human-gated merges in the first place: the process is built to catch the moments where the plan was right and the requirement still wasn't.
