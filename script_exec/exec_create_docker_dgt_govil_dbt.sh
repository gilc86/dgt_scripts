#!/bin/bash
echo " exec create docker for dgt_govil_dbt"
echo "creator: Gil Kal"

cd /home/gilc/projects/

# Check the $DIRECTORY_REPO is exists and delete
DIRECTORY_REPO='dgt_scripts'
if [ -d "$DIRECTORY_REPO" ]; then
  echo "$DIRECTORY_REPO does exist."
  rm -rf $DIRECTORY_REPO
  echo "$DIRECTORY_REPO as deleted."
  git clone https://github.com/gilc86/$DIRECTORY_REPO.git
  echo "clone success dgt_scripts"
fi

cd /$DIRECTORY_REPO

chmod u+x create_docker_dgt_govil_dbt.sh
./create_docker_dgt_govil_dbt.sh



