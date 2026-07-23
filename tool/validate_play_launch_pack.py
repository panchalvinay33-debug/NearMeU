#!/usr/bin/env python3

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def fail(message: str) -> None:
    print(f"Play launch pack validation failed: {message}", file=sys.stderr)
    raise SystemExit(1)


def read(relative: str) -> str:
    path = ROOT / relative
    if not path.is_file():
        fail(f"missing required file: {relative}")
    return path.read_text(encoding="utf-8")


def require_all(content: str, markers: list[str], label: str) -> None:
    missing = [marker for marker in markers if marker not in content]
    if missing:
        fail(f"{label} is missing: {', '.join(missing)}")


def extract_backtick_after_heading(content: str, heading_prefix: str) -> str:
    pattern = rf"{re.escape(heading_prefix)}[^\n]*\n\n`([^`]+)`"
    match = re.search(pattern, content)
    if not match:
        fail(f"could not extract value after heading: {heading_prefix}")
    return match.group(1).strip()


def extract_section(content: str, start: str, end: str) -> str:
    start_index = content.find(start)
    end_index = content.find(end, start_index + len(start))
    if start_index < 0 or end_index < 0:
        fail(f"could not extract section between {start!r} and {end!r}")
    return content[start_index + len(start) : end_index].strip()


def main() -> None:
    required = [
        "legal-site/index.html",
        "legal-site/privacy.html",
        "legal-site/account-deletion.html",
        "legal-site/styles.css",
        ".github/workflows/publish-legal-site.yml",
        "docs/PLAY_DATA_SAFETY_INVENTORY.md",
        "docs/PLAY_STORE_LISTING.md",
        "docs/PLAY_INTERNAL_TEST_PLAN.md",
        "functions/deletion_cleanup_logic.js",
        "functions/deletion_cleanup_logic.test.js",
        "functions/deletion_cleanup_functions.js",
    ]
    for relative in required:
        read(relative)

    listing = read("docs/PLAY_STORE_LISTING.md")
    short_description = extract_backtick_after_heading(
        listing, "### Short description —"
    )
    if len(short_description) > 80:
        fail(f"English short description is {len(short_description)} characters")

    full_description = extract_section(
        listing,
        "### Full description",
        "## Product details — Hindi",
    )
    if len(full_description) > 4000:
        fail(f"English full description is {len(full_description)} characters")
    require_all(
        full_description,
        ["18", "exact coordinates", "block or report", "delete your account"],
        "English full description",
    )

    privacy = read("legal-site/privacy.html")
    require_all(
        privacy,
        [
            "{{SUPPORT_EMAIL}}",
            "18 years or older",
            "Exact coordinates",
            "private messages",
            "Firebase Crashlytics",
            "Data retention and deletion",
            "other participant's conversation",
            "does not sell personal information",
        ],
        "privacy policy",
    )

    deletion = read("legal-site/account-deletion.html")
    require_all(
        deletion,
        [
            "{{SUPPORT_EMAIL}}",
            "Settings → Delete Account",
            "Email an account deletion request",
            "Firebase Authentication account",
            "profile photo",
            "other participant",
        ],
        "account deletion page",
    )

    for relative in [
        "legal-site/index.html",
        "legal-site/privacy.html",
        "legal-site/account-deletion.html",
    ]:
        content = read(relative)
        if "example.com" in content.lower():
            fail(f"fake example contact address found in {relative}")

    pages_workflow = read(".github/workflows/publish-legal-site.yml")
    require_all(
        pages_workflow,
        [
            "workflow_dispatch:",
            "NEARMEU_SUPPORT_EMAIL",
            "actions/configure-pages@v5",
            "actions/upload-pages-artifact@v3",
            "actions/deploy-pages@v4",
            "refs/heads/main",
        ],
        "GitHub Pages workflow",
    )

    data_safety = read("docs/PLAY_DATA_SAFETY_INVENTORY.md")
    require_all(
        data_safety,
        [
            "Approximate location",
            "Precise location",
            "Sexual orientation",
            "Other in-app messages",
            "Crash logs",
            "Diagnostics",
            "Device or other IDs",
            "Does the app sell user data?** No",
        ],
        "Data Safety inventory",
    )

    test_plan = read("docs/PLAY_INTERNAL_TEST_PLAN.md")
    require_all(
        test_plan,
        [
            "Play-installed build",
            "Play Integrity App Check",
            "Post-deletion privacy",
            "External deletion page",
            "Telemetry inspection",
            "Exit criteria",
        ],
        "internal test plan",
    )

    bootstrap = read("functions/bootstrap.js")
    if './deletion_cleanup_functions.js' not in bootstrap:
        fail("secure Functions bootstrap does not export deletion cleanup trigger")

    cleanup = read("functions/deletion_cleanup_functions.js")
    require_all(
        cleanup,
        [
            'document: "users/{uid}"',
            'collection("antiAbuseUsers")',
            'collection("reportLocks")',
            'collection("moderationAuditLogs")',
            "deleteProfilePhoto",
            "retry: true",
        ],
        "deleted-user cleanup trigger",
    )

    print(
        "Play launch pack validated: "
        f"short={len(short_description)}/80, full={len(full_description)}/4000."
    )


if __name__ == "__main__":
    main()
