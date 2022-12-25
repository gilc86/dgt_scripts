#!/bin/bash
export Dbt_project_Name=dgt_govil_dbt
export userName=$(gcloud config list account --format "value(core.account)")
export userName=$(cut -d "@" -f1 <<< "$userName")
echo $userName
DIRECTORY_REPO='govil_airflow_k8_dbt'

echo create docker for $Dbt_project_Name
echo "creator: Gil Kal"

cd /home/$userName/projects/

# Check the $DIRECTORY_REPO is exists and delete

if [ -d "$DIRECTORY_REPO" ]; then
  echo "$DIRECTORY_REPO does exist."
  rm -rf $DIRECTORY_REPO
  echo "$DIRECTORY_REPO as deleted."
fi

# git
# git clone https://github.com/gilc86/$DIRECTORY_REPO.git
git clone https://gilc86:gil300202@github.com/gilc86/$DIRECTORY_REPO.git
echo "clone success"

# docker
cd /home/$userName/projects/$DIRECTORY_REPO
echo $DEVSHELL_PROJECT_ID
export PROJECT_ID=$DEVSHELL_PROJECT_ID

docker build . -f ./dbt/Dockerfile -t eu.gcr.io/$PROJECT_ID/$Dbt_project_Name:latest

echo docker build success from $DIRECTORY_REPO

docker images

export Tag_Version=$(git describe --tags --abbrev=0)

echo $Tag_Version

docker tag eu.gcr.io/$PROJECT_ID/$Dbt_project_Name \eu.gcr.io/$PROJECT_ID/$Dbt_project_Name:$Tag_Version
docker images

echo image docker tag is: $Tag_Version

docker push eu.gcr.io/$PROJECT_ID/$Dbt_project_Name:$Tag_Version

echo push to docker $Tag_Version success.

echo container images describe eu.gcr.io/$PROJECT_ID/$Dbt_project_Name:$Tag_Version







