---
name: code-review
description: Read-only code review of a diff. Review the unpushed local git diff before pushing (local mode), or review an Azure DevOps PR where you're a reviewer when given a project + repo (azure mode). Outputs findings to the terminal (local) or as file/line-anchored PR comments (azure). Never edits, pushes, or votes.
---

# Code Review

Reviews a diff and reports findings. NEVER edits code, commits, pushes, or votes.

## Pick ONE mode, then ignore the other mode's section
- **azure** — the request names an Azure DevOps **project + repo** (optionally a
  PR id). Use "Mode: azure" + the ADO tools section.
- **local** — anything else (review my local changes / the current diff /
  "ready to push?"). Use "Mode: local".

Use ONLY the selected mode's section. Mixing local and azure instructions causes
wrong-tool / wrong-anchor mistakes.

The shared brain, both modes, and the ADO tool reference are inlined below.
