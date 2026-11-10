#!/usr/bin/env python3
"""Run the test-designing-guide skill on a fixture across model x effort, judge each run against golden.md, report.

  python3 run.py fsm-card-draw --model opus --effort high --runs 3
  python3 run.py fsm-card-draw --model opus --effort xhigh --runs 1 --draft-golden   # golden candidate -> draft-golden.md
  python3 run.py fsm-card-draw --report-only
  python3 run.py --report-only                                    # every fixture, for RESULTS.md
"""
import argparse, itertools, json, re, shutil, subprocess, sys, tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
PLUGIN_DIR = HERE.parent.parent
JUDGE_SCHEMA = json.dumps({"type": "object", "properties": {"items": {"type": "array", "items": {
    "type": "object", "properties": {"id": {"type": "integer"}, "present": {"type": "boolean"}, "evidence": {"type": "string"}},
    "required": ["id", "present", "evidence"]}}}, "required": ["items"]})


def claude(prompt, *args, cwd=None):
    # --setting-sources project: the user's ~/.claude/CLAUDE.md (tone, language) would otherwise shape every run and judge; a temp cwd has no project settings, so nothing else loads
    out = subprocess.run(["claude", "-p", "--output-format", "json", "--setting-sources", "project", *args, prompt], cwd=cwd, stdin=subprocess.DEVNULL, capture_output=True, text=True)
    if out.returncode != 0:
        sys.exit(f"claude failed:\n{out.stderr}\n{out.stdout[-2000:]}")
    return json.loads(out.stdout)


def parse_golden(path):
    """## must / ## must_not / ## regex sections, one `- ` bullet per item."""
    sections, current = {"must": [], "must_not": [], "regex": []}, None
    for line in path.read_text().splitlines():
        if line.startswith("## "):
            current = line[3:].strip()
        elif line.startswith("- ") and current in sections:
            sections[current].append(line[2:].strip().strip("`"))
    return sections


def run_once(fixture_dir, model, effort, out_md):
    with tempfile.TemporaryDirectory() as work:
        # golden.md, draft-golden.md and prompt.md stay out of the workspace: the agent must not see the checklist
        # instruction.md goes into the prompt, not the workspace: an instruction is what the user says, not a document a subagent may come across
        shutil.copytree(fixture_dir, work, dirs_exist_ok=True,
                        ignore=shutil.ignore_patterns("golden.md", "draft-golden.md", "instruction.md", "prompt.md"))
        prompt = fixture_dir / "prompt.md" if (fixture_dir / "prompt.md").exists() else HERE / "prompt.md"
        instruction = fixture_dir / "instruction.md"
        text = prompt.read_text().replace("{instruction}", instruction.read_text().strip() if instruction.exists() else "none")
        res = claude(text, "--model", model, "--effort", effort,
                     "--plugin-dir", str(PLUGIN_DIR), "--allowedTools", "Read,Glob,Grep,Skill,Agent",
                     "--permission-mode", "manual", cwd=work)
    out_md.write_text(res["result"])
    out_md.with_suffix(".json").write_text(json.dumps(
        {k: res.get(k) for k in ("total_cost_usd", "duration_ms", "num_turns", "is_error", "permission_denials", "session_id")}, indent=2))


def judge(golden, output, judge_model, votes):
    items = golden["must"] + golden["must_not"]
    listing = "\n".join(f"{i + 1}. {text}" for i, text in enumerate(items))
    prompt = (HERE / "judge.md").read_text().format(items=listing, output=output)
    tally = [0] * len(items)
    evidence = [""] * len(items)
    with tempfile.TemporaryDirectory() as work:
        votes_out = [claude(prompt, "--model", judge_model, "--json-schema", JUDGE_SCHEMA, cwd=work) for _ in range(votes)]
    for res in votes_out:
        for item in res["structured_output"]["items"]:
            i = item["id"] - 1
            if 0 <= i < len(items) and item["present"]:
                tally[i] += 1
                evidence[i] = item["evidence"]
    n_must = len(golden["must"])
    present = [t * 2 > votes for t in tally]
    return {
        "must": [{"text": items[i], "present": present[i], "evidence": evidence[i]} for i in range(n_must)],
        "must_not": [{"text": items[i], "present": present[i], "evidence": evidence[i]} for i in range(n_must, len(items))],
        "regex": [{"pattern": p, "matched": bool(re.search(p, output, re.I | re.S))} for p in golden["regex"]],
    }


def draft_golden(fixture_dir, run_md, model):
    """Write draft-golden.md from one run; the user reviews it and renames it to golden.md."""
    prompt = (HERE / "prompt-draft-golden.md").read_text().format(
        name=fixture_dir.name, spec=(fixture_dir / "spec.md").read_text(), output=run_md.read_text())
    with tempfile.TemporaryDirectory() as work:
        text = claude(prompt, "--model", model, cwd=work)["result"]
    text = re.sub(r"^```[a-z]*\n|\n```\s*$", "", text.strip())
    out = fixture_dir / "draft-golden.md"
    out.write_text(text + "\n")
    print(f"drafted {out} from {run_md}", file=sys.stderr)


def jaccard(a, b):
    return 1.0 if not a and not b else len(a & b) / len(a | b)


def report(fixture_dirs):
    """Markdown table of every judged configuration, one row per fixture x config, then the misses per run."""
    rows, cfgs = [], []
    for results_dir in fixture_dirs:
        cfgs += sorted(p for p in results_dir.iterdir() if p.is_dir())
    for cfg in cfgs:
        judged = sorted(cfg.glob("judge-*.json"))
        if not judged:
            continue
        runs = [json.loads(p.read_text()) for p in judged]
        metas = [json.loads(p.with_name(p.name.replace("judge-", "run-")).read_text()) for p in judged]
        hit_sets = [{m["text"] for m in r["must"] if m["present"]} for r in runs]
        recall = sum(len(s) for s in hit_sets) / (len(runs) * len(runs[0]["must"]) or 1)
        forbidden = sum(m["present"] for r in runs for m in r["must_not"])
        regex_ok = sum(x["matched"] for r in runs for x in r["regex"]) / (len(runs) * len(runs[0]["regex"]) or 1)
        pairs = list(itertools.combinations(hit_sets, 2))
        stability = sum(jaccard(a, b) for a, b in pairs) / len(pairs) if pairs else float("nan")
        cost = sum(m["total_cost_usd"] for m in metas) / len(metas)
        secs = sum(m["duration_ms"] for m in metas) / len(metas) / 1000
        rows.append((cfg.parent.name, cfg.name, len(runs), recall, forbidden, regex_ok, stability, cost, secs))
    print("| fixture | config | runs | recall | forbidden hits | regex | stability (Jaccard) | $/run | s/run |")
    print("|---|---|---|---|---|---|---|---|---|")
    for r in rows:
        stability = "—" if r[6] != r[6] else f"{r[6]:.2f}"
        print(f"| {r[0]} | {r[1]} | {r[2]} | {r[3]:.2f} | {r[4]} | {r[5]:.2f} | {stability} | {r[7]:.2f} | {r[8]:.0f} |")
    for cfg in cfgs:
        for p in sorted(cfg.glob("judge-*.json")):
            r = json.loads(p.read_text())
            missed = [m["text"] for m in r["must"] if not m["present"]]
            hits = [m["text"] for m in r["must_not"] if m["present"]]
            unmatched = [x["pattern"] for x in r["regex"] if not x["matched"]]
            if missed or hits or unmatched:
                print(f"\n{cfg.parent.name}/{cfg.name}/{p.stem}:")
                for t in missed: print(f"  missed: {t}")
                for t in hits: print(f"  FORBIDDEN: {t}")
                for t in unmatched: print(f"  regex unmatched: {t}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("fixture", nargs="?", help="omit with --report-only to report every fixture")
    ap.add_argument("--model", default="opus")
    ap.add_argument("--effort", default="high", choices=["low", "medium", "high", "xhigh", "max"])
    ap.add_argument("--runs", type=int, default=3)
    ap.add_argument("--judge-model", default="sonnet")
    ap.add_argument("--votes", type=int, default=3)
    ap.add_argument("--no-judge", action="store_true", help="run only")
    ap.add_argument("--draft-golden", action="store_true",
                    help="run, then write fixtures/<name>/draft-golden.md from the newest run; no judging. --runs 0 drafts from an existing run")
    ap.add_argument("--judge-only", action="store_true", help="re-judge existing runs, e.g., after editing golden.md")
    ap.add_argument("--report-only", action="store_true")
    a = ap.parse_args()

    if a.fixture is None:
        if not a.report_only:
            ap.error("fixture is required unless --report-only")
        report(sorted(p for p in (HERE / "results").iterdir() if p.is_dir()))
        return
    fixture_dir = HERE / "fixtures" / a.fixture
    results_dir = HERE / "results" / a.fixture
    cfg_dir = results_dir / f"{a.model}-{a.effort}"
    if not a.report_only:
        cfg_dir.mkdir(parents=True, exist_ok=True)
        if not a.judge_only:
            start = len(list(cfg_dir.glob("run-*.md")))
            for n in range(start, start + a.runs):
                print(f"run {n} ({a.model}-{a.effort})", file=sys.stderr)
                run_once(fixture_dir, a.model, a.effort, cfg_dir / f"run-{n}.md")
        if a.draft_golden:
            draft_golden(fixture_dir, sorted(cfg_dir.glob("run-*.md"))[-1], a.model)
            return
        if not a.no_judge:
            golden = parse_golden(fixture_dir / "golden.md")
            for md in sorted(cfg_dir.glob("run-*.md")):
                print(f"judge {md.stem}", file=sys.stderr)
                md.with_name(md.name.replace("run-", "judge-")).with_suffix(".json").write_text(
                    json.dumps(judge(golden, md.read_text(), a.judge_model, a.votes), ensure_ascii=False, indent=2))
    report([results_dir])


def _selfcheck():
    assert jaccard({1, 2}, {2, 3}) == 1 / 3 and jaccard(set(), set()) == 1.0
    g = parse_golden(HERE / "fixtures" / "fsm-card-draw" / "golden.md")
    assert g["must"] and g["must_not"] and g["regex"] and all(not t.startswith("-") for t in g["must"])


if __name__ == "__main__":
    _selfcheck()
    main()
