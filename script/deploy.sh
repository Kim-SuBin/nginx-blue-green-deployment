#!/usr/bin/env bash
BASE_PATH=/home/ubuntu/server/
BUILD_PATH=$(ls $BASE_PATH/build/*.jar)
JAR_NAME=$(basename $BUILD_PATH)
echo "> Build name : $JAR_NAME"

echo "> Copy build file"
DEPLOY_PATH=$BASE_PATH/jar/
cp $BUILD_PATH $DEPLOY_PATH

echo "> Check the running Set"
CURRENT_PROFILE=$(curl -s http://localhost/profile)
echo "> $CURRENT_PROFILE"

# Find idle set.
if [ $CURRENT_PROFILE == set1 ]
then
  IDLE_PROFILE=set2
  IDLE_PORT=8082
elif [ $CURRENT_PROFILE == set2 ]
then
  IDLE_PROFILE=set1
  IDLE_PORT=8081
else
  echo "> Failed to find profile. Profile: $CURRENT_PROFILE"
  echo "> Allocate set1. IDLE_PROFILE: set1"
  IDLE_PROFILE=set1
  IDLE_PORT=8081
fi

echo "> Change application.jar"
IDLE_APPLICATION=$IDLE_PROFILE-servertest.jar
IDLE_APPLICATION_PATH=$DEPLOY_PATH$IDLE_APPLICATION

ln -Tfs $DEPLOY_PATH$JAR_NAME $IDLE_APPLICATION_PATH

echo "> Check $IDLE_PROFILE PID"
IDLE_PID=$(pgrep -f $IDLE_APPLICATION)

if [ -z $IDLE_PID ]
then
  echo "> No application is running."
else
  echo "> kill -15 $IDLE_PID"
  kill -15 $IDLE_PID
  sleep 5
fi

echo "> $IDLE_PROFILE deployment."
nohup java -jar -Dspring.profiles.active=$IDLE_PROFILE,common $IDLE_APPLICATION_PATH &

echo "> Start $IDLE_PROFILE health check after 10 seconds."
echo "> curl -s http://localhost:$IDLE_PORT/application/health-check"
sleep 10

for retry_count in {1..10}
do
  response=$(curl -s http://localhost:$IDLE_PORT/application/health-check)
  up_count=$(echo $response | grep 'UP' | wc -l)

  if [ $up_count -ge 1 ]
  then
    echo "> Success health check."
    break
  else
    echo "> The health check response is unknown or the status is not 'UP'."
    echo "> Health check: ${response}"
  fi

  if [ $retry_count -eq 10 ]
  then
    echo "> Failed health check."
    echo "> Terminate the deployment without connecting to Nginx."
    exit 1
  fi

  echo "> Health check connection failed. Retry..."
  sleep 10
done

echo "> Switching"
sleep 10
/home/ubuntu/server/switch.sh
