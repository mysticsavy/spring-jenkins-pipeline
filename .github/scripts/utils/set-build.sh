#!/usr/bin/env bash

# -------------------------------------- Environment Variables --------------------------------------
# GITHUB_WORKSPACE - The GitHub workspace directory path
# BUILD_NUMBER - GitHub Actions build number
# -------------------------------------- Environment Variables --------------------------------------

REPOSITORY_API=${GITHUB_WORKSPACE}/repository-api
CHANNELS_MS=${REPOSITORY_API}/channels
FILES_MS=${REPOSITORY_API}/files
PRODUCTS_MS=${REPOSITORY_API}/products
SUBSCRIPTIONS_MS=${REPOSITORY_API}/subscriptions
UPDATES_MS=${REPOSITORY_API}/updates

PROJECT_VERSION="$(xmlstarlet select -N x=http://maven.apache.org/POM/4.0.0 -t -v "/x:project/x:version" ${GITHUB_WORKSPACE}/pom.xml)"
BUILD_VERSION=${PROJECT_VERSION}-${BUILD_NUMBER}

# Update project version with build number
xmlstarlet edit -N x=http://maven.apache.org/POM/4.0.0 -u "/x:project/x:version" -v ${BUILD_VERSION} ${GITHUB_WORKSPACE}/pom.xml > ${GITHUB_WORKSPACE}/pom.xml.new
mv ${GITHUB_WORKSPACE}/pom.xml.new ${GITHUB_WORKSPACE}/pom.xml

function update_parent_child_versions() {
  xmlstarlet edit -N x=http://maven.apache.org/POM/4.0.0 -u "/x:project/x:parent/x:version" -v ${BUILD_VERSION} ${1}/pom.xml > ${1}/pom.xml.new
  mv ${1}/pom.xml.new ${1}/pom.xml
  xmlstarlet edit -N x=http://maven.apache.org/POM/4.0.0 -u "/x:project/x:version" -v ${BUILD_VERSION} ${1}/pom.xml > ${1}/pom.xml.new
  mv ${1}/pom.xml.new ${1}/pom.xml
}

update_parent_child_versions ${REPOSITORY_API}
update_parent_child_versions ${CHANNELS_MS}
update_parent_child_versions ${FILES_MS}
update_parent_child_versions ${PRODUCTS_MS}
update_parent_child_versions ${SUBSCRIPTIONS_MS}
update_parent_child_versions ${UPDATES_MS}
