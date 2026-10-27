import json
import unittest

from handler import handler, summarise


class SummariseTests(unittest.TestCase):
    def test_plain_text(self):
        self.assertTrue(summarise("hello").startswith("TEXT message"))

    def test_cloudwatch_alarm(self):
        msg = json.dumps({
            "AlarmName": "shipit-dev-unhealthy-hosts",
            "OldStateValue": "OK",
            "NewStateValue": "ALARM",
            "NewStateReason": "Threshold crossed",
        })
        line = summarise(msg)
        self.assertIn("shipit-dev-unhealthy-hosts", line)
        self.assertIn("OK -> ALARM", line)

    def test_handler_counts_records(self):
        event = {"Records": [{"Sns": {"Message": "one"}}, {"Sns": {"Message": "two"}}]}
        self.assertEqual(handler(event, None), {"processed": 2})


if __name__ == "__main__":
    unittest.main()
