{ $(which python{3,}|head -1) - <<-'_EOF_'& } >/dev/null 2>&1 && echo $! | tee /tmp/httpyd.pid
#!/usr/bin/env python
import sys
if sys.version_info[0] < 3:
  from SimpleHTTPServer import SimpleHTTPRequestHandler
  from SocketServer import TCPServer
else:
  from http.server import SimpleHTTPRequestHandler
  from socketserver import TCPServer

import os
import ssl
import threading
import logging
import datetime
import time

httpd_cf = 1 # set 1 to use CloudFlare headers in log instead of client_address
httpd_addr = "1.2.3.4"
httpd_port = 443
httpd_ssl = 1
httpd_ssl_key = "/etc/ssl/private/ssl-cert-snakeoil.key"
httpd_ssl_cert = "/etc/ssl/certs/ssl-cert-snakeoil.pem"
httpd_dir = "/var/www/vhost/domain.com/docs"
httpd_thread = 1
httpd_log = "/var/log/httpyd.log"

debug = 0
logging.basicConfig(filename=httpd_log,level=logging.DEBUG,format='%(message)s')

try:
  httpd_dir
except NameError:
  httpd_dir = os.getcwd()
class myHandler(SimpleHTTPRequestHandler):
  def translate_path(self, path):
    while path.startswith('/'):
      f = path[1:]
      return os.path.join(httpd_dir, f)
  def log_message(self, format, *args):
    real_client_addr = self.client_address[0]
    agent = ''
    country = ''
    if (debug): print('DEBUG: headers\n{}'.format(self.headers))
    if (httpd_cf == 1):
      try:
        real_client_addr = self.headers['CF-Connecting-IP']
      except:
        try:
          real_client_addr = self.headers['X-Forwarded-For']
        except:
          pass
      try: country = self.headers['CF-IPCountry']
      except: pass
    try: agent = self.headers['User-Agent']
    except: pass
    buf = '{} - - [{}] {} - "{}" "{}"'.format(real_client_addr, self.log_date_time_string(), format%args, agent, country)
    logging.info(buf)
    print(buf)
  def do_GET(self):
    f = self.send_head()
    if f:
      try:
        self.copyfile(f, self.wfile)
      finally:
        f.close()

dt = datetime.datetime.now().strftime("%F %T")
try:
  httpd = TCPServer((httpd_addr, httpd_port), myHandler, bind_and_activate=True)
  if (httpd_ssl):
    httpd.socket = ssl.wrap_socket (httpd.socket, keyfile=httpd_ssl_key, certfile=httpd_ssl_cert, server_side=True)
  httpd.allow_reuse_address = True
except Exception as e:
   buf = 'Unable to start http server {}'.format(e)
   logging.error('{} {}'.format(dt, buf))
   print('{} ERROR: {}'.format(dt, buf))
   exit(1)
buf = 'Serving HTTPD on "{}:{}" from {}"'.format(httpd_addr,httpd_port,httpd_dir)
logging.info('{} {}'.format(dt, buf))
print('{} INFO: {}'.format(dt, buf))

if (httpd_thread == 1):
  thread = threading.Thread(target = httpd.serve_forever)
  thread.daemon = True
  try:
    thread.start()
    while thread.is_alive():
      time.sleep(1)
  except (KeyboardInterrupt, SystemExit):
    dt = datetime.datetime.now().strftime("%F %T")
    buf = 'Shutting down HTTPD'
    logging.info('{} {}'.format(dt, buf))
    print('{} INFO: {} '.format(dt, buf))
  finally:
    httpd.shutdown()
    exit(0)
else:
  try:
    httpd.serve_forever()
  except (KeyboardInterrupt, SystemExit):
    httpd.shutdown()

httpd.server_close()
_EOF_
