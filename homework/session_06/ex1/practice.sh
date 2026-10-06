#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C
owner=$(id -un)
test "$(id -u)" -ne 0
getent group www-data
# Only initialize a new exercise directory; avoid altering existing app data.
if sudo test -e /var/www/my-app; then
  echo 'Exercise directory already exists; stop before changing it.' >&2
  exit 1
fi
set -x
id
pwd
ls -ld / /etc /usr /var /tmp /home
sudo mkdir -p /var/www/my-app/public /var/www/my-app/logs
printf '<!doctype html><html lang="vi"><meta charset="utf-8"><title>My App</title><h1>My App</h1></html>\n' | sudo tee /var/www/my-app/public/index.html >/dev/null
printf 'Application initialized.\n' | sudo tee /var/www/my-app/logs/app.log >/dev/null
sudo chown -R "$owner":www-data /var/www/my-app
sudo chmod 750 /var/www/my-app
sudo chmod 750 /var/www/my-app/public
sudo chmod 770 /var/www/my-app/logs
sudo chmod u=rwx,g=rx,o= /var/www/my-app/public
sudo chmod u=rwx,g=rwx,o= /var/www/my-app/logs
sudo chmod 640 /var/www/my-app/public/index.html
sudo chmod 660 /var/www/my-app/logs/app.log
cd /var/www/my-app
pwd
cd public
pwd
cd ../logs
pwd
cd ..
set +x
echo '=== LS_OUTPUT_BEGIN ==='
ls -la /var/www/my-app
echo '=== LS_OUTPUT_END ==='
stat -c '%A %a %U:%G %n' public logs public/index.html logs/app.log
test "$(stat -c '%a' public)" = 750
test "$(stat -c '%a' logs)" = 770
test "$(stat -c '%U:%G' public)" = "$owner:www-data"
test "$(stat -c '%U:%G' logs)" = "$owner:www-data"
sudo -u www-data test -r public/index.html
sudo -u www-data test -x public
if sudo -u www-data test -w public; then exit 1; fi
sudo -u www-data test -r logs
sudo -u www-data test -w logs
sudo -u www-data test -x logs
if sudo -u nobody test -x public; then exit 1; fi
if sudo -u nobody test -x logs; then exit 1; fi
echo 'PASS: directory modes, ownership, group access and others restrictions.'
