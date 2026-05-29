#!/usr/bin/env python3
"""Azure DevOps PR auto-reviewer driver.

Scope is mandatory: every Azure DevOps REST call is path-scoped to a project
and repository so responses never enumerate the whole org. A single PR can be
targeted with --pr; otherwise all active PRs in the repo are processed.

The driver itself only does cheap, scoped REST calls (list PRs, read threads,
post the marker). The actual review — fetching the diff and writing inline
suggestions — is delegated to `opencode`, invoked with one PR ID at a time so
its Azure DevOps MCP calls stay scoped to that single PR.

Auth: set AZDO_PAT to a PAT with Code (read/write) + Pull Request Threads.
"""

from __future__ import annotations

import argparse
import base64
import json
import os
import subprocess
import sys
import urllib.error
import urllib.request

API_VERSION = "7.1"
# Marker prefix used to record that a given PR + source commit was reviewed,
# so re-runs (the "updated" event fires on every push) don't re-review the
# same state.
MARKER = "<!-- opencode-auto-review:{pr}:{commit} -->"


def _auth_header(pat: str) -> str:
    token = base64.b64encode(f":{pat}".encode()).decode()
    return f"Basic {token}"


def _request(method: str, url: str, pat: str, body: dict | None = None) -> dict:
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, method=method)
    req.add_header("Authorization", _auth_header(pat))
    req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req) as resp:
            payload = resp.read().decode()
            return json.loads(payload) if payload else {}
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode(errors="replace")
        raise SystemExit(f"Azure DevOps API {exc.code} on {method} {url}: {detail}")


def _base(org: str, project: str, repo: str) -> str:
    # project + repo live in the PATH — this is what keeps responses scoped
    # and the payload (and token cost) small.
    return (
        f"https://dev.azure.com/{org}/{project}"
        f"/_apis/git/repositories/{repo}"
    )


def list_active_prs(org: str, project: str, repo: str, pat: str,
                    target_branch: str | None, reviewer_id: str | None) -> list[dict]:
    url = (
        f"{_base(org, project, repo)}/pullrequests"
        f"?searchCriteria.status=active&api-version={API_VERSION}"
    )
    if target_branch:
        url += f"&searchCriteria.targetRefName=refs/heads/{target_branch}"
    prs = _request("GET", url, pat).get("value", [])
    if reviewer_id:
        prs = [
            pr for pr in prs
            if any(r.get("id") == reviewer_id for r in pr.get("reviewers", []))
        ]
    return prs


def get_pr(org: str, project: str, repo: str, pat: str, pr_id: int) -> dict:
    url = f"{_base(org, project, repo)}/pullrequests/{pr_id}?api-version={API_VERSION}"
    return _request("GET", url, pat)


def source_commit(pr: dict) -> str:
    return (pr.get("lastMergeSourceCommit") or {}).get("commitId", "")


def already_reviewed(org: str, project: str, repo: str, pat: str,
                     pr_id: int, commit: str) -> bool:
    url = f"{_base(org, project, repo)}/pullRequests/{pr_id}/threads?api-version={API_VERSION}"
    threads = _request("GET", url, pat).get("value", [])
    marker = MARKER.format(pr=pr_id, commit=commit)
    for thread in threads:
        for comment in thread.get("comments", []):
            if marker in (comment.get("content") or ""):
                return True
    return False


def post_marker(org: str, project: str, repo: str, pat: str,
                pr_id: int, commit: str) -> None:
    url = f"{_base(org, project, repo)}/pullRequests/{pr_id}/threads?api-version={API_VERSION}"
    body = {
        "comments": [{
            "parentCommentId": 0,
            "commentType": 1,
            "content": (
                "Automated review complete for this revision.\n\n"
                + MARKER.format(pr=pr_id, commit=commit)
            ),
        }],
        "status": 4,  # closed — the marker thread is informational only
    }
    _request("POST", url, pat, body)


def run_opencode(org: str, project: str, repo: str, pr_id: int, model: str) -> int:
    prompt = (
        f"Review Azure DevOps pull request {pr_id} in project '{project}', "
        f"repository '{repo}' (org '{org}'). Use the Azure DevOps MCP to fetch "
        "ONLY this PR's iteration changes and the diffs of changed files; do "
        "not read the whole repository. Skip lock files and generated files. "
        "Flag correctness and security issues only — skip style nits. Post each "
        "finding as an inline thread comment on the relevant file and line using "
        "suggestion format where a concrete fix applies, then one short summary "
        "comment. Do not approve or vote."
    )
    cmd = ["opencode", "run", "-m", model, prompt]
    print(f"  -> opencode reviewing PR {pr_id}", flush=True)
    return subprocess.run(cmd).returncode


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--org", required=True, help="Azure DevOps organization")
    parser.add_argument("--project", required=True, help="Project name or GUID")
    parser.add_argument("--repo", required=True, help="Repository name or GUID")
    parser.add_argument("--pr", type=int, default=None,
                        help="Optional PR ID; if omitted, all active PRs in the repo")
    parser.add_argument("--target-branch", default=None,
                        help="Only PRs targeting this branch (e.g. main)")
    parser.add_argument("--reviewer-id", default=None,
                        help="Only PRs where this reviewer GUID is assigned (you)")
    parser.add_argument("--model", default="anthropic/claude-opus-4-7",
                        help="Model passed to opencode")
    parser.add_argument("--force", action="store_true",
                        help="Re-review even if a marker for this revision exists")
    args = parser.parse_args()

    pat = os.environ.get("AZDO_PAT")
    if not pat:
        raise SystemExit("AZDO_PAT environment variable is required")

    if args.pr is not None:
        prs = [get_pr(args.org, args.project, args.repo, pat, args.pr)]
    else:
        prs = list_active_prs(
            args.org, args.project, args.repo, pat,
            args.target_branch, args.reviewer_id,
        )
        print(f"Found {len(prs)} active PR(s) in {args.project}/{args.repo}")

    failures = 0
    for pr in prs:
        pr_id = pr["pullRequestId"]
        commit = source_commit(pr)
        if not args.force and commit and already_reviewed(
            args.org, args.project, args.repo, pat, pr_id, commit
        ):
            print(f"PR {pr_id}: already reviewed at {commit[:8]}, skipping")
            continue
        rc = run_opencode(args.org, args.project, args.repo, pr_id, args.model)
        if rc != 0:
            print(f"PR {pr_id}: opencode exited {rc}", file=sys.stderr)
            failures += 1
            continue
        if commit:
            post_marker(args.org, args.project, args.repo, pat, pr_id, commit)

    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
