"""
Fake-project integration checks for the local Vidux automation lane.

These tests intentionally use disposable fixtures:
- vidux planning is exercised through this repo's scripts.
- ledger worktree GC is exercised against the local ledger skill when present,
  but skips cleanly on machines that do not have Leo's skill repo installed.
"""

import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from datetime import datetime, timezone
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
PLAN_GC = ROOT / "scripts" / "vidux-plan-gc.py"
VIDUX_LOOP = ROOT / "scripts" / "vidux-loop.sh"
LEDGER_SKILL_DIR = Path(
    os.environ.get("LEDGER_SKILL_DIR", Path.home() / "Development" / "ai" / "skills" / "ledger")
)
LEDGER_CLASSIFY = LEDGER_SKILL_DIR / "scripts" / "worktree_classify.sh"
LEDGER_GC = LEDGER_SKILL_DIR / "scripts" / "worktree_gc.sh"


def run(cmd, *, input_text=None, env=None):
    return subprocess.run(
        cmd,
        input=input_text,
        capture_output=True,
        text=True,
        env=env,
        check=False,
    )


def write_fake_plan(plan_dir: Path) -> None:
    lines = [
        "# Fake Vidux Project",
        "",
        "## Purpose",
        "Exercise automation primitives without touching real projects.",
        "",
        "## Evidence",
        "- [Source: fake-project fixture] Disposable test plan.",
        "",
        "## Constraints",
        "- ALWAYS: operate only on fake fixtures.",
        "- NEVER: mutate real projects from this test.",
        "",
        "## Tasks",
    ]
    lines.extend(
        f"- [completed] T{i}: shipped task {i} [Evidence: fixture] [Shipped: sha{i}]"
        for i in range(1, 36)
    )
    lines.extend(
        [
            "- [pending] Task P: queued fake work [Evidence: fixture] [ETA: 1h]",
            "- [in_progress] Task IP: active fake work [Evidence: fixture] [ETA: 1h]",
            "",
            "## Decision Log",
            "- [DIRECTION] [2026-04-24] Keep fake-project tests deterministic.",
            "",
            "## Progress",
            "- [2026-04-24] Fixture created.",
            "",
        ]
    )
    plan_dir.joinpath("PLAN.md").write_text("\n".join(lines))

    plan_dir.joinpath("INBOX.md").write_text(
        "# Inbox\n\n" + "\n".join(f"- fake inbox item {i}" for i in range(1, 24)) + "\n"
    )
    investigations = plan_dir / "investigations"
    investigations.mkdir()
    stale = investigations / "stale.md"
    stale.write_text("# stale investigation\n")
    stale_time = datetime(2025, 1, 1, tzinfo=timezone.utc).timestamp()
    os.utime(stale, (stale_time, stale_time))


class FakeProjectFlowTests(unittest.TestCase):
    def setUp(self):
        self.tempdir = tempfile.TemporaryDirectory(prefix="vidux-fake-project-")
        self.root = Path(self.tempdir.name)

    def tearDown(self):
        self.tempdir.cleanup()

    def test_vidux_plan_gc_and_loop_selection_on_fake_project(self):
        write_fake_plan(self.root)

        gc_result = run([sys.executable, str(PLAN_GC), "--json", str(self.root)])
        self.assertEqual(gc_result.returncode, 0, gc_result.stderr + gc_result.stdout)

        payload = json.loads(gc_result.stdout)
        completed = next(t for t in payload["targets"] if t["target"] == "completed-tasks")
        inbox = next(t for t in payload["targets"] if t["target"] == "inbox")
        investigations = next(t for t in payload["targets"] if t["target"] == "investigations")
        self.assertEqual(completed["completed_after"], 20)
        self.assertEqual(inbox["entry_count_after"], 20)
        self.assertEqual(investigations["archived"], 1)

        loop_result = run(["bash", str(VIDUX_LOOP), str(self.root / "PLAN.md")])
        self.assertEqual(loop_result.returncode, 0, loop_result.stderr + loop_result.stdout)
        loop_payload = json.loads(loop_result.stdout)
        self.assertTrue(loop_payload["is_resuming"])
        self.assertEqual(loop_payload["task"], "Task IP: active fake work [Evidence: fixture] [ETA: 1h]")
        self.assertEqual(loop_payload["action"], "execute")

    @unittest.skipUnless(shutil.which("jq"), "jq is required for ledger GC scripts")
    @unittest.skipUnless(
        LEDGER_CLASSIFY.exists() and LEDGER_GC.exists(),
        "local ledger skill is not installed",
    )
    def test_ledger_gc_classifies_fake_project_worktrees_safely(self):
        fake_home = self.root / "home"
        ledger_dir = fake_home / ".agent-ledger"
        ledger_dir.mkdir(parents=True)

        active_path = str(self.root / "fake-projects" / "active" / "repo")
        stale_path = str(self.root / "fake-projects" / "stale" / "repo")
        unpushed_path = str(self.root / "fake-projects" / "unpushed" / "repo")
        unknown_path = str(self.root / "fake-projects" / "unknown" / "repo")

        ledger_dir.joinpath("activity.jsonl").write_text(
            json.dumps(
                {
                    "ts": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
                    "eid": "evt_fake_active",
                    "agent_id": "codex/fake",
                    "repo": "fake-projects",
                    "event": "live",
                    "summary": "active fake project",
                    "files": [],
                    "worktree": active_path,
                    "worktree_branch": "codex/fake-active",
                }
            )
            + "\n"
        )

        discovery = [
            {
                "path": active_path,
                "repo": "fake-projects",
                "source": "codex",
                "branch": "",
                "commit": "11111111",
                "age_hours": 12,
                "is_detached": True,
                "has_unpushed": False,
                "is_prunable": False,
                "disk_mb": 5,
            },
            {
                "path": stale_path,
                "repo": "fake-projects",
                "source": "codex",
                "branch": "",
                "commit": "22222222",
                "age_hours": 12,
                "is_detached": True,
                "has_unpushed": False,
                "is_prunable": False,
                "disk_mb": 7,
            },
            {
                "path": unpushed_path,
                "repo": "fake-projects",
                "source": "codex",
                "branch": "codex/unpushed",
                "commit": "33333333",
                "age_hours": 120,
                "is_detached": False,
                "has_unpushed": True,
                "is_prunable": False,
                "disk_mb": 9,
            },
            {
                "path": unknown_path,
                "repo": "fake-projects",
                "source": "unknown",
                "branch": "feature/manual",
                "commit": "44444444",
                "age_hours": 200,
                "is_detached": False,
                "has_unpushed": False,
                "is_prunable": False,
                "disk_mb": 11,
            },
        ]
        env = os.environ.copy()
        env["HOME"] = str(fake_home)

        classified_result = run(
            ["bash", str(LEDGER_CLASSIFY)],
            input_text=json.dumps(discovery),
            env=env,
        )
        self.assertEqual(classified_result.returncode, 0, classified_result.stderr)
        classified = json.loads(classified_result.stdout)
        by_path = {row["path"]: row for row in classified["worktrees"]}

        self.assertEqual(by_path[active_path]["classification"]["action"], "skip")
        self.assertIn("recent ledger activity", by_path[active_path]["classification"]["reason"])
        self.assertEqual(by_path[stale_path]["classification"]["action"], "reap")
        self.assertEqual(by_path[stale_path]["classification"]["tier"], "T1")
        self.assertEqual(by_path[unpushed_path]["classification"]["action"], "skip")
        self.assertIn("unpushed commits", by_path[unpushed_path]["classification"]["reason"])
        self.assertEqual(by_path[unknown_path]["classification"]["action"], "skip")
        self.assertEqual(classified["reap_candidates"], 1)

        gc_result = run(
            ["bash", str(LEDGER_GC), "--dry-run"],
            input_text=json.dumps(classified),
            env=env,
        )
        self.assertEqual(gc_result.returncode, 0, gc_result.stderr + gc_result.stdout)
        self.assertIn("would reap", gc_result.stdout)
        self.assertNotIn("gc_reap", (ledger_dir / "activity.jsonl").read_text())


if __name__ == "__main__":
    unittest.main()
