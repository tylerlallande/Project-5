import concurrent.futures
import tempfile
import unittest
from pathlib import Path
from server import Store, ApiError


class TailgateTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.path = Path(self.temp.name) / 'tailgates.db'
        self.store = Store(self.path)
        self.token = self.store.session()['token']
        self.host = self.store.user(self.token)
        self.guest = self.store.user(self.store.session()['token'])
        self.draft = dict(name='Gumbo & Geaux', game='LSU game day', date='2026-10-24',
                          kickoff='6:30 PM', meetupTime='Noon', location='Oak Grove', vibe='Food', isPublic=True)

    def test_persists_across_server_restart_and_device_reconnect(self):
        event = self.store.create(self.host, self.draft)
        restarted = Store(self.path)
        self.assertEqual(restarted.user(self.token), self.host)
        self.assertEqual(restarted.list(self.host)[0]['id'], event['id'])
        self.assertEqual(restarted.list(self.host)[0]['memberCount'], 1)

    def test_last_member_requires_confirmation_then_event_and_code_are_gone(self):
        event = self.store.create(self.host, self.draft)
        with self.assertRaises(ApiError) as error:
            self.store.leave(self.host, event['id'])
        self.assertEqual(error.exception.code, 'last_member')
        self.assertEqual(self.store.list(self.host)[0]['memberCount'], 1)
        self.assertTrue(self.store.leave(self.host, event['id'], True)['deleted'])
        self.assertEqual(self.store.list(self.host), [])
        with self.assertRaises(ApiError):
            self.store.lookup(self.guest, event['code'])
        with self.assertRaises(ApiError):
            self.store.join(self.guest, event['id'], '')

    def test_private_access_is_enforced_on_server_and_codes_are_not_exposed(self):
        private = self.store.create(self.host, self.draft | {'isPublic': False})
        self.assertEqual(self.store.list(self.guest), [])
        with self.assertRaises(ApiError):
            self.store.join(self.guest, private['id'], 'WRONG1')
        found = self.store.lookup(self.guest, private['code'])
        self.assertFalse(found['joined'])
        self.store.join(self.guest, private['id'], private['code'])
        self.assertTrue(self.store.list(self.guest)[0]['joined'])
        public = self.store.create(self.host, self.draft)
        visible = next(x for x in self.store.list(self.guest) if x['id'] == public['id'])
        self.assertEqual(visible['code'], '')

    def test_join_is_idempotent_and_host_leaving_transfers_ownership(self):
        event = self.store.create(self.host, self.draft)
        self.store.join(self.guest, event['id'], '')
        self.store.join(self.guest, event['id'], '')
        self.assertEqual(self.store.list(self.guest)[0]['memberCount'], 2)
        self.assertFalse(self.store.leave(self.host, event['id'])['deleted'])
        self.assertTrue(self.store.list(self.guest)[0]['hosted'])

    def test_concurrent_leaves_still_warn_the_last_member(self):
        event = self.store.create(self.host, self.draft)
        self.store.join(self.guest, event['id'], '')
        def leave(user):
            try:
                return self.store.leave(user, event['id'])
            except ApiError as error:
                return error.code
        with concurrent.futures.ThreadPoolExecutor(2) as pool:
            results = list(pool.map(leave, [self.host, self.guest]))
        self.assertEqual(sum(x == 'last_member' for x in results), 1)
        self.assertEqual(self.store.list(self.host)[0]['memberCount'], 1)

    def test_nonmember_cannot_leave_or_delete(self):
        event = self.store.create(self.host, self.draft)
        with self.assertRaises(ApiError):
            self.store.leave(self.guest, event['id'], True)
        self.assertEqual(len(self.store.list(self.host)), 1)


if __name__ == '__main__':
    unittest.main()
