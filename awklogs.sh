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
    # echo -e '\t\tnginx.error\t\tanalysis nginx.error.log'
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
    if [ -z $awklogs_params_log_type ] || ([ $awklogs_params_log_type != 'nginx.access' ] && [ $awklogs_params_log_type != 'nginx.error' ]) ; then
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
awk -v analysis_field=$awklogs_params_ana_field \
    -v filter_timestamp_start=$awklogs_params_filter_timestamp_start \
    -v filter_timestamp_end=$awklogs_params_filter_timestamp_end \
    -v filter_request_uri=$awklogs_params_filter_request_uri \
    -F '"' '
    BEGIN{
        SUBSEP = "|"
        begin_time_range["0_100"] = 1;
        begin_time_range["100_200"] = 1;
        begin_time_range["200_500"] = 1;
        begin_time_range["500_1000"] = 1;
        begin_time_range["1000_200"] = 1;
        begin_time_range["2000_infinite"] = 1;
        begin_analysis_rows = 0;
        analysis_start_time = systime();
    }
    {
        split($1, rbarr, " ");
        split($2, reqarr, " ");
        split($3, hrbarr, " ");
        row["remote_addr"] = rbarr[1];
        row["remote_user"] = rbarr[3];
        row["time_local"] = rbarr[4]" "rbarr[5];
        row["request_method"] = reqarr[1];
        row["request_uri"] = reqarr[2];
        row["request_scheme"] = reqarr[3];
        row["status"] = hrbarr[1];
        row["body_bytes_sent"] = hrbarr[2];
        row["http_referer"] = $4;
        row["http_user_agent"] = $6;
        row["http_x_forwarded_for"] = $8;
        row["upstream_response_time"] = $10;
        row["request_time"] = $12;
        qm_index = index(row["request_uri"], "?");
        if(qm_index > 0){
            row["request_uri"] = substr(row["request_uri"], 1, qm_index-1);
        }
        # default pass filter
        row_filtered = 0;
        if(filter_timestamp_start !=0 || filter_timestamp_end != 0){
            row_timestamp = timelocal_2_timestamp(substr(row["time_local"], 2, length(row["time_local"])-1));
            # if filter_timestamp_start is set and row_timestamp is lt filter_timestamp_start, row_filtered = 1
            if(row_filtered == 0 && filter_timestamp_start > 0 && row_timestamp < filter_timestamp_start){
                row_filtered = 1;
            }
            # if filter_time_end is set and row_timestamp is gt filter_time_end, row_filtered = 1
            if(row_filtered == 0 && filter_timestamp_end > 0 && row_timestamp > filter_timestamp_end){
                row_filtered = 1;
            }
        }
        if(row_filtered == 0 && filter_request_uri && row["request_uri"] != filter_request_uri){
            row_filtered = 1;
        }
        if(row_filtered == 0){
            if(analysis_field == "time_local"){
                if(row_timestamp){
                    timestamp = row_timestamp;
                }else{
                    timestamp = timelocal_2_timestamp(substr(row["time_local"], 2, length(row["time_local"])-1));
                }
                if(timestamp != 0){
                    analysis_result["time_local_count", timestamp]++;
                    analysis_result["time_local_request_time_sum", timestamp] += row["request_time"] * 1000;
                }
            }
            if(analysis_field == "remote_addr"){
                analysis_result["remote_addr_count", row["remote_addr"]]++;
                analysis_result["remote_addr_bytes_sum", row["remote_addr"]]+=row["body_bytes_sent"];
            }
            if(analysis_field == "request_uri"){
                analysis_result["request_uri_count", row["request_uri"]]++;
                analysis_result["request_uri_status_count", row["request_uri"], row["status"]]++;
                row_request_time_ms = int(row["request_time"]*1000);
                if(row_request_time_ms < 100){
                    analysis_result["request_uri_request_time_range", row["request_uri"], row["status"], "0_100"]++;
                }else if(row_request_time_ms < 200){
                    analysis_result["request_uri_request_time_range", row["request_uri"], row["status"], "100_200"]++;
                }else if(row_request_time_ms < 500){
                    analysis_result["request_uri_request_time_range", row["request_uri"], row["status"], "200_500"]++;
                }else if(row_request_time_ms < 1000){
                    analysis_result["request_uri_request_time_range", row["request_uri"], row["status"], "500_1000"]++;
                }else if(row_request_time_ms < 2000){
                    analysis_result["request_uri_request_time_range", row["request_uri"], row["status"], "1000_2000"]++;
                }else{
                    analysis_result["request_uri_request_time_range", row["request_uri"], row["status"], "2000_infinite"]++;
                }
            }
            begin_analysis_rows++;
        }
    }
    END{
        analysis_end_time = systime();
        analysis_used_time = int(analysis_end_time-analysis_start_time);
        if(analysis_used_time == 0){
            analysis_used_time = "<1";
        }
        ORS = ""
        print begin_analysis_rows" rows analysised. "analysis_used_time" seconds used."
        if(begin_analysis_rows == 0){
            print "no result output."
        }
        ORS = "\n"
        print ""
        if(analysis_field == "time_local"){
            for(key in analysis_result){
                split(key, keyarr, SUBSEP);
                analysis_type = keyarr[1];
                timestamp = keyarr[2];
                if(analysis_type == "time_local_count"){
                    if(analysis_result[key] > 3){
                        time_local_count[timestamp] = analysis_result[key];
                    }
                }
                if(analysis_type == "time_local_request_time_sum"){
                    time_local_request_time_sum[timestamp] = analysis_result[key];
                }
            }
            count_len = sort_arr(time_local_count, time_local_count_sorted);
            if(count_len > 0){
                print "------------------------------------------------------------------";
                print "datetime\t\tconcurrency\tavg_time(ms)\tQPS";
                print "------------------------------------------------------------------";
                for(i=1; i<=count_len; ++i){
                    split(time_local_count_sorted[i], count_arr, ",");
                    ORS = ""
                    print strftime("%Y-%m-%d %H:%M:%S", count_arr[1])"\t"count_arr[2]"\t";
                    for(timestamp in time_local_request_time_sum){
                        if(timestamp == count_arr[1]){
                            avg_time = time_local_request_time_sum[timestamp]/count_arr[2];
                            print "\t"avg_time;
                            if(avg_time != 0){
                                print "\t\t"int(count_arr[2]/(avg_time/1000));
                            }else{
                                print "\t\t-"
                            }
                        }
                    }
                    ORS = "\n";
                    print "";
                }
            }
        }
        if(analysis_field == "remote_addr"){
            for(key in analysis_result){
                split(key, keyarr, SUBSEP);
                analysis_type = keyarr[1];
                remote_addr = keyarr[2];
                if(analysis_type == "remote_addr_count"){
                    if(analysis_result[key] > 3){
                        remote_addr_count[remote_addr] = analysis_result[key];
                    }
                }
                if(analysis_type == "remote_addr_bytes_sum"){
                    remote_addr_bytes_sum[remote_addr] = analysis_result[key];
                }
            }
            addr_len = sort_arr(remote_addr_count, remote_addr_count_sorted);
            if(addr_len > 0){
                print "----------------------------------------------------------"
                print "remote_addr\trequest\tbyte_sum\thuman_sum"
                print "----------------------------------------------------------"
                for(i=1; i<=addr_len; ++i){
                    split(remote_addr_count_sorted[i], addr_arr, ",");
                    ORS = ""
                    print addr_arr[1]"\t"addr_arr[2]"\t";
                    for(remote_addr in remote_addr_bytes_sum){
                        if(remote_addr == addr_arr[1]){
                            addr_bytes = remote_addr_bytes_sum[remote_addr];
                            if(addr_bytes<=99999999){
                                print addr_bytes"\t\t";
                            }else{
                                print addr_bytes"\t";
                            }
                            if(addr_bytes < 1024){
                                print addr_bytes" B\t";
                            }else if(addr_bytes < 1024*1024){
                                print addr_bytes/1024" KB\t";
                            }else if(addr_bytes < 1024*1024*1024){
                                print addr_bytes/1024/1024" MB\t";
                            }else{
                                print addr_bytes/1024/1024/1024" GB\t";
                            }
                        }
                    }
                    ORS = "\n";
                    print "";
                }
            }
        }
        if(analysis_field == "request_uri"){
            for(key in analysis_result){
                split(key, keyarr, SUBSEP);
                analysis_type = keyarr[1];
                request_uri = keyarr[2];
                if(analysis_type == "request_uri_count"){
                    if(analysis_result[key] > 3){
                        request_uri_count[request_uri] = analysis_result[key];
                    }
                }
                if(analysis_type == "request_uri_status_count"){
                    status = keyarr[3];
                    request_uri_status_count[request_uri, status] = analysis_result[key];
                }
                if(analysis_type == "request_uri_request_time_range"){
                    status = keyarr[3];
                    time_range = keyarr[4];
                    request_uri_request_time_range[request_uri, status, time_range] = analysis_result[key];
                }
            }
            uri_number = sort_arr(request_uri_count, request_uri_count_sorted);
            if(uri_number){
                print "----------------------------------------------------------------------------------------------------------------"
                print "request_uri\t\t\ttotal\tstatus\tcount\t<100ms\t<200ms\t<500ms\t<1000ms\t<2000ms\t>2000ms"
                print "----------------------------------------------------------------------------------------------------------------"
                for(i=1; i<=uri_number; ++i){
                    split(request_uri_count_sorted[i], sorted_value_arr, ",");
                    request_uri = sorted_value_arr[1];
                    if(length(request_uri) < 8){
                        print request_uri"\t\t\t\t"sorted_value_arr[2];
                    }else if(length(request_uri) < 16){
                        print request_uri"\t\t\t"sorted_value_arr[2];
                    }else if(length(request_uri) < 24){
                        print request_uri"\t\t"sorted_value_arr[2];
                    }else if(length(request_uri) < 32){
                        print request_uri"\t"sorted_value_arr[2];
                    }else{
                        print substr(request_uri, 1, 28)"...\t"sorted_value_arr[2];
                    }
                    for(k in request_uri_status_count){
                        split(k, karr, SUBSEP);
                        if(karr[1] == request_uri){
                            ORS = ""
                            print "\t\t\t\t\t"karr[2]"\t"request_uri_status_count[k]"\t";
                            for(kk in request_uri_request_time_range){
                                split(kk, kkarr, SUBSEP);
                                if(kkarr[1] == request_uri && kkarr[2] == karr[2]){
                                    time_range = kkarr[3];
                                    row_uri_time_range_data[time_range] = request_uri_request_time_range[kk];
                                }
                            }
                            for(tr in begin_time_range){
                                if(row_uri_time_range_data[tr]){
                                    print row_uri_time_range_data[tr];
                                    row_uri_time_range_data[tr] = 0;
                                }else{
                                    print 0
                                }
                                print "\t";
                            }
                            ORS = "\n"
                            print ""
                        }
                    }
                    print "----------------------------------------------------------------------------------------------------------------"
                }
            }
        }
    }
    function sort_arr(arr, tarr){
        for(k in arr){
          	tarr[++alen] = (k","arr[k]);
        }
        for(m=1; m<=alen-1; m++){
            for(n=m+1; n<=alen; n++){
                split(tarr[m], tm, ",");
                split(tarr[n+1], tn, ",");
                tnum = tarr[m];
                if(tm[2]+0 < tn[2]+0){
                     tarr[m] = tarr[n+1];
                     tarr[n+1] = tnum;
                }
            }
        }
        return alen;
    }
    function month_str2num(month_str){
        month_str = tolower(month_str);
        if(month_str == "jan"){return 1;}
        if(month_str == "feb"){return 2;}
        if(month_str == "mar"){return 3;}
        if(month_str == "apr"){return 4;}
        if(month_str == "may"){return 5;}
        if(month_str == "jun"){return 6;}
        if(month_str == "jul"){return 7;}
        if(month_str == "aug"){return 8;}
        if(month_str == "sep"){return 9;}
        if(month_str == "oct"){return 10;}
        if(month_str == "nov"){return 11;}
        if(month_str == "dev"){return 12;}
        return 0;
    }
    function timelocal_2_timestamp(timelocal){
        split(timelocal, tlarr, " ");
        timelocal = tlarr[1];
        split(timelocal, tlarr, "/");
        date = tlarr[1];
        month_str = tlarr[2];
        month = month_str2num(month_str);
        if(month == 0){
            return 0;
        }
        yhms_str = tlarr[3];
        split(yhms_str, yhmsarr, ":");
        year = yhmsarr[1];
        hour = yhmsarr[2];
        minute = yhmsarr[3];
        second = yhmsarr[4];
        return mktime(year" "month" "date" "hour" "minute" "second);
    }
' $awklogs_params_log_file

# awk 'BEGIN{print strftime("%Y-%m-%d %H:%M:%S",systime());}'
# awk 'BEGIN{print mktime("2019 11 11 11 11 11")}'