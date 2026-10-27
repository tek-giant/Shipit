#!/usr/bin/env python3
"""Report on the images in an ECR repository: tags, size, age and scan results.

Exit codes: 0 = all images scanned and clean, 1 = an image has CRITICAL or HIGH findings,
            2 = could not check (AWS error, or an image has no completed scan).
"""
import argparse
import os
import sys
from datetime import datetime, timezone

import boto3
from botocore.exceptions import BotoCoreError, ClientError

BLOCKING_SEVERITIES = ("CRITICAL", "HIGH")


def classify(tags):
    """Release tags have no hyphen (0.1.2); pipeline build tags do (abc1234-12)."""
    if not tags:
        return "untagged"
    if any("-" not in tag for tag in tags):
        return "release"
    return "build"


def summarise_image(detail, scan, now=None):
    now = now or datetime.now(timezone.utc)
    tags = sorted(detail.get("imageTags", []))
    return {
        "kind": classify(tags),
        "tags": ",".join(tags) if tags else "<untagged>",
        "size_mb": round(detail.get("imageSizeInBytes", 0) / 1_000_000, 1),
        "age_days": (now - detail["imagePushedAt"]).days,
        "scan": scan["status"],
        "findings": scan["counts"],
    }


def scan_is_known(summary):
    return summary["scan"] == "COMPLETE"


def has_blocking_findings(summary):
    return scan_is_known(summary) and any(
        summary["findings"].get(sev, 0) > 0 for sev in BLOCKING_SEVERITIES
    )


def findings_text(summary):
    if not scan_is_known(summary):
        return f"unknown ({summary['scan']})"
    if not summary["findings"]:
        return "none"
    return ", ".join(f"{sev}={n}" for sev, n in sorted(summary["findings"].items()))


def exit_code(summaries):
    if any(has_blocking_findings(s) for s in summaries):
        return 1
    if any(not scan_is_known(s) for s in summaries):
        return 2
    return 0


def format_report(summaries):
    rows = sorted(summaries, key=lambda s: s["age_days"])
    header = f"{'KIND':<9} {'TAGS':<32} {'MB':>7} {'AGE(d)':>7}  {'SCAN':<11} FINDINGS"
    lines = [header, "-" * len(header)]
    for s in rows:
        if has_blocking_findings(s):
            flag = "  <-- needs attention"
        elif not scan_is_known(s):
            flag = "  <-- scan result unavailable"
        else:
            flag = ""
        lines.append(
            f"{s['kind']:<9} {s['tags']:<32} {s['size_mb']:>7} {s['age_days']:>7}  "
            f"{s['scan']:<11} {findings_text(s)}{flag}"
        )
    return "\n".join(lines)


def fetch_images(ecr, repository):
    for page in ecr.get_paginator("describe_images").paginate(repositoryName=repository):
        yield from page["imageDetails"]


def fetch_scan(ecr, repository, digest):
    """Ask ECR for the scan result of one image. A missing scan is reported, not hidden."""
    try:
        resp = ecr.describe_image_scan_findings(
            repositoryName=repository, imageId={"imageDigest": digest}
        )
    except ecr.exceptions.ScanNotFoundException:
        return {"status": "NONE", "counts": {}}
    return {
        "status": resp.get("imageScanStatus", {}).get("status", "NONE"),
        "counts": resp.get("imageScanFindings", {}).get("findingSeverityCounts", {}),
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repository", default="shipit/orders-api")
    parser.add_argument("--profile", default=os.environ.get("AWS_PROFILE", "shipit"))
    parser.add_argument("--region", default=os.environ.get("AWS_REGION", "eu-west-2"))
    args = parser.parse_args()

    try:
        session = boto3.Session(profile_name=args.profile, region_name=args.region)
        ecr = session.client("ecr")
        summaries = []
        for detail in fetch_images(ecr, args.repository):
            scan = fetch_scan(ecr, args.repository, detail["imageDigest"])
            summaries.append(summarise_image(detail, scan))
    except (BotoCoreError, ClientError) as err:
        print(f"ERROR: could not read {args.repository}: {err}", file=sys.stderr)
        print(f"Try: aws sso login --profile {args.profile}", file=sys.stderr)
        return 2

    print(format_report(summaries))
    print()
    code = exit_code(summaries)
    if code == 1:
        bad = [s["tags"] for s in summaries if has_blocking_findings(s)]
        print(f"RESULT: {len(bad)} image(s) with CRITICAL/HIGH findings: {'; '.join(bad)}")
    elif code == 2:
        unknown = [s["tags"] for s in summaries if not scan_is_known(s)]
        print(f"RESULT: no completed scan for: {'; '.join(unknown)} (cannot confirm they are clean)")
    else:
        print(f"RESULT: {len(summaries)} image(s), all scanned, none with CRITICAL/HIGH findings")
    return code


if __name__ == "__main__":
    sys.exit(main())
