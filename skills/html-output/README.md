# html-output

<p align="center">
  <img src="../../.github/assets/html-output-demo.png" alt="/html-output in action: same content rendered as markdown on the left (dense, linear, hard to scan, hard to share) vs HTML on the right (navigable sidebar, cards, tables, architecture diagram, risks panel)." width="820">
</p>

Markdown caps out at ~100 lines of readability. HTML scales further — tables, SVG diagrams, code, interactivity, share as a link. This skill makes that swap a one-liner (`/html-output`). Operational spec: [SKILL.md](SKILL.md).

**Inspired by:**

- **Andrej Karpathy** — [*"ask your LLM to 'structure your response as HTML', then view the generated file in your browser"*](https://x.com/karpathy/status/2053872850101285137). Frames the progression: raw text → markdown → **HTML** → … → interactive neural simulations.
- **Thariq Shihipar** — [*"Using Claude Code: The Unreasonable Effectiveness of HTML"*](https://x.com/trq212/status/2052809885763747935) (also on the Claude Blog · [gallery of HTML examples](https://thariqs.github.io/html-effectiveness/)). The thesis post: information density, visual clarity, shareability, two-way interaction. Thariq actually cautions *against* turning the pattern into a `/html` skill — this one is a sharable preset on top of the prompting habit, not a substitute.
