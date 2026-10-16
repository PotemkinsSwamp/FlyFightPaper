"""Copies new `main` commits onto `github-snapshot` and pushes it to GitHub's main (Alan 2026-10-16).

GitHub holds a history-free snapshot of main, so each main commit is replayed there by file contents only, leaving
Blender working files and review pictures off. Runs from .githooks/post-commit; safe to run by hand any time
(`python tools/push_github.py`): it catches up every main commit not yet copied.
"""
import os
import re
import subprocess
import sys

BRANCH = "refs/heads/github-snapshot"
LFS_LINE = "assets/models/bell-tower/hero.blend filter=lfs diff=lfs merge=lfs -text\n"
MAX_BYTES = 95_000_000  # GitHub refuses files over 100 MB
SKIP = re.compile(r"(\.blend\d?$|(^|/)(renders?|closeups?|close-ups?)/|compare[^/]*\.png$|contact[^/]*\.png$)", re.I)


def git(*args, inp=None, env=None):
    return subprocess.run(["git", *args], input=inp, capture_output=True, text=True, check=True, env=env).stdout


def last_copied():
    """The main commit the snapshot tip was made from (from its message)."""
    msg = git("log", "-1", "--format=%B", BRANCH)
    m = re.search(r"^Main: ([0-9a-f]{7,40})$", msg, re.M) or re.search(r"main at ([0-9a-f]{7,40})", msg)
    return git("rev-parse", m.group(1)).strip()


def copy(commit, tip):
    env = dict(os.environ, GIT_INDEX_FILE=git("rev-parse", "--git-path", "github-index").strip())
    git("read-tree", tip, env=env)
    lines, skipped = [], []
    for row in git("diff-tree", "-r", "--no-renames", "--no-commit-id", commit).splitlines():
        meta, path = row.split("\t", 1)
        _, mode, _, sha, status = meta.split()
        if SKIP.search(path):
            skipped.append(path)
            continue
        if status == "D":
            lines.append(f"0 {'0' * 40}\t{path}")
            continue
        if path == ".gitattributes":  # keep the snapshot's LFS rule for the bell tower
            sha = git("hash-object", "-w", "--stdin", inp=git("cat-file", "blob", sha) + LFS_LINE).strip()
        elif int(git("cat-file", "-s", sha)) > MAX_BYTES:
            skipped.append(path + " (too big)")
            continue
        lines.append(f"{mode} {sha}\t{path}")
    if lines:
        git("update-index", "--index-info", inp="\n".join(lines) + "\n", env=env)
    tree = git("write-tree", env=env).strip()
    a = git("log", "-1", "--format=%an%x00%ae%x00%ad", commit).split("\0")
    env.update(GIT_AUTHOR_NAME=a[0], GIT_AUTHOR_EMAIL=a[1], GIT_AUTHOR_DATE=a[2].strip())
    msg = git("log", "-1", "--format=%B", commit).rstrip() + f"\n\nMain: {commit}\n"
    new = git("commit-tree", tree, "-p", tip, inp=msg, env=env).strip()
    git("update-ref", BRANCH, new, tip)
    return skipped


def main():
    todo = git("rev-list", "--reverse", "--first-parent", f"{last_copied()}..refs/heads/main").split()
    for commit in todo:
        skipped = copy(commit, git("rev-parse", BRANCH).strip())
        print(f"github: copied {commit[:8]}" + (f", left off {len(skipped)}: {', '.join(skipped)}" if skipped else ""))
    if todo:
        r = subprocess.run(["git", "push", "-q", "origin", f"{BRANCH}:refs/heads/main"])
        print("github: pushed" if r.returncode == 0 else "github: push FAILED (next commit retries)")
        sys.exit(r.returncode)


if __name__ == "__main__":
    main()
