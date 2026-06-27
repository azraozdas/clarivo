#!/usr/bin/env python3
"""Local CORS proxy for Marketstack API — run this before flutter run on web."""
from http.server import HTTPServer, BaseHTTPRequestHandler
import urllib.request
import ssl

MARKETSTACK_BASE = 'https://api.marketstack.com/v2'

class ProxyHandler(BaseHTTPRequestHandler):
    def do_OPTIONS(self):
        self.send_response(200)
        self._cors()
        self.end_headers()

    def do_GET(self):
        target = f'{MARKETSTACK_BASE}{self.path}'
        ctx = ssl.create_default_context()
        ctx.check_hostname = False
        ctx.verify_mode = ssl.CERT_NONE
        req = urllib.request.Request(
            target,
            headers={'User-Agent': 'ClarivApp/1.0'},
        )
        try:
            with urllib.request.urlopen(req, context=ctx, timeout=15) as resp:
                data = resp.read()
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self._cors()
            self.end_headers()
            self.wfile.write(data)
        except Exception as e:
            self.send_response(502)
            self._cors()
            self.end_headers()
            self.wfile.write(str(e).encode())

    def _cors(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', '*')

    def log_message(self, fmt, *args):
        print(f'[proxy] {fmt % args}')

if __name__ == '__main__':
    server = HTTPServer(('localhost', 8089), ProxyHandler)
    print('Marketstack CORS proxy running on http://localhost:8089')
    server.serve_forever()
