#!/usr/bin/env python3
"""Extract [Category("VisualVerification")] test results from TestResults.xml.

TestResults.xml under Application.persistentDataPath is written by the
com.unity.test-framework.performance package (Editor.RunFinished), not by
Unity Test Framework itself — UTF only writes a result XML in CLI/batchmode
runs, to <project-root>/TestResults-<ticks>.xml. So when the performance
package is not installed, this script finds nothing; fall back to Editor.log
(see run-tests/SKILL.md -> Visual Verification).

Uses ElementTree rather than awk/grep because a class-scoped [Category] is
recorded on the ancestor <test-suite type="TestFixture"> element (not on the
<test-case> itself), a single test can record multiple "Screenshot"
properties, and property values are XML-entity-escaped.
"""

import subprocess
import sys
import xml.etree.ElementTree as ElementTree
from datetime import datetime, timezone
from pathlib import Path

EXIT_USAGE = 2
EXIT_ERROR = 1
EXIT_NO_RESULTS_XML = 3

CATEGORY = "VisualVerification"


def usage_error(message):
    print(f"Usage: {Path(sys.argv[0]).name} <unity-project-root> [test-results-xml]", file=sys.stderr)
    print("  <unity-project-root> is only read when [test-results-xml] is omitted", file=sys.stderr)
    print("  (it is passed to get-persistent-data-path.sh to locate the default file).", file=sys.stderr)
    print(f"Error: {message}", file=sys.stderr)
    sys.exit(EXIT_USAGE)


def resolve_results_xml(project_root):
    script_dir = Path(__file__).resolve().parent
    helper = script_dir / "get-persistent-data-path.sh"
    try:
        result = subprocess.run(
            ["bash", str(helper), project_root],
            capture_output=True, text=True, check=True,
        )
    except subprocess.CalledProcessError as e:
        print(f"Error: {helper.name} failed: {e.stderr.strip()}", file=sys.stderr)
        sys.exit(EXIT_ERROR)

    persistent_data_path = result.stdout.strip()
    return Path(persistent_data_path) / "TestResults.xml"


def properties_of(element):
    """Return {name: [values]} from a direct child <properties> element, or {}.

    A list because a single test can add the same property name more than
    once (e.g. one "Screenshot" entry per TakeScreenshotAsync() call)."""
    properties_element = element.find("properties")
    if properties_element is None:
        return {}
    values = {}
    for prop in properties_element.findall("property"):
        name = prop.get("name")
        values.setdefault(name, []).append(prop.get("value"))
    return values


def categories_including_ancestors(test_case, ancestors):
    """Categories on the test-case itself plus every ancestor <test-suite>
    (a class-scoped [Category] is recorded on the TestFixture suite, not on
    each test-case)."""
    names = set()
    for element in [test_case, *ancestors]:
        names.update(properties_of(element).get("Category", []))
    return names


def format_age(start_time_text, now):
    try:
        start = datetime.strptime(start_time_text, "%Y-%m-%d %H:%M:%SZ").replace(tzinfo=timezone.utc)
    except (TypeError, ValueError):
        return ""
    age_seconds = int((now - start).total_seconds())
    if age_seconds < 0:
        return " (clock skew — run start-time is in the future)"
    return f" — {age_seconds} seconds ago"


def walk_test_cases(element, ancestors):
    """Yield (test_case_element, ancestor_suites) for every <test-case> under element."""
    for child in element:
        if child.tag == "test-case":
            yield child, list(ancestors)
        elif child.tag == "test-suite":
            yield from walk_test_cases(child, [*ancestors, child])


def main():
    if len(sys.argv) not in (2, 3):
        usage_error("expected 1 or 2 arguments")

    project_root = sys.argv[1]
    if len(sys.argv) == 3:
        results_xml = Path(sys.argv[2])
    else:
        results_xml = resolve_results_xml(project_root)

    if not results_xml.is_file():
        print(f"Error: no TestResults.xml found at {results_xml}", file=sys.stderr)
        print(
            "This file is written by the com.unity.test-framework.performance package, "
            "not by Unity Test Framework itself. If that package is not installed in this "
            "project, fall back to Editor.log (see run-tests SKILL.md -> Visual Verification).",
            file=sys.stderr,
        )
        sys.exit(EXIT_NO_RESULTS_XML)

    try:
        tree = ElementTree.parse(results_xml)
    except ElementTree.ParseError as e:
        print(f"Error: failed to parse {results_xml}: {e}", file=sys.stderr)
        sys.exit(EXIT_ERROR)

    root = tree.getroot()

    age_text = format_age(root.get("start-time"), datetime.now(timezone.utc))
    print(f"Source: {results_xml} (run started {root.get('start-time')}{age_text})")

    all_test_cases = list(walk_test_cases(root, []))
    all_names = ", ".join(test_case.get("fullname") for test_case, _ in all_test_cases)
    print(f"All {len(all_test_cases)} test(s) in this result file: {all_names}")
    print("(cross-check this list against the tests you just ran — if it names tests you")
    print(" didn't run, or omits ones you did, this file is from an earlier run, regardless")
    print(" of the age above; TestResults.xml is overwritten each run, not appended.)")
    print()

    matches = [
        (test_case, ancestors)
        for test_case, ancestors in all_test_cases
        if CATEGORY in categories_including_ancestors(test_case, ancestors)
    ]

    if not matches:
        print(f'0 tests with [Category("{CATEGORY}")] found in this result file.')
        sys.exit(0)

    screenshot_count = 0
    for test_case, ancestors in matches:
        props = properties_of(test_case)
        description = props.get("Description", ["(none)"])[0]
        screenshots = props.get("Screenshot", [])
        result = test_case.get("result")

        print(f"{test_case.get('fullname')} [{result}]")
        print(f"  Description: {description}")
        if result != "Passed":
            print("  Note: test did not pass — do not analyze; the screenshot may be stale, partial, or absent.")
        if screenshots:
            for screenshot in screenshots:
                print(f"  Screenshot: {screenshot}")
                screenshot_count += 1
        else:
            print("  Screenshot: (none — not captured)")
        print()

    plural_test = "test" if len(matches) == 1 else "tests"
    plural_shot = "screenshot" if screenshot_count == 1 else "screenshots"
    print(f"{len(matches)} visual verification {plural_test}, {screenshot_count} {plural_shot}")


if __name__ == "__main__":
    main()
