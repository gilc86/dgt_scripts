#!/bin/bash
echo "create docker for dgt_govil_dbt"
echo "creator: Gil Kal"

cd /home/gilc/projects/

# Check the $DIRECTORY_REPO is exists and delete
DIRECTORY_REPO='govil_airflow_k8_dbt'
if [ -d "$DIRECTORY_REPO" ]; then
  echo "$DIRECTORY_REPO does exist."
  rm -rf $DIRECTORY_REPO
  echo "$DIRECTORY_REPO as deleted."
fi

# git
git clone https://github.com/gilc86/govil_airflow_k8_dbt.git
echo "clone success"

# docker
echo $DEVSHELL_PROJECT_ID
export PROJECT_ID=$DEVSHELL_PROJECT_ID

docker build . -f ./dbt/Dockerfile -t eu.gcr.io/$PROJECT_ID/dgt_govil_dbt:latest

