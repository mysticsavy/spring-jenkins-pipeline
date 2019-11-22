#!/usr/bin/env bash

DEPLOYMENT=$1

###### Deployment variables
SERVER_USERNAME=$2
SERVER_PASSWORD=$3
DB_USERNAME=$4
DB_PASSWORD=$5
ENV_USERNAME=$6
ENV_PASSWORD=$7
SP_USERNAME=$8
SP_PASSWORD=$9

###### WUMAdmin Microservice
WUMADMIN_EMAIL_USERNAME=$10
WUMADMIN_EMAIL_PASSWORD=$11

SUBSCRIPTION_SALESFORCE_CLIENT_SECRET=$12
SUBSCRIPTION_SALESFORCE_CLIENT_ID=$13
SUBSCRIPTION_SALESFORCE_TOKEN=$14
SUBSCRIPTION_SALESFORCE_USERNAME=$15
SUBSCRIPTION_SALESFORCE_PASSWORD=$16
SUBSCRIPTION_JIRA_USERNAME=$17
SUBSCRIPTION_JIRA_PASSWORD=$18

# Set deployment specific variables
if [[ ${DEPLOYMENT} = "dev" ]]
then
	TENANT="wumdev"
	CDN_URL="https://staging-cdn-updates.private.wso2.com/"
	UPDATES_ENVIRONMENT="dev"
elif [[ ${DEPLOYMENT} = "staging" ]]
then
	TENANT="wumstaging"
	CDN_URL="https://staging-cdn-updates.private.wso2.com/"
	UPDATES_ENVIRONMENT="staging"
else
	echo "Invaid deployment $DEPLOYMENT"
	exit 1
fi

VERSION="1.0.0-SNAPSHOT"
USER_TENANT=${ENV_USERNAME}"@"${TENANT}
DB_TENANT="300_"${TENANT}
DB_POOLSIZE="50"
DB_MAX_RETRIES="3"
DB_RETRY_INTERVAL="500"
SP_URL="https://staging-internal-analytics-reciever.wso2.com:5005/"
NEW_VERSION="true"

VALIDATE_WSO2_DOMAIN="true"
SP_ENABLE="false"
UPDATES_LIFECYCLE_STATES="Regression,Broken,Released,ReleasedNotAutomated,ReleasedNotInPublicSVN,Staging"

###### Products Microservice
PRODUCTS_APPNAME="products-v3"
PRODUCTS_APP_DESC="Products-MS"
PRODUCTS_DB="productsdb"
PRODUCTS_VERSION=${VERSION}
# PRODUCTS_UMT_TOKEN="441b2412365fefceca449e2d5d24e1d"
# PRODUCTS_UMT_API_URL="https://umt.private.wso2.com"
# PRODUCTS_UMT_API_PATH="wumapi/1.0.0/properties?path=/_system/governance/patchs/WSO2-CARBON-PATCH-"
# PRODUCTS_IGNORED_EXTENSIONS="jag,js,sh,css,html,xml,conf,war,json"
PRODUCTS_JAR="products-"${VERSION}".jar"
PRODUCTS_FILE_PATH=${GITHUB_WORKSPACE}"/repository-api/products/target/products-"${VERSION}".jar"
PRODUCTS_API_URL="https://"${TENANT}"-products-v3.wso2apps.com/products/"

###### Updates Microservice
UPDATES_APPNAME="updates-v3"
UPDATES_APP_DESC="Updates-MS"
UPDATES_DB="updatesdb"
UPDATES_VERSION=${VERSION}
UPDATES_JAR="updates-"${VERSION}".jar"
UPDATES_FILE_PATH=${GITHUB_WORKSPACE}"/repository-api/updates/target/updates-"${VERSION}".jar"
UPDATES_API_URL="https://"${TENANT}"-"${UPDATES_APPNAME}".wso2apps.com/updates/"

###### Subscription Microservice
SUBSCRIPTION_APPNAME="subscriptions-v3"
SUBSCRIPTION_APP_DESC="Subscription-MS"
SUBSCRIPTION_VERSION=${VERSION}
SUBSCRIPTION_DB="subscriptiondb"
SUBSCRIPTION_JAR="subscriptions-"${VERSION}".jar"
SUBSCRIPTION_FILE_PATH=${GITHUB_WORKSPACE}"/repository-api/subscriptions/target/subscriptions-"${VERSION}".jar"
SUBSCRIPTION_SALESFORCE_URL="https://wso2.my.salesforce.com"
SUBSCRIPTION_TRIAL_DAYS="15"
SUBSCRIPTION_CACHE_EXPIRY="1"
SUBSCRIPTION_JIRA_URL="https://support.wso2.com"
SUBSCRIPTION_SP_URL="$SP_URL"subscriptions
SUBSCRIPTIONS_API_URL="https://"${TENANT}"-subscriptions-v3.wso2apps.com/subscriptions"

###### Channels Microservice
CHANNELS_APPNAME="channels-v3"
CHANNELS_APP_DESC="CHANNELS-MS"
CHANNELS_DB="channelsdb"
CHANNELS_VERSION=${VERSION}
CHANNELS_JAR="channels-"${VERSION}".jar"
DEFAULT_CHANNEL="full"
CHANNELS_FILE_PATH=${GITHUB_WORKSPACE}"/repository-api/channels/target/channels-"${VERSION}".jar"
CHANNELS_API_URL="https://"${TENANT}"-channels-v3.wso2apps.com/channels/"

##################################################################################################################
##################################################################################################################


PRODUCTS_JDBC_URL="jdbc:mysql://mysql.storage.cloud.wso2.com:3306/"${PRODUCTS_DB}"_"${DB_TENANT}"?autoReconnect=true"
PRODUCTS_SP_FULL_URL="$SP_URL"products
PRODUCTS_CDN_URL=${CDN_URL}"products/"

CHANNELS_JDBC_URL="jdbc:mysql://mysql.storage.cloud.wso2.com:3306/"${CHANNELS_DB}"_"${DB_TENANT}"?autoReconnect=true"
CHANNELS_DAS_FULL_URL="$SP_URL"channels

UPDATES_JDBC_URL="jdbc:mysql://mysql.storage.cloud.wso2.com:3306/"${UPDATES_DB}"_"${DB_TENANT}"?autoReconnect=true"
UPDATES_SP_FULL_URL="$SP_URL"updates
UPDATES_CDN_URL=${CDN_URL}"updates/"

SUBSCRIPTION_DATABASE_URL="jdbc:mysql://mysql.storage.cloud.wso2.com:3306/"${SUBSCRIPTION_DB}"_"${DB_TENANT}"?autoReconnect=true"

##################################################################################################################
##################################################################################################################

function appCloudLogin() {
	echo "App Cloud Login"
	curl -c cookies -v -X POST -k https://integration.cloud.wso2.com/appmgt/site/blocks/user/login/ajax/login.jag \
	-d 'action=login&userName='${USER_TENANT}'&password='${ENV_PASSWORD}
}

function appCloudLogout() {
	echo "App Cloud Logout"
	curl -b cookies -v -X POST -k https://integration.cloud.wso2.com/appmgt/site/blocks/user/logout/ajax/logout.jag -d 'action=logout'
}

function uploadProductsMS() {
	echo "Deploying product microservice..."
	curl -v -b cookies -X POST "https://integration.cloud.wso2.com/appmgt/site/blocks/application/application.jag" -F action=createApplication \
	-F runtime=27 -F appTypeName=mss -F isFileAttached=true -F appCreationMethod=default -F conSpec=4 \
	-F applicationName=${PRODUCTS_APPNAME} -F applicationDescription=${PRODUCTS_APP_DESC} -F applicationRevision=${PRODUCTS_VERSION} -F uploadedFileName=${PRODUCTS_JAR} \
	-F runtimeProperties='[
		{"key": "wum_products_server_username","value": "'${SERVER_USERNAME}'"},
		{"key": "wum_products_server_password","value": "'${SERVER_PASSWORD}'"},
		{"key": "wum_products_database_username","value": "'${DB_USERNAME}'"},
		{"key": "wum_products_database_password","value": "'${DB_PASSWORD}'"},
		{"key": "wum_products_database_url","value": "'${PRODUCTS_JDBC_URL}'"},
		{"key": "wum_products_database_pool_size","value": "'${DB_POOLSIZE}'"},
		{"key": "wum_products_database_max_retries","value": "'${DB_MAX_RETRIES}'"},
		{"key": "wum_products_database_retry_interval", "value": "'${DB_RETRY_INTERVAL}'"},
		{"key": "wum_products_sp_enabled","value": "'${SP_ENABLE}'"},
		{"key": "wum_products_sp_username","value": "'${SP_USERNAME}'"},
		{"key": "wum_products_sp_password","value": "'${SP_PASSWORD}'"},
    {"key": "wum_products_sp_url", "value": "'${PRODUCTS_SP_FULL_URL}'"},
    {"key": "wum_products_channels_username","value": "'${SERVER_USERNAME}'"},
    {"key": "wum_products_channels_password","value": "'${SERVER_PASSWORD}'"},
    {"key": "wum_products_channels_api_url","value": "'${CHANNELS_API_URL}'"},
    {"key": "wum_products_download_url_prefix","value": "'${PRODUCTS_CDN_URL}'"},
    {"key": "wum_products_jwt_shared_key", "value": "WUM Shared Key Used in the JWT encryption"},
    {"key": "wum_products_validate_wso2_domain", "value": "'${VALIDATE_WSO2_DOMAIN}'"},
		{"key": "JAVA_OPTS", "value": "-XX:NativeMemoryTracking=summary -Xms256m -Xmx256m -XX:ThreadStackSize=256 -XX:MaxMetaspaceSize=128m"}]' \
	-F fileupload=@${PRODUCTS_FILE_PATH} -F isNewVersion=${NEW_VERSION} --progress-bar -k
}

function uploadUpdatesMS() {
	echo "Deploying updates microservice..."
	curl -v -b cookies -X POST "https://integration.cloud.wso2.com/appmgt/site/blocks/application/application.jag" -F action=createApplication \
	-F runtime=27 -F appTypeName=mss -F isFileAttached=true -F appCreationMethod=default -F conSpec=4 \
	-F applicationName=${UPDATES_APPNAME} -F applicationDescription=${UPDATES_APP_DESC} -F applicationRevision=${UPDATES_VERSION} -F uploadedFileName=${UPDATES_JAR} \
	-F runtimeProperties='[
		{"key": "wum_updates_server_username","value": "'${SERVER_USERNAME}'"},
		{"key": "wum_updates_server_password","value": "'${SERVER_PASSWORD}'"},
		{"key": "wum_updates_database_url","value": "'${UPDATES_JDBC_URL}'"},
		{"key": "wum_updates_database_username","value": "'${DB_USERNAME}'"},
		{"key": "wum_updates_database_password","value": "'${DB_PASSWORD}'"},
		{"key": "wum_updates_database_pool_size","value": "'${DB_POOLSIZE}'"},
		{"key": "wum_updates_database_max_retries", "value": "'${DB_MAX_RETRIES}'"},
		{"key": "wum_updates_database_retry_interval", "value": "'${DB_RETRY_INTERVAL}'"},
		{"key": "wum_updates_sp_enabled","value": "'${SP_ENABLE}'"},
		{"key": "wum_updates_sp_username","value": "'${SP_USERNAME}'"},
		{"key": "wum_updates_sp_password","value": "'${SP_PASSWORD}'"},
		{"key": "wum_updates_sp_url","value": "'${UPDATES_SP_FULL_URL}'"},
		{"key": "wum_updates_channels_username","value": "'${SERVER_USERNAME}'"},
		{"key": "wum_updates_channels_password","value": "'${SERVER_PASSWORD}'"},
		{"key": "wum_updates_channels_api_url","value": "'${CHANNELS_API_URL}'"},
		{"key": "wum_updates_jwt_shared_key","value": "WUM Shared Key Used in the JWT encryption"},
		{"key": "wum_updates_validate_wso2_domain","value": "'${VALIDATE_WSO2_DOMAIN}'"},
		{"key": "wum_updates_lifecycle_states","value": "'${UPDATES_LIFECYCLE_STATES}'"},
    {"key": "wum_updates_environment","value": "'${UPDATES_ENVIRONMENT}'"},
		{"key": "wum_updates_download_url_prefix","value": "'${UPDATES_CDN_URL}'"},
		{"key": "wum_updates_products_username","value": "'${SERVER_USERNAME}'"},
		{"key": "wum_updates_products_password","value": "'${SERVER_PASSWORD}'"},
		{"key": "wum_updates_products_api_url","value": "'${PRODUCTS_API_URL}'"},
		{"key": "JAVA_OPTS","value": "-XX:NativeMemoryTracking=summary -Xms256m -Xmx256m -XX:ThreadStackSize=256 -XX:MaxMetaspaceSize=128m"}]' \
	-F fileupload=@${UPDATES_FILE_PATH} -F isNewVersion=${NEW_VERSION} --progress-bar -k
}

function uploadSubscriptionMS() {
	echo "Deploying subscription microservice..."
    curl -v -b cookies -X POST "https://integration.cloud.wso2.com/appmgt/site/blocks/application/application.jag" -F action=createApplication \
    -F runtime=27 -F appTypeName=mss -F isFileAttached=true -F appCreationMethod=default -F conSpec=4 \
    -F applicationName=${SUBSCRIPTION_APPNAME} -F applicationDescription=${SUBSCRIPTION_APP_DESC} -F applicationRevision=${SUBSCRIPTION_VERSION} -F uploadedFileName=${SUBSCRIPTION_JAR} \
    -F runtimeProperties='[
		{"key": "wum_subscriptions_server_username","value": "'${SERVER_USERNAME}'"},
		{"key": "wum_subscriptions_server_password","value": "'${SERVER_PASSWORD}'"},
		{"key": "wum_subscriptions_trial_days","value": "'${SUBSCRIPTION_TRIAL_DAYS}'"},
		{"key": "wum_subscriptions_cache_expiry","value": "'${SUBSCRIPTION_CACHE_EXPIRY}'"},
		{"key": "wum_subscriptions_supportjira_url","value": "'${SUBSCRIPTION_JIRA_URL}'"},
		{"key": "wum_subscriptions_supportjira_username","value": "'${SUBSCRIPTION_JIRA_USERNAME}'"},
		{"key": "wum_subscriptions_supportjira_password","value": "'${SUBSCRIPTION_JIRA_PASSWORD}'"},
		{"key": "wum_subscriptions_salesforce_username","value": "'${SUBSCRIPTION_SALESFORCE_USERNAME}'"},
		{"key": "wum_subscriptions_salesforce_password","value": "'${SUBSCRIPTION_SALESFORCE_PASSWORD}'"},
		{"key": "wum_subscriptions_salesforce_token","value": "'${SUBSCRIPTION_SALESFORCE_TOKEN}'"},
		{"key": "wum_subscriptions_salesforce_url","value": "'${SUBSCRIPTION_SALESFORCE_URL}'"},
		{"key": "wum_subscriptions_salesforce_client_secret","value": "'${SUBSCRIPTION_SALESFORCE_CLIENT_SECRET}'"},
		{"key": "wum_subscriptions_salesforce_client_id","value": "'${SUBSCRIPTION_SALESFORCE_CLIENT_ID}'"},
		{"key": "wum_subscriptions_database_username","value": "'${DB_USERNAME}'"},
		{"key": "wum_subscriptions_database_password","value": "'${DB_PASSWORD}'"},
		{"key": "wum_subscriptions_database_url","value": "'${SUBSCRIPTION_DATABASE_URL}'"},
		{"key": "wum_subscriptions_sp_enabled","value": "'${SP_ENABLE}'"},
		{"key": "wum_subscriptions_sp_username","value": "'${SP_USERNAME}'"},
		{"key": "wum_subscriptions_sp_password","value": "'${SP_PASSWORD}'"},
		{"key": "wum_subscriptions_sp_url","value": "'${SUBSCRIPTION_SP_URL}'"},
		{"key": "JAVA_OPTS","value": "-XX:NativeMemoryTracking=summary -Xms256m -Xmx256m -XX:ThreadStackSize=256 -XX:MaxMetaspaceSize=128m"}]' \
    -F fileupload=@${SUBSCRIPTION_FILE_PATH} -F isNewVersion=${NEW_VERSION} --progress-bar -k
}

function uploadChannelsMS() {
	echo "Deploying channels microservice..."
	curl -v -b cookies -X POST "https://integration.cloud.wso2.com/appmgt/site/blocks/application/application.jag" -F action=createApplication \
	-F runtime=27 -F appTypeName=mss -F isFileAttached=true -F appCreationMethod=default -F conSpec=4 \
	-F applicationName=${CHANNELS_APPNAME} -F applicationDescription=${CHANNELS_APP_DESC} -F applicationRevision=${CHANNELS_VERSION} -F uploadedFileName=${CHANNELS_JAR} \
	-F runtimeProperties='[
		{"key": "wum_channels_server_username","value": "'${SERVER_USERNAME}'"},
		{"key": "wum_channels_server_password","value": "'${SERVER_PASSWORD}'"},
		{"key": "wum_channels_database_username","value": "'${DB_USERNAME}'"},
		{"key": "wum_channels_database_password","value": "'${DB_PASSWORD}'"},
		{"key": "wum_channels_database_url","value": "'${CHANNELS_JDBC_URL}'"},
		{"key": "wum_channels_database_pool_size","value": "'${DB_POOLSIZE}'"},
		{"key": "wum_channels_database_max_retries", "value": "'${DB_MAX_RETRIES}'"},
		{"key": "wum_channels_database_retry_interval", "value": "'${DB_RETRY_INTERVAL}'"},
		{"key": "wum_channels_sp_enabled","value": "'${SP_ENABLE}'"},
		{"key": "wum_channels_sp_username","value": "'${SP_USERNAME}'"},
		{"key": "wum_channels_sp_password","value": "'${SP_PASSWORD}'"},
		{"key": "wum_channels_sp_url", "value": "'${CHANNELS_DAS_FULL_URL}'"},
		{"key": "wum_channels_validate_wso2_domain", "value": "'${VALIDATE_WSO2_DOMAIN}'"},
		{"key": "wum_channels_subscriptions_username","value": "'${SERVER_USERNAME}'"},
		{"key": "wum_channels_subscriptions_password","value": "'${SERVER_PASSWORD}'"},
		{"key": "wum_channels_user_default_channel","value": "'${DEFAULT_CHANNEL}'"},
		{"key": "wum_channels_subscriptions_api_url","value": "'${SUBSCRIPTIONS_API_URL}'"},
		{"key": "JAVA_OPTS", "value": "-XX:NativeMemoryTracking=summary -Xms256m -Xmx256m -XX:ThreadStackSize=256 -XX:MaxMetaspaceSize=128m"}]' \
	-F fileupload=@${CHANNELS_FILE_PATH} -F isNewVersion=${NEW_VERSION} --progress-bar
}

echo "current directory: $PWD"

ls -la ${GITHUB_WORKSPACE}
ls -la ${GITHUB_WORKSPACE}/repository-api/
ls -la ${GITHUB_WORKSPACE}/repository-api/channels
ls -la ${GITHUB_WORKSPACE}/repository-api/channels/target

appCloudLogin

uploadProductsMS
uploadUpdatesMS
uploadSubscriptionMS
uploadChannelsMS

appCloudLogout
exit 0
