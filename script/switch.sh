#!/usr/bin/env bash
echo "> Check running port."
CURRENT_PROFILE=$(curl -s http://localhost/profile)

# Find idle set.
if [ $CURRENT_PROFILE == set1 ]
then
  IDLE_PORT=8082
elif [ $CURRENT_PROFILE == set2 ]
then
  IDLE_PORT=8081
else
  echo "> Failed to find profile. Profile: $CURRENT_PROFILE"
  echo "> Allocate 8081."
  IDLE_PORT=8081
fi

echo "> Port to switch: $IDLE_PORT"
echo "> Port switching."
echo "set \$service_url http://127.0.0.1:${IDLE_PORT};" |sudo tee /etc/nginx/conf.d/service-url.inc

PROXY_PORT=$(curl -s http://localhost/profile)
echo "> Current Nginx Proxy Port: $PROXY_PORT"

echo "> Nginx Reload"
sudo systemctl reload nginx

sleep 10
PROXY_PORT=$(curl -s http://localhost/profile)
echo "> Set Nginx Proxy Port: $PROXY_PORT"