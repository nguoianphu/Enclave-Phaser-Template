#!/bin/bash

echo "Exit if there is any error"
set -e

MY_DIR=${PWD##*/}

echo "Copy Cordova files to the deploy folder"
rm -rf deploy
mkdir -p deploy
cp -R www/* deploy/

echo "Increase APP_VERSION"
echo "Getting info in the package.json"
APP_VERSION_CURRENT=$(cat package.json | grep version -m 1 | cut -d '"' -f4)
echo "Current App version: $APP_VERSION_CURRENT"
APP_VERSION=$(echo $APP_VERSION_CURRENT | awk -F. -v OFS=. 'NF==1{print ++$NF}; NF>1{if(length($NF+1)>length($NF))$(NF-1)++; $NF=sprintf("%0*d", length($NF), ($NF+1)%(10^length($NF))); print}')

echo "Set new App version $APP_VERSION to package.json"
sed -i "0,/${APP_VERSION_CURRENT}/{s/${APP_VERSION_CURRENT}/${APP_VERSION}/}" package.json

echo "Set App version $APP_VERSION to deploy/config.xml"
sed -i "s/APP_VERSION/${APP_VERSION}/1" deploy/config.xml


echo "Get App name"
APP_NAME=$(cat package.json | grep name -m 1 | cut -d '"' -f4)
APP_NAME=$(echo $APP_NAME | sed "s/ //g")
echo "Set App name $APP_NAME to deploy"
sed -i "s/APP_NAME/${APP_NAME}/g" deploy/config.xml
# sed -i "s/APP_NAME/${APP_NAME}/g" deploy/index.html

echo "Copy files to deploy folder"
cp index.html deploy/
cp favicon.ico deploy/
cp -R fonts deploy/
cp -R img deploy/
cp -R screens deploy/
cp -R sfx deploy/
cp -R src deploy/

BRANCH=$(git rev-parse --abbrev-ref HEAD)

git add .
git commit -m"$APP_NAME version $APP_VERSION on branch $BRANCH"
git config --global push.default simple
git push origin $BRANCH
echo "GOOD! The deploy folder is ready"


echo "Start the cordova builder on Travis-CI.org"

PASSWORD=$1
COMMENT=$2

if [ -z "$PASSWORD" ]; then
    echo "Use default password to encrypt"
    PASSWORD="ngu01anphu"
fi

if [ -z "$COMMENT" ]; then
    COMMENT=$(git log -1 --pretty=format:%s)
fi

cd ../cordova-builder

rm -rf www 
rm www.zip
git clean -df

git fetch --all
git config --global push.default simple
git checkout -B release origin/release

cp -R ../$MY_DIR/deploy www
zip -P $PASSWORD -r www.zip www

git add www.zip
git commit -m"${COMMENT}"
git push origin release 

git clean -df
echo "BUILD STARTED! Check Travis-CI for build result"

cd ../$MY_DIR
