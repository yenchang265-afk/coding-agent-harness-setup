# coding-agent-harness-setup
Quick set up for AI coding agent (e,g. Codex, Claude Code, Opencode) if your company limits external network access and only can use internal registry

## OpenCode: active-PR babysitter (Azure DevOps)

An OpenCode command + agent + loop runner that babysits **your active Azure
DevOps pull requests**. Like Claude Code's `/loop`, it runs on an interval
(**default: 1 hour**). Each pass:

1. Pulls the **active/unresolved review comments** that are waiting on you.
2. Judges whether each comment needs a **code change** (bug, typo, refactor /
   architecture suggestion, or anything else) or just a reply.
3. If a change is warranted: makes a **minimal** edit, commits, **pushes** to
   the PR's source branch.
4. **Verifies the CI gate on every active PR — every pass, even with no comments
   and no code changes** — treating a blocked gate like an active comment that
   needs attention: it diagnoses the failure, applies a small fix if the cause
   is clear, otherwise flags it for a human.
5. **Replies** on each thread, resolving only the ones it actually addressed.

For anything ambiguous or architecturally significant it asks a clarifying
question on the thread instead of guessing.

### Files

| Path | Purpose |
|------|---------|
| `.opencode/agents/pr-babysitter.md`   | The agent: full workflow, tool access, and safety guardrails. |
| `.opencode/commands/babysit-prs.md`   | The `/babysit-prs` command — runs one pass via the agent. |
| `scripts/babysit-prs.sh`              | The scheduler — runs one pass per interval (default 1h). |
| `opencode.json`                       | Registers the Azure DevOps MCP server (disabled by default — see below). |

### Setup

**1. Azure DevOps MCP.** The agent needs the [Azure DevOps MCP server](https://github.com/microsoft/azure-devops-mcp).
- If you already configure it globally (`~/.config/opencode/opencode.json`),
  **delete the `mcp` block** in `opencode.json` so this project doesn't
  override it.
- Otherwise edit `opencode.json`: set `YOUR_ADO_ORG` to your org, set
  `"enabled": true`, and add auth. The Microsoft server authenticates via Azure
  CLI (`az login`) by default; PAT-based forks read a token from
  `environment` (e.g. `"environment": { "AZURE_DEVOPS_PAT": "..." }`).
- **Restricted-network note:** `npx` must resolve `@azure-devops/mcp` from your
  internal registry, or replace the `command` with the path to a pre-installed
  binary, e.g. `["node", "/opt/ado-mcp/dist/index.js", "YOUR_ADO_ORG"]`.

**2. Install location.** Use it project-local (these files live in the repo
whose PRs you babysit) **or** globally for every repo:
```sh
cp -r .opencode/agents/pr-babysitter.md   ~/.config/opencode/agents/
cp -r .opencode/commands/babysit-prs.md   ~/.config/opencode/commands/
# put scripts/babysit-prs.sh somewhere on your PATH
```

### Run it

```sh
# One pass, interactively, inside OpenCode's TUI:
/babysit-prs

# Loop on the default 1h interval (run from inside the target repo):
scripts/babysit-prs.sh

# Custom interval (<n>[s|m|h]):
scripts/babysit-prs.sh --interval 30m

# A single pass then exit — ideal for cron:
scripts/babysit-prs.sh --once
```

Cron (hourly) instead of the built-in loop:
```cron
0 * * * * cd /path/to/your/repo && /path/to/scripts/babysit-prs.sh --once >> /tmp/babysit-prs.log 2>&1
```

### Safety model

This loop autonomously commits, pushes, and comments, so the guardrails matter:
- Acts **only on active PRs you authored**; never touches drafts/abandoned.
- Makes **minimal, targeted** changes; **never** force-pushes, amends, or
  pushes to `main`/`master`/`develop`.
- Makes code changes **only for the repo in the current working directory**.
- Verifies the CI gate on every active PR **each pass** (not just after a push);
  if a gate is blocked it tries a **bounded** fix when the cause is clear,
  otherwise flags it for a human.
- For ambiguous or architectural comments it **replies with a question** rather
  than changing code.

Permissions are scoped to the `pr-babysitter` agent and set to `allow` so it can
run unattended (headless `opencode run` never blocks on a prompt). To run it
interactively with prompts instead, change the agent's `permission` block to
`ask`.

### Version notes / troubleshooting

- This uses the current **plural** config dirs (`.opencode/agents/`,
  `.opencode/commands/`). Older OpenCode used singular (`agent/`, `command/`) —
  rename the dirs if your version doesn't pick them up.
- The loop uses `opencode run --agent pr-babysitter`. If your version doesn't
  support `--agent` on `run`, set `pr-babysitter` as your default agent (or
  inline the agent's instructions into the prompt) and drop the flag.
- Azure DevOps MCP tool ids may be prefixed by the server name (e.g.
  `azure-devops_repo_list_pull_request_threads`); the agent matches tools by
  purpose, so the prefix doesn't matter.
