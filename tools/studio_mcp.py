"""Local MCP stdio client for Roblox's verified official Studio server.

This is a client, not a replacement Studio server. The loopback HTTP adapter
keeps the official stdio session alive across command-line calls in this task.
"""
import argparse
import json
import queue
import subprocess
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.request import Request, urlopen

ROOT = Path(__file__).resolve().parents[1]
PORT = 49324


class StdioClient:
    def __init__(self):
        self.pending = {}
        self.serial = 0
        self.lock = threading.Lock()
        self.proc = subprocess.Popen(
            [str(ROOT / '.tools/roblox-mcp/rbx-studio-mcp.exe'), '--stdio'],
            stdin=subprocess.PIPE, stdout=subprocess.PIPE,
            stderr=open(ROOT / 'evidence/mcp-server.log', 'a', encoding='utf-8'),
            text=True, encoding='utf-8', bufsize=1,
            creationflags=getattr(subprocess, 'CREATE_NO_WINDOW', 0),
        )
        threading.Thread(target=self.read, daemon=True).start()
        self.info = self.call('initialize', {
            'protocolVersion': '2024-11-05', 'capabilities': {},
            'clientInfo': {'name': 'RoyalRush-Codex', 'version': '1.0.0'},
        })
        self.notify('notifications/initialized')
        self.tools = self.call('tools/list', {})
        (ROOT / 'evidence/mcp-tool-discovery.json').write_text(
            json.dumps({'server': self.info, 'tools': self.tools}, ensure_ascii=False, indent=2),
            encoding='utf-8',
        )

    def read(self):
        for line in self.proc.stdout:
            try:
                msg = json.loads(line)
            except json.JSONDecodeError:
                continue
            response = self.pending.get(msg.get('id'))
            if response:
                response.put(msg)

    def notify(self, method):
        with self.lock:
            self.proc.stdin.write(json.dumps({'jsonrpc': '2.0', 'method': method}) + '\n')
            self.proc.stdin.flush()

    def call(self, method, params, timeout=55):
        with self.lock:
            self.serial += 1
            request_id = self.serial
            response = queue.Queue()
            self.pending[request_id] = response
            self.proc.stdin.write(json.dumps({
                'jsonrpc': '2.0', 'id': request_id, 'method': method, 'params': params,
            }, ensure_ascii=False) + '\n')
            self.proc.stdin.flush()
        try:
            return response.get(timeout=timeout)
        finally:
            self.pending.pop(request_id, None)


def serve():
    client = StdioClient()

    class Handler(BaseHTTPRequestHandler):
        def log_message(self, *args):
            pass

        def do_GET(self):
            self.reply({'server': client.info, 'tools': client.tools})

        def do_POST(self):
            try:
                payload = json.loads(self.rfile.read(int(self.headers.get('Content-Length', 0))))
                self.reply(client.call(payload['method'], payload.get('params', {})))
            except Exception as exc:
                self.reply({'error': str(exc)}, 500)

        def reply(self, payload, status=200):
            body = json.dumps(payload, ensure_ascii=False).encode('utf-8')
            self.send_response(status)
            self.send_header('Content-Type', 'application/json; charset=utf-8')
            self.send_header('Content-Length', str(len(body)))
            self.end_headers()
            self.wfile.write(body)

    server = ThreadingHTTPServer(('127.0.0.1', PORT), Handler)
    print('Official Roblox MCP stdio client ready on loopback port', PORT, flush=True)
    try:
        server.serve_forever()
    finally:
        client.proc.terminate()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--serve', action='store_true')
    parser.add_argument('--request', type=Path)
    args = parser.parse_args()
    if args.serve:
        serve()
        return
    if args.request:
        payload = args.request.read_bytes()
        request = Request(f'http://127.0.0.1:{PORT}/', data=payload, headers={'Content-Type': 'application/json'})
        print(urlopen(request, timeout=60).read().decode('utf-8'))
    else:
        print(urlopen(f'http://127.0.0.1:{PORT}/', timeout=5).read().decode('utf-8'))


if __name__ == '__main__':
    main()
