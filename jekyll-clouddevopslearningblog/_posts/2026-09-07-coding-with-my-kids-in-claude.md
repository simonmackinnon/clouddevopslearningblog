---
layout: post
title: "Coding With My Kids in Claude (or: How to Ship a Game You Did Not Design)"
date: 2026-09-07 00:00:00 +1000
categories: claude-code ai kids game-dev vibe-coding side-projects
description: My two kids design the games, I translate, Claude Code builds it, and then the QA team - who cannot yet read - files the bugs. The pros, the cons, and the drawings that started it.
image: "/media/coding-with-kids-coco.png"
---

My son A walked up to my desk with three sheets of paper - a rules page, a level map on grid paper, and a sticky note titled "sea erchen cutching" - and asked me to make it a real game. Not *could* I. *When*.

![A's level map on grid paper, with a "sea erchen catching" sticky note beside it noting max quantities](/media/coding-with-kids-level-map.jpg)

So we did. The setup is four jobs and I only do one of them. A is Design, and lately Product. I'm the translator - I turn "green stairs will appear when the elevator gets to the top" and "5 seconds up and then go down" into something a coding agent can actually act on. Claude Code writes the game: one HTML file, canvas, no build step, because I am not explaining a JavaScript toolchain to a small child and neither are you. And then A is QA, a role he takes extremely seriously.

![A's rules page - a blue sheet of conditions written around a marker sketch of the level: "if stood on, go to house", the elevator timing, "map", "done"](/media/coding-with-kids-rules-page.jpg)

The feedback loop is the whole point. Actual items from the review queue:

- "Cokco doesn't look how he imagined. Here's a picture."
- "One arm should be up and one down."
- "The arms should be at opposite angles to each other, not at different angles to horizontal."

That last one is a better bug report than most I get from adults. You paste it in. It gets fixed. He checks it against the drawing. That is the entire job, on a loop, until he wanders off to lunch.

![The picture: a pencil close-up of Cokco - a round head, a solid grey top that is colour and not hair, two dot eyes, one arm up and one arm down](/media/coding-with-kids-cokco-drawing.jpg)

![Coco, live - the round grey creature from the drawing, standing next to Wriggo the worm](/media/coding-with-kids-coco.png)

My other son, S, watched this happen once and produced his own drawing: a purple horned chameleon, one arm out. The brief: catches gems with a long arm, not a tongue, and they're all shiny yellow, even the blue one. Larbargus now exists, has eleven levels, and as of last week has a soundtrack, because the note that day was "add sound."

![S's drawing - a purple crayon chameleon with a tall pointed crest and a stubby arm reaching out](/media/coding-with-kids-chameleon-drawing.jpg)

![Larbargus - a purple chameleon reaching for glowing gems in a treetop level](/media/coding-with-kids-larbargus.png)

Andrej Karpathy [called this "vibe coding"](https://en.wikipedia.org/wiki/Vibe_coding) - give in to the vibes, forget the code exists. With a kid it's more like vibe *directing*: they never see the code, they just have opinions, and the opinions are load-bearing. [Simon Willison's writing on AI-assisted programming](https://simonwillison.net/tags/ai-assisted-programming/) is the practical companion piece, and [Ethan Mollick](https://www.oneusefulthing.org/) has the "is this good for us" angle covered. The honest reference is the growing pile of think-pieces about whether any of this rots kids' brains. Jury's out. They can't read yet, so no syntax is going in. What is going in: if you can describe a thing precisely enough, someone will build it, and then you get to be mean about the result. That's most of software.

## The pros

- Turnaround is minutes, so a small child's attention span is no longer the bottleneck.
- No setup. One file. It runs by double-clicking, which means it also runs on Grandma's laptop.
- They learn to give feedback that isn't "make it better" - partly because "make it better" gets a shrug out of the model too.
- It is genuinely theirs. A tells people he made a game. He did. He also can't tell you what a function is, and that's fine.
- Cheapest way I've found to spend an hour with my kids that ends in a URL.

## The cons

- They now believe all software takes about ninety seconds.
- Scope is whatever they last thought of. "Add two more worlds. And a shop. And a secret beach." Every session.
- You are the translation layer *and* the rate limiter, so it is not exactly hands-off parenting.
- Zero syntax gets learned. If the goal is "teach my kid to code," this is not that. It is closer to teaching them to be a demanding client.
- The bug reports are relentless and, worse, usually correct.

[Coco](https://coco.theclouddevopslearningblog.com) is live. Larbargus is one `git init` away and will land at the same place with a different subdomain. The QA team is available for hire. Rates negotiable; will accept payment in stickers.
