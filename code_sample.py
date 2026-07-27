#!/usr/bin/env python3
"""Hand-code the validation sample, one post at a time.

    python3 code_sample.py              # code everything still unlabelled
    python3 code_sample.py --marker ought    # ought items only (these gate H2a)
    python3 code_sample.py --status          # how far along you are

Shows you the marker and the evidence, and nothing else. What the dictionary decided
(`flagged`) and the machine pass (`machine_label`) are deliberately withheld: seeing
either turns an independent rating into an agreement exercise, which is the one thing
that would make your coding worthless.

Saves after every single answer, so quitting and resuming loses nothing.
"""
import argparse, csv, os, shutil, sys, textwrap

CSV = os.path.join(os.path.dirname(os.path.abspath(__file__)), "out", "validation_sample.csv")

RULES = {
    "ought": """Does the writer express an obligation or requirement THEY FEEL BOUND BY,
about THEMSELVES?

  1  = yes. "i have to keep going", "i should be over this by now",
       "i need to get my life together"
  0  = no. Advice to someone else ("you should see a doctor"), a filler
       ("i have to say", "all i have to ask"), a hypothetical, a quotation of
       someone else, or a plain question ("what should i do?")""",
    "selfcrit": """Does the writer negatively evaluate THEMSELVES AS A PERSON?

  1  = yes. "i'm a failure", "i hate myself", "i'm such a burden", "stupid me"
  0  = no. Criticising a situation ("i hate my job"), another person, or a
       symptom/state ("i feel hopeless", "i hate this feeling"), or quoting an
       insult someone else threw at them without endorsing it""",
}


def load():
    if not os.path.exists(CSV):
        sys.exit("No validation sample found. Run:  Rscript 05_validate.R")
    with open(CSV, newline="", encoding="utf-8") as f:
        rows = list(csv.DictReader(f))
    if "true_label" not in rows[0]:
        sys.exit("validation_sample.csv has no true_label column; regenerate it.")
    return rows


def save(rows):
    """Write via a temp file then rename, so an interrupt cannot truncate the real one."""
    tmp = CSV + ".tmp"
    with open(tmp, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        w.writeheader()
        w.writerows(rows)
    shutil.move(tmp, CSV)


def done(r):
    return str(r.get("true_label", "")).strip() not in ("", "NA")


def status(rows):
    for mk in sorted({r["marker"] for r in rows}):
        sub = [r for r in rows if r["marker"] == mk]
        n = sum(done(r) for r in sub)
        bar = "#" * round(20 * n / len(sub)) + "." * (20 - round(20 * n / len(sub)))
        print(f"  {mk:9s} [{bar}] {n}/{len(sub)}")
    total = sum(done(r) for r in rows)
    print(f"  {'TOTAL':9s} {total}/{len(rows)}")
    if total == len(rows):
        print("\nAll coded. Score it with:\n  Rscript 05_validate.R --score")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--marker", choices=["ought", "selfcrit"], help="code one marker only")
    ap.add_argument("--status", action="store_true", help="show progress and exit")
    # Batch mode, for coding through a chat client instead of a terminal. --next prints
    # the next N unlabelled items; --record applies N answers to that same set. Both walk
    # the file in fixed order and neither writes anything in between, so the two calls
    # always refer to the same rows.
    ap.add_argument("--next", type=int, metavar="N", help="print next N unlabelled items")
    ap.add_argument("--record", metavar="ANSWERS", help="comma/space separated 1s and 0s")
    a = ap.parse_args()

    rows = load()
    if a.status:
        status(rows)
        return

    if a.next or a.record:
        pend = [i for i, r in enumerate(rows)
                if not done(r) and (a.marker is None or r["marker"] == a.marker)]
        if not pend:
            print("Nothing left to code for that marker.")
            status(rows)
            return
        if a.record:
            # "-" is accepted as a synonym for 0, because that is how it gets typed.
            ans = [x.replace("-", "0") for x in a.record.replace(",", " ").split() if x != ""]
            if any(x not in ("0", "1") for x in ans):
                sys.exit(f"Answers must be 0 or 1. Got: {ans}")
            if len(ans) > len(pend):
                sys.exit(f"Got {len(ans)} answers but only {len(pend)} items left.")
            for x, i in zip(ans, pend):
                rows[i]["true_label"] = x
            save(rows)
            print(f"Recorded {len(ans)} answers.\n")
            status(rows)
            return
        w = 88
        for k, i in enumerate(pend[: a.next], 1):
            txt = " ".join(rows[i]["evidence"].split())
            print(f"\n{k}. [{rows[i]['marker']}]")
            print(textwrap.fill(txt, width=w, initial_indent="   ", subsequent_indent="   "))
        left = len(pend)
        print(f"\n({min(a.next, left)} shown, {left} unlabelled remaining for this marker)")
        return

    todo = [i for i, r in enumerate(rows)
            if not done(r) and (a.marker is None or r["marker"] == a.marker)]
    if not todo:
        print("Nothing left to code.\n")
        status(rows)
        return

    width = min(shutil.get_terminal_size((90, 24)).columns, 90)
    print("\n" + "=" * width)
    print("Coding the validation sample. 1 = yes, 0 = no, s = skip, b = back, q = quit.")
    print("Ambiguous? Pick the reading a stranger would pick and move on. Consistency")
    print("matters more than agonising over any single row.")
    print("\nThese are real posts from people in distress, including suicidal ideation.")
    print("Take a break whenever you need one. Your progress is saved after every answer.")
    print("=" * width)

    pos = 0
    while 0 <= pos < len(todo):
        i = todo[pos]
        r = rows[i]
        remaining = sum(1 for j in todo if not done(rows[j]))
        print("\n" + "-" * width)
        print(f"[{len(todo) - remaining + 1}/{len(todo)}]  marker: {r['marker']}")
        print("-" * width)
        print(RULES[r["marker"]])
        print("\nPOST:\n")
        for para in r["evidence"].split("\n"):
            print(textwrap.fill(para.strip(), width=width - 4,
                                initial_indent="    ", subsequent_indent="    ") or "")
        print()

        while True:
            try:
                ans = input("  1 / 0 / s / b / q > ").strip().lower()
            except (EOFError, KeyboardInterrupt):
                print("\n\nStopped. Progress saved.")
                status(rows)
                return
            if ans in ("1", "0"):
                r["true_label"] = ans
                save(rows)
                pos += 1
                break
            if ans == "s":
                pos += 1
                break
            if ans == "b":
                pos = max(0, pos - 1)
                break
            if ans == "q":
                print("\nStopped. Progress saved.\n")
                status(rows)
                return
            print("  Enter 1, 0, s (skip), b (back), or q (quit).")

    print("\nDone with this pass.\n")
    status(rows)


if __name__ == "__main__":
    main()
