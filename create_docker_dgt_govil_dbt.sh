#!/bin/bash
export ProjectNameGCP=$(gcloud config get-value project)# Example: dgt-gcp-egov-test-govilbi-0
export Dbt_project_Name=dgt_govil_dbt
export Test_ProjectNameGCP=dgt-gcp-egov-test-govilbi-0
export Prod_ProjectNameGCP=dgt-gcp-egov-prod-govilbi-0
export userName=$(gcloud config list account --format "value(core.account)")
export userName=$(cut -d "@" -f1 <<< "$userName")
export test_composer_environmentName=composer-dgt-gcp-egov-test-govilbi-2 #compserName
export prod_composer_environmentName=composer-dgt-gcp-egov-prod-govilbi-2 #compserName change name!!!????
export composer_environmentName
export LOCATION=europe-west3
echo $userName
export DIRECTORY_REPO=govil_airflow_k8_dbt

export test_gcs_composer=europe-west3-composer-dgt-g-97f74c13-bucket
export prod_gcs_composer=europe #change name!!!????
export gcs_composer
export Dag_DBT_Name=dgt_airflow_k8_dbt.py

echo create docker for $Dbt_project_Name
echo "creator: Gil Kal"

cd /home/$userName/projects/

# Check name $ProjectNameGCP and conig variables Prod or Test
case $ProjectNameGCP in
	$Test_ProjectNameGCP) 
	$composer_environmentName=$test_composer_environmentName
	$gcs_composer=$test_gcs_composer
   ;;
	$Prod_ProjectNameGCP) 
	$composer_environmentName=$test_composer_environmentName
	$gcs_composer=$test_gcs_composer
   ;;
esac

echo $ProjectNameGCP
echo $composer_environmentName
echo "The project name " $ProjectNameGCP " and composer name: " $composer_environmentName
echo "the composer name is: $composer_environmentName"
echo $composer_environmentName

# Check the $DIRECTORY_REPO is exists and delete Directory
if [ -d "$DIRECTORY_REPO" ]; then
  echo "$DIRECTORY_REPO does exist."
  rm -rf $DIRECTORY_REPO
  echo "$DIRECTORY_REPO as deleted."
fi

# git
git clone https://github.com/gilc86/$DIRECTORY_REPO.git
# git clone https://gilc86:gil300202@github.com/gilc86/$DIRECTORY_REPO.git
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

#GCS
echo copy Dag file to gcs
gsutil cp /home/$userName/projects/$DIRECTORY_REPO/dags/$Dag_DBT_Name gs://$gcs_composer/dags/
#Composer2
gcloud composer environments update $composer_environmentName \
  --location $LOCATION \
  --update-env-variables=DGT_AIRFLOW_DBT_TAG=$Tag_Version



