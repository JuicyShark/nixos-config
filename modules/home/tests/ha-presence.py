#!/usr/bin/env python3

import importlib.util
import json
from pathlib import Path
import sys
import tempfile
import unittest


MODULE_PATH = Path(sys.argv.pop(1))
SPEC = importlib.util.spec_from_file_location("ha_presence", MODULE_PATH)
assert SPEC and SPEC.loader
ha_presence = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(ha_presence)


class PresenceTests(unittest.TestCase):
    def setUp(self):
        self.engine = ha_presence.StateEngine(
            priority=["locked", "remote-streaming", "streaming", "screen-recording", "gaming"],
            stability_seconds=30,
            gaming_seconds=600,
        )

    @staticmethod
    def fact(state, since=0, source="test"):
        return [{"source": source, "state": state, "since": since}]

    def test_gaming_qualification_survives_higher_priority_states(self):
        self.assertIsNone(self.engine.evaluate(self.fact("gaming"), 599)["stable"])
        self.assertEqual(self.engine.evaluate(self.fact("gaming"), 600)["candidate"], "gaming")
        self.assertEqual(self.engine.evaluate(self.fact("gaming"), 630)["stable"], "gaming")

        facts = self.fact("gaming") + self.fact("locked", since=635, source="lock")
        self.assertEqual(self.engine.evaluate(facts, 635)["candidate"], "locked")
        self.assertEqual(self.engine.evaluate(facts, 665)["stable"], "locked")

        # Removing lock returns to already-qualified gaming after only the normal
        # stability window; it does not restart the ten-minute gaming clock.
        self.assertEqual(self.engine.evaluate(self.fact("gaming"), 666)["candidate"], "gaming")
        self.assertEqual(self.engine.evaluate(self.fact("gaming"), 696)["stable"], "gaming")

    def test_every_primary_transition_needs_thirty_seconds(self):
        self.assertIsNone(self.engine.evaluate([], 0)["stable"])
        self.assertIsNone(self.engine.evaluate([], 29.9)["stable"])
        self.assertEqual(self.engine.evaluate([], 30)["stable"], "normal")
        self.assertEqual(self.engine.evaluate(self.fact("streaming", since=31), 31)["stable"], "normal")
        self.assertEqual(self.engine.evaluate(self.fact("streaming", since=31), 61)["stable"], "streaming")

    def test_identical_source_reassertion_preserves_qualification_time(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            ha_presence.set_source(root, "games", "gaming", True, now=10)
            ha_presence.set_source(root, "games", "gaming", True, now=500)
            records = ha_presence.read_sources(root, now=500)
            self.assertEqual(records[0]["since"], 10)
            ha_presence.set_source(root, "games", "gaming", False, now=501)
            self.assertEqual(ha_presence.read_sources(root, now=501), [])

    def test_new_compositor_instance_discards_old_instance_facts(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            ha_presence.set_source(root, "stream", "remote-streaming", True, now=10, instance="old")
            ha_presence.set_source(root, "games", "gaming", True, now=20, instance="new")
            records = ha_presence.read_sources(root, now=20)
            self.assertEqual(records, [{"source": "games", "state": "gaming", "since": 20}])

    def test_engine_restores_candidate_clock_but_requires_redelivery(self):
        first = self.engine.evaluate([], 100)
        restored = ha_presence.StateEngine(
            priority=self.engine.priority,
            stability_seconds=30,
            gaming_seconds=600,
            restored={**first, "delivered": "normal"},
        )
        self.assertEqual(restored.evaluate([], 130)["stable"], "normal")

    def test_failed_delivery_is_retried_before_marking_state_delivered(self):
        class Connection:
            def __init__(self):
                self.outcomes = iter((False, True))
                self.attempts = []

            def publish(self, topic, payload):
                self.attempts.append((topic, payload))
                return next(self.outcomes)

        connection = Connection()
        delivered = ha_presence.deliver_stable(connection, "state/topic", "gaming", None)
        self.assertIsNone(delivered)
        delivered = ha_presence.deliver_stable(connection, "state/topic", "gaming", delivered)
        self.assertEqual(delivered, "gaming")
        self.assertEqual(connection.attempts, [("state/topic", "gaming"), ("state/topic", "gaming")])


if __name__ == "__main__":
    unittest.main()
