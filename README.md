# httpyd
Python HTTPServer with CloudFlare support

### http.server/SimpleHTTPServer with some extra's:

- works with both Python 2 and 3
- runs as "hybrid" Shell/Python script (in bg/daemonized)
- uses CloudFlare headers to get client ip address
- TLS/SSL

#### Run:
To run as Shell/Bash script: `bash httpyd.sh` (or +x and `./httpyd.sh`)
It will both print PID to stdout and write it to `/tmp/httpyd.pid`

To run using Python: `python -x httpyd.sh`
(first line in script is a here-doc wrapper)

#### Options:
Options are set inside script: [0/1] to disable/enable
```
httpd_cf = 1 # set 1 to use CloudFlare headers in log instead of client_address
httpd_addr = "1.2.3.4"
httpd_port = 443
httpd_ssl = 1
httpd_ssl_key = "/etc/ssl/private/ssl-cert-domain.key"
httpd_ssl_cert = "/etc/ssl/certs/ssl-cert-domain.pem"
httpd_dir = "/var/www/vhost/domain.com/docs"
httpd_thread = 1
httpd_log = "/var/log/httpd_py.log"
```
(to run as non root user you have to choose diff port/paths)


#### Logging:
If headers `CF-Connecting-IP` (or `X-Forwarded-For`) is set it will be used instead as client address in log, `CF-IPCountry` is added at the end of each line:

`1.2.3.4 - - [12/Jun/2018 09:09:08] "GET / HTTP/1.1" 200 - - "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/67.0.3396.62 Safari/537.36" "NL"`
