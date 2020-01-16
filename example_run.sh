mkdir lists

python scripts/prepare_lists.py

echo "###################################### eval xvector logs LA #########################################" >> eval_la_logs
echo "###################################### dev xvector logs LA #########################################" >> dev_la_logs

bash scripts/wrapper_devData_asv2019.sh lfcc 21 1 1 0 1 1024 512 50 0 LA la_logs ## see .sh file for detials


echo "###################################### eval xvector logs PA #########################################" >> eval_pa_logs
echo "###################################### dev xvector logs PA #########################################" >> dev_pa_logs

bash scripts/wrapper_devData_asv2019.sh lfcc 21 1 1 0 1 1024 512 50 0 PA pa_logs

