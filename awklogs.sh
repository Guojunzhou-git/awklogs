#!/bin/bash

awklogs_params_log_type=''
awklogs_params_log_file=''
awklogs_params_ana_action=''
awklogs_params_output_limit=10

# parse awklogs prams into var
parse_awklogs_params(){
    for i in $* ;
    do
        if [ $(echo $i | cut -c1-10) == '--log_type' ] ; then
            awklogs_params_log_type=${i#--log_type=}
        elif [ $(echo $i | cut -c1-10) == '--log_file' ] ; then
            awklogs_params_log_file=${i#--log_file=}
        elif [ $(echo $i | cut -c1-12) == '--ana_action' ] ; then
            awklogs_params_ana_action=${i#--ana_action=}
        elif [ $(echo $i | cut -c1-14) == '--output_limit' ] ; then
            awklogs_params_output_limit=${i#--output_limit=}
        fi
    done
}

# echo usage of awklogs
echo_usage_of_awklogs(){
    echo -e 'Usage: awklogs [--option=value] [...]'
    echo -e '\t--log_type'
    echo -e '\t\tnginx.access\t\tanalysis nginx.access.log'
    echo -e '\t\tnginx.error\t\tanalysis nginx.error.log'
    echo -e '\t--log_file'
    echo -e '\t\t/path/to/xxx.log\tinput path of log file'
    echo -e '\t--ana_action'
    echo -e '\t\tremote_addr_count\toutput how many requests every remote_addr makes'
    echo -e '\t\tremote_addr_bytes_sum\toutput how many bytes every remote_addr used'
    echo -e '\t\trequest_uri_count\toutput how many times every uri been requested'
    echo -e '\t--output_limit'
    echo -e '\t\t10\t\t\thow many result output, default 10'
    exit 0
}

# check common necessary params
check_necessary_params(){
    if [ -z $awklogs_params_log_type ] || ([ $awklogs_params_log_type != 'nginx.access' ] && [ $awklogs_params_log_type != 'nginx.error' ]) ; then
        echo -e 'error: log_type='$awklogs_params_log_type' is not supported.'
        exit 1
    fi
    if [ -z $awklogs_params_log_file ] || [ ! -f $awklogs_params_log_file ] ; then
        echo -e 'error: log_file='$awklogs_params_log_file' is not an exists file.'
        exit 1
    fi
}
# echo usage if no prams given, or prase params
if [ $# == 0 ] ; then
    echo_usage_of_awklogs
else
    parse_awklogs_params $*
fi

# check whether common necessary params are given
check_necessary_params

# run analysis
if [ -z $awklogs_params_ana_action ] ; then
    echo -e 'error: ana_action='$awklogs_params_ana_action' is not supportrd.'
    exit 1
elif [ $awklogs_params_ana_action == 'remote_addr_count' ] ; then
    echo -e "---------------------\nremote_addr\tcount\n---------------------"
    awk -F '"' '{split($1, rbarr, " ");split($2, reqarr, " ");split($3, hrbarr, " ");row["remote_addr"]=rbarr[1];row["remote_user"]=rbarr[3];row["time_local"]=rbarr[4]" "rbarr[5];row["request_method"]=reqarr[1];row["request_uri"]=reqarr[2];row["request_scheme"]=reqarr[3];row["status"]=hrbarr[1];row["body_bytes_sent"]=hrbarr[2];row["http_referer"]=$4;row["http_user_agent"]=$6;row["http_x_forwarded_for"]=$8;row["upstream_response_time"]=$10;row["request_time"]=$12;remote_addr_arr[row["remote_addr"]]++;}END{for(k in remote_addr_arr){ print k"\t"remote_addr_arr[k];}}' $awklogs_params_log_file | sort -n -r -k 2 | head -n $awklogs_params_output_limit
elif [ $awklogs_params_ana_action == 'request_uri_count' ] ; then
    echo -e "---------------------\nrequest_uri\tcount\n---------------------"
    awk -F '"' '{split($1, rbarr, " ");split($2, reqarr, " ");split($3, hrbarr, " ");row["remote_addr"]=rbarr[1];row["remote_user"]=rbarr[3];row["time_local"]=rbarr[4]" "rbarr[5];row["request_method"]=reqarr[1];row["request_uri"]=reqarr[2];row["request_scheme"]=reqarr[3];row["status"]=hrbarr[1];row["body_bytes_sent"]=hrbarr[2];row["http_referer"]=$4;row["http_user_agent"]=$6;row["http_x_forwarded_for"]=$8;row["upstream_response_time"]=$10;row["request_time"]=$12;request_uri[row["request_uri"]]++;}END{for(k in request_uri){ print k"\t"request_uri[k];}}' $awklogs_params_log_file | sort -n -r -k 2 | head -n $awklogs_params_output_limit
elif [ $awklogs_params_ana_action == 'remote_addr_bytes_sum' ] ; then
    echo -e "------------------------------------------------------\nremote_addr_bytes\tbytes_sum\thuman_sum\n------------------------------------------------------"
    awk -F '"' '{split($1, rbarr, " ");split($2, reqarr, " ");split($3, hrbarr, " ");row["remote_addr"]=rbarr[1];row["remote_user"]=rbarr[3];row["time_local"]=rbarr[4]" "rbarr[5];row["request_method"]=reqarr[1];row["request_uri"]=reqarr[2];row["request_scheme"]=reqarr[3];row["status"]=hrbarr[1];row["body_bytes_sent"]=hrbarr[2];row["http_referer"]=$4;row["http_user_agent"]=$6;row["http_x_forwarded_for"]=$8;row["upstream_response_time"]=$10;row["request_time"]=$12;remote_addr_bytes_sum[row["remote_addr"]]+=row["body_bytes_sent"];}END{for(k in remote_addr_bytes_sum){if(remote_addr_bytes_sum[k]<1024){print k"\t\t"remote_addr_bytes_sum[k]"\t"remote_addr_bytes_sum[k]" B";}else if(remote_addr_bytes_sum[k]<1024*1024){print k"\t\t"remote_addr_bytes_sum[k]"\t\t"remote_addr_bytes_sum[k]/1024" KB";}else if(remote_addr_bytes_sum[k]<1024*1024*1024){print k"\t\t"remote_addr_bytes_sum[k]"\t"remote_addr_bytes_sum[k]/1024/1024" MB";}else{print k"\t\t"remote_addr_bytes_sum[k]"\t"remote_addr_bytes_sum[k]/1024/1024/1024" GB";}}}' $awklogs_params_log_file | sort -n -r -k 2 | head -n $awklogs_params_output_limit
fi
# log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
#                   '$status $body_bytes_sent "$http_referer" '
#                   '"$http_user_agent" "$http_x_forwarded_for" "$upstream_response_time" "$request_time"';
