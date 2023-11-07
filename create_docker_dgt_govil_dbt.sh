#!/bin/bash
#me-west1-docker.pkg.dev/dgt-gcp-egov-test-govilbi-0/bi-team
export ProjectNameGCP=$(gcloud config get-value project) #Example: dgt-gcp-egov-test-govilbi-0
export Dbt_project_Name=dgt_govil_dbt
export Test_ProjectNameGCP=dgt-gcp-egov-test-govilbi-0
export Prod_ProjectNameGCP=dgt-gcp-egov-prod-govilbi-0
export registry_ProjectName=dgt-gcp-egov-registry-0 #to be deleted
export userName=$(gcloud config list account --format "value(core.account)")
export userName=$(cut -d "@" -f1 <<< "$userName")
export test_composer_environmentName=composer-dgt-gcp-egov-test-govilbi-2 #compserName
export prod_composer_environmentName=composer-dgt-gcp-egov-prod-govilbi-2 #compserName change name!!!????
export composer_environmentName
# export LOCATION=europe-west3 #to be deleted
echo $userName
export DIRECTORY_REPO=govil_airflow_k8_dbt

export test_gcs_composer=me-west1-composer-dgt-gcp-e-40315794-bucket
export prod_gcs_composer=me-west1-composer-dgt-gcp-e-40315794-bucket #change name!!!????
export gcs_composer
export Dag_DBT_Name=dgt_airflow_k8_dbt.py
export dag_config_name=config_dgt_airflow_k8_dbt.json
# export artifact_registry=me-west1-docker.pkg.dev
export artifact_registry=me-west1-docker.pkg.dev
# export artifact_registry=eu.gcr.io #//1.0.4
export doker_repository_name=dataops-doker-dbt-repo
echo create docker for $Dbt_project_Name
echo "creator: Gil Kal"

cd /home/$userName/projects/

echo $ProjectNameGCP
echo $Test_ProjectNameGCP
echo $Prod_ProjectNameGCP
echo DIRECTORY_REPO is: $DIRECTORY_REPO

# Check name $ProjectNameGCP and conig variables Prod or Test

case $ProjectNameGCP in
	$Test_ProjectNameGCP)
		echo 1111 "- Test Env " $ProjectNameGCP
		export composer_environmentName=$test_composer_environmentName
		export gcs_composer=$test_gcs_composer
   ;;
	$Prod_ProjectNameGCP)
		echo 2222 "- Prod Env " $ProjectNameGCP
		export composer_environmentName=$prod_composer_environmentName
		export gcs_composer=$prod_gcs_composer
   ;;
esac

echo "The project name " $ProjectNameGCP " and composer name: " $composer_environmentName


# Check the $DIRECTORY_REPO is exists and delete Directory
if [ -d "$DIRECTORY_REPO" ]; then
  echo "$DIRECTORY_REPO does exist."
  rm -rf $DIRECTORY_REPO
  echo "$DIRECTORY_REPO as deleted."
fi

# git
git clone https://github.com/gilc86/$DIRECTORY_REPO.git
echo "clone success"

# docker
cd /home/$userName/projects/$DIRECTORY_REPO
echo $DEVSHELL_PROJECT_ID
export PROJECT_ID=$DEVSHELL_PROJECT_ID
export Tag_Version=$(git describe --tags --abbrev=0)
######################################

#GCS
echo copy Dag file to gcs composer:  $gcs_composer
gsutil cp /home/$userName/projects/$DIRECTORY_REPO/dags/ gs://$gcs_composer/dags/

echo copy config json Dag file to gcs
echo $Tag_Version
export tmp=$(mktemp)
jq '."Tag_Version" = "'"$Tag_Version"'"' /home/$userName/projects/$DIRECTORY_REPO/dags/$dag_config_name > "$tmp" && mv "$tmp" /home/$userName/projects/$DIRECTORY_REPO/dags/$dag_config_name
jq '."artifact_registry" = "'"$artifact_registry"'"' /home/$userName/projects/$DIRECTORY_REPO/dags/$dag_config_name > "$tmp" && mv "$tmp" /home/$userName/projects/$DIRECTORY_REPO/dags/$dag_config_name
jq '."Dbt_project_Name" = "'"$Dbt_project_Name"'"' /home/$userName/projects/$DIRECTORY_REPO/dags/$dag_config_name > "$tmp" && mv "$tmp" /home/$userName/projects/$DIRECTORY_REPO/dags/$dag_config_name
gsutil cp /home/$userName/projects/$DIRECTORY_REPO/dags/$dag_config_name gs://$gcs_composer/dags/

################################################################################

# gcloud config set project $registry_ProjectName #Change project
# echo Change config project: $registry_ProjectName
docker build . -f ./dbt/Dockerfile -t $artifact_registry/$ProjectNameGCP/$doker_repository_name/$Dbt_project_Name:latest
# docker build . -f ./dbt/Dockerfile -t me-west1-docker.pkg.dev/$ProjectNameGCP/bi-team/$Dbt_project_Name:latest #//1.0.6
# docker build . -f ./dbt/Dockerfile -t $artifact_registry/$registry_ProjectName/bi-team/$ProjectNameGCP/$Dbt_project_Name:latest
# docker build . -f ./dbt/Dockerfile -t $artifact_registry/$ProjectNameGCP/bi-team/$Dbt_project_Name:latest
# docker build . -f ./dbt/Dockerfile -t me-west1-docker.pkg.dev/dgt-gcp-egov-prod-govilbi-0/bi-team/

echo docker build success from: $DIRECTORY_REPO

docker images

echo $Tag_Version
# docker tag \
# $artifact_registry/$registry_ProjectName/$ProjectNameGCP/$Dbt_project_Name \
# $artifact_registry/$registry_ProjectName/$ProjectNameGCP/$Dbt_project_Name:$Tag_Version


docker tag \
$artifact_registry/$ProjectNameGCP/$doker_repository_name/$Dbt_project_Name \
$artifact_registry/$ProjectNameGCP/$doker_repository_name/$Dbt_project_Name:$Tag_Version

# echo $Tag_Version
# docker tag \
# $artifact_registry/$ProjectNameGCP/bi-team/$Dbt_project_Name \
# $artifact_registry/$ProjectNameGCP/bi-team/$Dbt_project_Name:$Tag_Version


# docker tag eu.gcr.io/$PROJECT_ID/$Dbt_project_Name \eu.gcr.io/$PROJECT_ID/$Dbt_project_Name:$Tag_Version
docker images

echo image docker tag is: $Tag_Version

# docker push $artifact_registry/$registry_ProjectName/bi-team/$ProjectNameGCP/$Dbt_project_Name:$Tag_Version
# docker push $artifact_registry/$ProjectNameGCP/bi-team/$Dbt_project_Name:$Tag_Version         
# docker push $artifact_registry/$ProjectNameGCP/bi-team/$Dbt_project_Name:$Tag_Version         
docker push $artifact_registry/$ProjectNameGCP/$doker_repository_name/$Dbt_project_Name:$Tag_Version #//1.1.2
echo push to docker $Tag_Version success.
#echo path push: $artifact_registry/$ProjectNameGCP/bi-team/$ProjectNameGCP/$Dbt_project_Name:$Tag_Version
echo path push: $artifact_registry/$ProjectNameGCP/$doker_repository_name/$Dbt_project_Name:$Tag_Version       

# gcloud config set project $ProjectNameGCP
# echo Change config project: $ProjectNameGCP


#Composer2
# gcloud composer environments update $composer_environmentName \
#   --location $LOCATION \
#   --update-env-variables=DGT_AIRFLOW_DBT_TAG=$Tag_Version
  
# export ProjectNameGCP=dgt-gcp-egov-test-govilbi-0
# export Tag_Version=1.0.2
# export artifact_registry=me-west1-docker.pkg.dev
# export Dbt_project_Name=dgt_govil_dbt
# 
# cd /home/gilc/projects/govil_airflow_k8_dbt
# docker build . -f ./dbt/Dockerfile -t me-west1-docker.pkg.dev/dgt-gcp-egov-prod-govilbi-0/bi-team/dgt_govil_dbt:latest
# docker tag me-west1-docker.pkg.dev/dgt-gcp-egov-prod-govilbi-0/bi-team/dgt_govil_dbt \me-west1-docker.pkg.dev/dgt-gcp-egov-prod-govilbi-0/bi-team/dgt_govil_dbt:1.0.0
# docker push me-west1-docker.pkg.dev/dgt-gcp-egov-prod-govilbi-0/bi-team/dgt_govil_dbt:1.0.0
# docker push me-west1-docker.pkg.dev/dgt-gcp-egov-test-govilbi-0/bi-team/dgt_govil_dbt:1.0.2
# gcloud config set project dgt-gcp-egov-registry-0



