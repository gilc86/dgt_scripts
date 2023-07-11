cd \
cd projects/
rm -r -f govil_onperm_to_cloud/
git clone https://github.com/gilc86/govil_onperm_to_cloud.git
cd govil_onperm_to_cloud/BigQuery/
docker build ./dockertest2 -t eu.gcr.io/dgt-gcp-egov-test-govilbi-0/dataops/incremental_load_hw_jsons:1.0.0