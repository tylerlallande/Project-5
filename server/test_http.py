import json
import tempfile
import threading
import unittest
from pathlib import Path
from urllib.error import HTTPError
from urllib.request import Request, urlopen
from http.server import ThreadingHTTPServer
from server import Store, handler


class HttpTests(unittest.TestCase):
    def test_two_devices_join_and_last_leave_deletes_via_http(self):
        with tempfile.TemporaryDirectory() as folder:
            store = Store(Path(folder) / 'test.sqlite3')
            server = ThreadingHTTPServer(('127.0.0.1', 0), handler(store))
            thread = threading.Thread(target=server.serve_forever, daemon=True)
            thread.start()
            try:
                base = f'http://127.0.0.1:{server.server_port}'
                def call(path, token=None, data=None, origin=None):
                    headers = {'Content-Type': 'application/json'}
                    if token:
                        headers['Authorization'] = f'Bearer {token}'
                    if origin:
                        headers['Origin'] = origin
                    request = Request(base + path, headers=headers,
                                      data=json.dumps(data).encode() if data is not None else None)
                    try:
                        with urlopen(request, timeout=5) as response:
                            return response.status, json.load(response)
                    except HTTPError as error:
                        return error.code, json.load(error)
                host = call('/sessions', data={})[1]['token']
                guest = call('/sessions', data={})[1]['token']
                self.assertEqual(call('/tailgates')[0], 401)
                self.assertEqual(call('/tailgates', host, origin='https://example.com')[0], 403)
                event = call('/tailgates', host, {'draft': dict(game='LSU', name='HTTP crew',
                    date='2026-10-24', kickoff='6 PM', meetupTime='Noon', location='Oak Grove', vibe='Food', isPublic=True)})[1]
                ident = event['id']
                self.assertEqual(call('/tailgates', host)[1][0]['id'], ident)
                self.assertFalse(call('/tailgates', guest)[1][0]['joined'])
                self.assertEqual(call(f'/tailgates/{ident}/join', guest, {})[1]['memberCount'], 2)
                self.assertFalse(call(f'/tailgates/{ident}/leave', host, {})[1]['deleted'])
                status, warning = call(f'/tailgates/{ident}/leave', guest, {})
                self.assertEqual((status, warning['code']), (409, 'last_member'))
                self.assertTrue(call(f'/tailgates/{ident}/leave', guest, {'confirmDelete': True})[1]['deleted'])
                self.assertEqual(call('/tailgates', host)[1], [])
                self.assertEqual(call('/tailgates/lookup', host, {'code': event['code']})[0], 404)
            finally:
                server.shutdown()
                server.server_close()
                thread.join(timeout=5)


if __name__ == '__main__':
    unittest.main()
