import unittest
from datetime import datetime, timedelta, timezone

from ecr_report import (
    classify,
    exit_code,
    format_report,
    has_blocking_findings,
    summarise_image,
)

NOW = datetime(2026, 10, 27, tzinfo=timezone.utc)


def image(tags, days_old, counts=None, status="COMPLETE"):
    detail = {
        "imageSizeInBytes": 88_000_000,
        "imagePushedAt": NOW - timedelta(days=days_old),
    }
    if tags:
        detail["imageTags"] = tags
    return summarise_image(detail, {"status": status, "counts": counts or {}}, NOW)


class ClassifyTests(unittest.TestCase):
    def test_release(self):
        self.assertEqual(classify(["0.1.2"]), "release")

    def test_build(self):
        self.assertEqual(classify(["d331a4e-10", "d331a4e-9"]), "build")

    def test_untagged(self):
        self.assertEqual(classify([]), "untagged")


class FindingsTests(unittest.TestCase):
    def test_critical_blocks(self):
        self.assertTrue(has_blocking_findings(image(["0.1.0"], 5, {"CRITICAL": 1})))

    def test_medium_does_not_block(self):
        self.assertFalse(has_blocking_findings(image(["0.1.1"], 5, {"MEDIUM": 3})))

    def test_report_flags_bad_image(self):
        report = format_report([image(["0.1.0"], 9, {"CRITICAL": 1}), image(["abc1234-5"], 1)])
        self.assertIn("needs attention", report)
        self.assertIn("abc1234-5", report)

    def test_missing_scan_is_not_shown_as_clean(self):
        report = format_report([image(["0.2.0"], 1, status="NONE")])
        self.assertIn("unknown", report)
        self.assertNotIn("none", report)


class ExitCodeTests(unittest.TestCase):
    def test_all_clean_is_zero(self):
        self.assertEqual(exit_code([image(["0.1.2"], 1), image(["a-1"], 1)]), 0)

    def test_critical_is_one(self):
        self.assertEqual(exit_code([image(["0.1.0"], 1, {"CRITICAL": 1})]), 1)

    def test_missing_scan_is_two(self):
        self.assertEqual(exit_code([image(["0.1.2"], 1), image(["0.2.0"], 1, status="NONE")]), 2)

    def test_critical_beats_missing_scan(self):
        summaries = [image(["0.1.0"], 1, {"CRITICAL": 1}), image(["0.2.0"], 1, status="NONE")]
        self.assertEqual(exit_code(summaries), 1)


if __name__ == "__main__":
    unittest.main()
