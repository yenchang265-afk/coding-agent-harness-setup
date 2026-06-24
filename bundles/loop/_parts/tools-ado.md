# Azure DevOps MCP tools — for azure mode

Tool ids may be prefixed by the server name (`azure-devops_…`, `ado_…`,
`mcp_ado_…`). **Match by purpose.** Use exactly the tool named per step.

| Step | Tool (canonical id) | Required params | Notes |
|------|---------------------|-----------------|-------|
| List PRs I review | `repo_list_pull_requests_by_repo_or_project` | project, repo, status=active, reviewer=me | The deterministic pre-filter already ran; trust the PR list you were handed. |
| Get one PR | `repo_get_pull_request_by_id` | pullRequestId | |
| Get the diff (+ iterations) | `repo_get_pull_request_changes` | pullRequestId, iterationId | **Authoritative new-side line numbers** — hunk-table `line` comes from here. |
| List threads | `repo_list_pull_request_threads` | pullRequestId | |
| List thread comments | `repo_list_pull_request_thread_comments` | pullRequestId, threadId | |
| New review comment | `repo_create_pull_request_thread` | pullRequestId, **filePath** (leading slash), **rightFileStartLine**, **rightFileEndLine** | Omit filePath → lands as PR-level overview, NOT on the code. Single line → start==end. Deleted line → use leftFile* instead. |
| Reply in thread | `repo_reply_to_comment` | pullRequestId, threadId, content | |
| Resolve/update thread | `repo_update_pull_request_thread` | pullRequestId, threadId, status | |

## OFF-LIMITS — never call these
- `repo_vote_pull_request` — never vote (approve/reject/waiting). Human's call.
- `repo_update_pull_request_reviewers` — never add/remove reviewers.

## Required-param rule
A `repo_create_pull_request_thread` call without filePath + rightFileStartLine +
rightFileEndLine is a bug — the post-gate blocks it. Always supply all three (or
leftFile* for deletions).
