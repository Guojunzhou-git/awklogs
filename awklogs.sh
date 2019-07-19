#!/bin/bash

awklogs_params_log_type=''
awklogs_params_log_file=''
awklogs_params_ana_field=''
awklogs_params_filter_timestamp_start=0
awklogs_params_filter_timestamp_end=0
awklogs_params_filter_request_uri=''
os_platform=`uname -s`

# parse awklogs prams into var
parse_awklogs_params(){
    for i in $* ;
    do
        if [ $(echo $i | cut -c1-10) == '--log_type' ] ; then
            awklogs_params_log_type=${i#--log_type=}
        elif [ $(echo $i | cut -c1-10) == '--log_file' ] ; then
            awklogs_params_log_file=${i#--log_file=}
        elif [ $(echo $i | cut -c1-16) == '--analysis_field' ] ; then
            awklogs_params_ana_field=${i#--analysis_field=}
        elif [ $(echo $i | cut -c1-24) == '--filter_timestamp_start' ] ; then
            awklogs_params_filter_timestamp_start=${i#--filter_timestamp_start=}
        elif [ $(echo $i | cut -c1-22) == '--filter_timestamp_end' ] ; then
            awklogs_params_filter_timestamp_end=${i#--filter_timestamp_end=}
        elif [ $(echo $i | cut -c1-20) == '--filter_request_uri' ] ; then
            awklogs_params_filter_request_uri=${i#--filter_request_uri=}
        elif [ $(echo $i | cut -c1-23) == '--filter_datetime_start' ] ; then
            if [[ "${os_platform}" = "Darwin" ]];then
                awklogs_params_filter_timestamp_start=`date -j -f "%Y-%m-%d_%H:%M:%S" ${i#--filter_datetime_start=} +%s`
            elif [[ "${os_platform}" = "Linux" ]];then
                awklogs_params_filter_timestamp_start=`date -d "${i#--filter_datetime_start=}" +%s`
            fi
        elif [ $(echo $i | cut -c1-21) == '--filter_datetime_end' ] ; then
            if [[ "${os_platform}" = "Darwin" ]];then
                awklogs_params_filter_timestamp_end=`date -j -f "%Y-%m-%d_%H:%M:%S" ${i#--filter_datetime_end=} +%s`
            elif [[ "${os_platform}" = "Linux" ]];then
                awklogs_params_filter_timestamp_end=`date -d "${i#--filter_datetime_end=}" +%s`
            fi
        fi
    done
}

# echo usage of awklogs
echo_usage_of_awklogs(){
    echo -e 'Usage: awklogs [--option=value] [...]'
    echo -e '\t--log_type'
    echo -e '\t\tnginx.access\t\tanalysis nginx.access.log'
    echo -e '\t\tjson\t\t\tanalysis json format file'
    echo -e '\t--log_file'
    echo -e '\t\t/path/to/xxx.log\tinput path of log file'
    echo -e '\t--analysis_field'
    echo -e '\t\trequest_uri\t\tanalysis access.log file based on request_uri field, give result of:'
    echo -e '\t\t\t\t\t- 1. how many request every uri makes'
    echo -e '\t\t\t\t\t- 2. how many request with every http code'
    echo -e '\t\t\t\t\t- 3. request_time time_range with every http_code'
    echo -e '\t\tremote_addr\t\tanalysis access.log file based on remote_addr field, give result of:'
    echo -e '\t\t\t\t\t- 1. how many remote_addr have sent request'
    echo -e '\t\t\t\t\t- 2. how many request every remote_addr makes'
    echo -e '\t\t\t\t\t- 3. how many bytes every remote_addr used'
    echo -e '\t\ttime_local\t\tanalysis access.log file based on time_local field, give result of:'
    echo -e '\t\t\t\t\t- 1. how many request every second makes(concurrency)'
    echo -e '\t\t\t\t\t- 2. when comes the top N concurrency'
    echo -e '\t\t\t\t\t- 3. QPS of every seconds'
    echo -e '\t\txxx\t\t\tanalysis json format file, analysis_field need to be given'
    echo -e '\t--filter_timestamp_start\t\tadd rows filter time_local start, timestamp like 1500000000'
    echo -e '\t--filter_timestamp_end\t\tadd rows filter time_local end, timestamp like 1500000000,'
    echo -e '\t\t\t\t\tignored when timestamp_end < timestamp_start'
    echo -e '\t--filter_datetime_start\t\tadd rows filter time_local start, datetime with format "%Y-%m-%d_%H:%M:%S" like 2019-01-01_01:01:01'
    echo -e '\t--filter_datetime_end\t\tadd rows filter time_local end, datetime with format "%Y-%m-%d_%H:%M:%S" like 2019-01-01_01:01:01,'
    echo -e '\t\t\t\t\tignored when datetime_end < datetime_start'
    echo -e '\t--filter_request_uri\t\tonly analysis the special REQUEST_URI'
    exit 0
}

# check common necessary params
check_necessary_params(){
    if [ -z $awklogs_params_log_type ] || ([ $awklogs_params_log_type != 'nginx.access' ] && [ $awklogs_params_log_type != 'json' ]) ; then
        echo -e 'error: log_type='$awklogs_params_log_type' is not supported.'
        exit 1
    fi
    if [ -z $awklogs_params_log_file ] || [ ! -f $awklogs_params_log_file ] ; then
        echo -e 'error: log_file='$awklogs_params_log_file' is not an exists file.'
        exit 1
    fi
    if [ $awklogs_params_filter_timestamp_end -gt 0 ] && [ $awklogs_params_filter_timestamp_end -lt $awklogs_params_filter_timestamp_start ] ; then
        echo -e 'warning: timestamp_end=['$awklogs_params_filter_timestamp_end'] is less then timestamp_start=['$awklogs_params_filter_timestamp_start'], ignored time_end.'
        awklogs_params_filter_timestamp_end=0
    fi
    if [ -z $awklogs_params_ana_field ] ; then
        echo -e 'warning: no analysis_field given, nothing to do.'
        exit 0
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
if [ $awklogs_params_log_type == "nginx.access" ] ; then
    awk -v analysis_field=$awklogs_params_ana_field \
        -v filter_timestamp_start=$awklogs_params_filter_timestamp_start \
        -v filter_timestamp_end=$awklogs_params_filter_timestamp_end \
        -v filter_request_uri=$awklogs_params_filter_request_uri \
        -F '"' -f awk/nginx_access.awk $awklogs_params_log_file
fi
if [ $awklogs_params_log_type == "json" ] ; then
    awk -v analysis_field=$awklogs_params_ana_field \
        -v filter_timestamp_start=$awklogs_params_filter_timestamp_start \
        -v filter_timestamp_end=$awklogs_params_filter_timestamp_end \
        -v filter_request_uri=$awklogs_params_filter_request_uri \
        -F '"' -f awk/json.awk -f awk/json_cb.awk $awklogs_params_log_file
fi