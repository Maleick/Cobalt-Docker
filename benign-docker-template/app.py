#!/usr/bin/env python3
import argparse
import json
from http.server import BaseHTTPRequestHandler, HTTPServer


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/health":
            self._send_json(200, {"status": "ok"})
            return
        self._send_json(
            200,
            {
                "service": "benign-template",
                "message": "Service is running",
                "health": "/health",
            },
        )

    def log_message(self, fmt, *args):
        print(f"[http] {self.address_string()} - {fmt % args}")

    def _send_json(self, status, payload):
        body = json.dumps(payload).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", default="0.0.0.0")
    parser.add_argument("--port", default=50051, type=int)
    args = parser.parse_args()

    server = HTTPServer((args.host, args.port), Handler)
    print(f"[app] Listening on {args.host}:{args.port}")
    server.serve_forever()


if __name__ == "__main__":
    main()
