#!/usr/bin/env python3
import os
from http.server import BaseHTTPRequestHandler, HTTPServer

pairingToken = os.environ.get('ASPNETCORE_TOKEN')

class RequestHandler(BaseHTTPRequestHandler):

    def _start_response(self, status):
        self.send_response(status)
        self.send_header('Content-Type', 'text/plain')
        self.end_headers()


    def do_GET(self):
        if pairingToken != self.headers.get('MS-ASPNETCORE-TOKEN'):
            self._start_response(403)
            self.wfile.write('Invalid request: ANCM token mismatch')
            return

        self._start_response(200)

        iisUser = self.headers['MS-ASPNETCORE-USER']
        if iisUser is not None:
            self.wfile.write("Hello from Python, {}!\r\n\r\n".format(iisUser).encode('utf-8'))
        self.wfile.write(str(self.headers).encode('utf-8'))


port = int(os.environ['ASPNETCORE_PORT'])

server = HTTPServer(('127.0.0.1', port), RequestHandler)
server.serve_forever()
