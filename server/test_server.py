import concurrent.futures
import tempfile
import unittest
from pathlib import Path
from urllib.parse import parse_qs, urlparse
from unittest.mock import patch
from server import Store, ApiError, games_feed, scoreboard_feed, weather_feed


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
        public = self.store.create(self.host, self.draft | {'date': '2026-10-25'})
        visible = next(x for x in self.store.list(self.guest) if x['id'] == public['id'])
        self.assertEqual(visible['code'], '')

    def test_join_is_idempotent_and_host_leaving_transfers_ownership(self):
        event = self.store.create(self.host, self.draft)
        self.store.join(self.guest, event['id'], '')
        self.store.join(self.guest, event['id'], '')
        self.assertEqual(self.store.list(self.guest)[0]['memberCount'], 2)
        self.assertFalse(self.store.leave(self.host, event['id'])['deleted'])
        self.assertTrue(self.store.list(self.guest)[0]['hosted'])

    def test_member_names_are_saved_and_returned_to_the_crew(self):
        named_host = self.store.user(self.store.session('Abdul')['token'])
        named_guest = self.store.user(self.store.session('Taylor')['token'])
        event = self.store.create(named_host, self.draft)
        self.store.join(named_guest, event['id'], '')

        members = self.store.list(named_host)[0]['members']

        self.assertEqual(
            [(member['displayName'], member['isHost']) for member in members],
            [('Abdul', True), ('Taylor', False)],
        )
        self.store.set_profile(named_guest, 'Taylor Updated')
        updated = self.store.list(named_host)[0]['members']
        self.assertEqual(updated[1]['displayName'], 'Taylor Updated')

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

    def test_capacity_waitlist_promotes_when_a_member_leaves(self):
        event = self.store.create(self.host, self.draft | {'capacity': 2})
        self.store.join(self.guest, event['id'], '')
        waiting = self.store.user(self.store.session()['token'])
        self.assertEqual(
            self.store.join(waiting, event['id'], '')['membershipStatus'],
            'waitlisted',
        )
        self.store.leave(self.guest, event['id'])
        self.assertTrue(self.store.list(waiting)[0]['joined'])

    def test_approval_archive_delete_report_and_photo_recap(self):
        event = self.store.create(
            self.host,
            self.draft | {'requiresApproval': True},
        )
        pending = self.store.join(self.guest, event['id'], '')
        self.assertEqual(pending['membershipStatus'], 'pending')
        host_view = self.store.list(self.host)[0]
        self.assertEqual(host_view['pendingMembers'], [self.guest])
        self.store.approve(self.host, event['id'], self.guest)
        photos = self.store.photos(
            self.guest,
            event['id'],
            'https://example.com/recap.jpg',
            'Game day',
        )
        self.assertEqual(photos[0]['caption'], 'Game day')
        reporter = self.store.user(self.store.session()['token'])
        self.store.report(reporter, event['id'], 'Not a good fit', True)
        self.assertEqual(self.store.list(reporter), [])
        self.store.set_status(self.host, event['id'], 'completed')
        self.store.set_status(self.host, event['id'], 'archived')
        self.assertTrue(self.store.delete(self.host, event['id'])['deleted'])

    def test_duplicate_tailgate_for_same_host_game_and_day_is_rejected(self):
        self.store.create(self.host, self.draft)
        with self.assertRaises(ApiError) as error:
            self.store.create(self.host, self.draft | {'name': 'Duplicate'})
        self.assertEqual(error.exception.code, 'duplicate_tailgate')

    def test_bring_list_starts_empty_and_members_control_saved_items(self):
        event = self.store.create(self.host, self.draft)
        self.assertEqual(self.store.bring_items(self.host, event['id']), [])
        item = self.store.add_bring_item(self.host, event['id'], {
            'name': 'Paper plates', 'quantity': 3, 'category': 'gear',
        })
        self.assertEqual(item['claimedBy'], None)
        updated = self.store.update_bring_item(self.host, event['id'], item['id'], {
            'name': 'Paper plates', 'quantity': 4, 'category': 'gear',
            'claimedByMe': True, 'isPacked': True,
        })
        self.assertEqual(updated['quantity'], 4)
        self.assertTrue(updated['isPacked'])
        restarted = Store(self.path)
        self.assertEqual(restarted.bring_items(self.host, event['id'])[0]['name'], 'Paper plates')
        restarted.delete_bring_item(self.host, event['id'], item['id'])
        self.assertEqual(restarted.bring_items(self.host, event['id']), [])

    def test_nonmember_cannot_read_or_change_bring_list(self):
        event = self.store.create(self.host, self.draft)
        with self.assertRaises(ApiError):
            self.store.bring_items(self.guest, event['id'])
        with self.assertRaises(ApiError):
            self.store.add_bring_item(self.guest, event['id'], {
                'name': 'Ice', 'quantity': 1, 'category': 'drinks',
            })

    def test_guest_profile_can_be_saved_with_hashed_account_credentials(self):
        result = self.store.create_account(
            self.host, 'Fan@Example.com', 'strong-password')
        self.assertEqual(result['email'], 'fan@example.com')
        with self.store.connect() as db:
            account = db.execute(
                'SELECT email,password_hash FROM accounts WHERE user_id=?',
                (self.host,)).fetchone()
        self.assertEqual(account['email'], 'fan@example.com')
        self.assertNotEqual(account['password_hash'], 'strong-password')
        with self.assertRaises(ApiError):
            self.store.create_account(self.guest, 'fan@example.com', 'another-password')


class ProviderContractTests(unittest.TestCase):
    @patch.dict('os.environ', {'CFBD_API_KEY': 'test-key'})
    @patch('server.fetch_json')
    def test_schedule_is_normalized_from_current_cfbd_contract(self, fetch):
        fetch.return_value = [{
            'id': 401,
            'homeTeam': 'LSU',
            'awayTeam': 'Florida',
            'startDate': '2026-10-24T23:30:00Z',
            'completed': True,
            'homePoints': 31,
            'awayPoints': 17,
            'venue': 'Tiger Stadium',
        }]

        result = games_feed({'team': ['LSU'], 'year': ['2026']})

        self.assertEqual(result['games'][0], {
            'id': '401',
            'homeTeam': 'LSU',
            'awayTeam': 'Florida',
            'startDate': '2026-10-24T23:30:00Z',
            'status': 'completed',
            'homePoints': 31,
            'awayPoints': 17,
            'venue': 'Tiger Stadium',
            'live': False,
        })
        self.assertEqual(fetch.call_args.args[1], {'Authorization': 'Bearer test-key'})

    @patch.dict('os.environ', {'CFBD_API_KEY': 'test-key'})
    @patch('server.fetch_json')
    def test_scoreboard_filters_team_and_normalizes_nested_scores(self, fetch):
        fetch.return_value = [
            {
                'id': 402,
                'homeTeam': {'name': 'LSU', 'points': 14},
                'awayTeam': {'name': 'Alabama', 'points': 10},
                'startDate': '2026-11-07T23:00:00Z',
                'status': 'in_progress',
                'venue': {'name': 'Tiger Stadium'},
            },
            {
                'id': 999,
                'homeTeam': {'name': 'Other', 'points': 7},
                'awayTeam': {'name': 'Teams', 'points': 3},
                'startDate': '2026-11-07T23:00:00Z',
                'status': 'in_progress',
            },
        ]

        result = scoreboard_feed({'team': ['lsu'], 'classification': ['fbs']})

        self.assertEqual(len(result['games']), 1)
        self.assertEqual(result['games'][0]['status'], 'in_progress')
        self.assertEqual(result['games'][0]['homePoints'], 14)
        self.assertEqual(result['games'][0]['venue'], 'Tiger Stadium')

    @patch('server.fetch_json')
    def test_weather_requests_us_units_and_utc_hours(self, fetch):
        fetch.return_value = {'hourly': {'time': []}}

        weather_feed({'latitude': ['30.412'], 'longitude': ['-91.184']})

        query = parse_qs(urlparse(fetch.call_args.args[0]).query)
        self.assertEqual(query['temperature_unit'], ['fahrenheit'])
        self.assertEqual(query['wind_speed_unit'], ['mph'])
        self.assertEqual(query['timezone'], ['UTC'])


if __name__ == '__main__':
    unittest.main()
