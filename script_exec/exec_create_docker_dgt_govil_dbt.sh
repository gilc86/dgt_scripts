#!/bin/bash
echo " exec create docker for dgt_govil_dbt"
echo "creator: Gil Kal"
export DIRECTORY_REPO=govil_airflow_k8_dbt
git clone https://github.com/gilc86/$DIRECTORY_REPO.git 
export userName=$(gcloud config list account --format "value(core.account)")
export userName=$(cut -d "@" -f1 <<< "$userName")
echo Name of user: $userName

mkdir -p /home/$userName/projects/script_exec
cp /home/$userName/projects/dgt_scripts/script_exec/exec_create_docker_dgt_govil_dbt.sh /home/$userName/projects/script_exec
cd /home/$userName/projects/script_exec/
chmod u+x exec_create_docker_dgt_govil_dbt.sh

cd /home/$userName/projects/

# Check the $DIRECTORY_REPO is exists and delete
DIRECTORY_REPO='dgt_scripts'
if [ -d "$DIRECTORY_REPO" ]; then
  echo "$DIRECTORY_REPO does exist."
  rm -rf $DIRECTORY_REPO
  echo "$DIRECTORY_REPO as deleted."
  git clone https://github.com/gilc86/$DIRECTORY_REPO.git
  echo "clone success dgt_scripts"
fi

cd /home/$userName/projects/script_exec/
chmod u+x exec_create_docker_dgt_govil_dbt.sh

cd /home/$userName/projects/$DIRECTORY_REPO
chmod u+x create_docker_dgt_govil_dbt.sh
./create_docker_dgt_govil_dbt.sh



