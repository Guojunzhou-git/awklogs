# awklogs
Using awk to analyze various log files, such as: nginx.access.log, nginx.error.log

## usage:
```linux
awklogs.sh 
Usage: awklogs [--option=value] [...]
        --log_type
                nginx.access            analysis nginx.access.log
        --log_file
                /path/to/xxx.log        input path of log file
        --analysis_field
                request_uri             analysis access.log file based on request_uri field, give result of:
                                        - 1. how many request every uri makes
                                        - 2. how many request with every http code
                                        - 3. request_time time_range with every http_code
                remote_addr             analysis access.log file based on remote_addr field, give result of:
                                        - 1. how many remote_addr have sent request
                                        - 2. how many request every remote_addr makes
                                        - 3. how many bytes every remote_addr used
                time_local              analysis access.log file based on time_local field, give result of:
                                        - 1. how many request every second makes(concurrency)
                                        - 2. when comes the top N concurrency
                                        - 3. QPS of every seconds
```

## examples
### 1. request_uri based analysis
analysis access.log file based on request_uri field
```linux
awklogs.sh --log_type=nginx.access --log_file=test/teacher.cd.singsound.com_access.log --analysis_field=request_uri
----------------------------------------------------------------------------------------------------------------
request_uri                     total   status  count   <100ms  <200ms  <500ms  <1000ms <2000ms >2000ms
----------------------------------------------------------------------------------------------------------------
/report.php                     2689
                                        200     2687    0       23      0       2652    0       12      
                                        499     2       0       0       0       2       0       0       
----------------------------------------------------------------------------------------------------------------
/                               2356
                                        500     7       0       0       0       7       0       0       
                                        200     2345    0       48      3       2252    7       33      
                                        499     4       0       0       0       2       0       2       
----------------------------------------------------------------------------------------------------------------
```
### 2. remote_addr based analysis
analysis access.log file based on remote_addr field
```linux
awklogs.sh --log_type=nginx.access --log_file=test/teacher.cd.singsound.com_access.log --analysis_field=remote_addr
----------------------------------------------------------
remote_addr     request byte_sum        human_sum
----------------------------------------------------------
124.42.59.17    12713   191631083       182.754 MB      
183.136.190.62  102     3097813         2.9543 MB       
112.124.3.0     65      0               0 B     
222.92.255.178  57      251073          245.188 KB      
```
### 3. time_local based analysis
analysis access.log file based on time_local field
```linux
awklogs.sh --log_type=nginx.access --log_file=test/teacher.cd.singsound.com_access.log --analysis_field=time_local
------------------------------------------------------------------
datetime                concurrency     avg_time(ms)    QPS
------------------------------------------------------------------
2019-06-04 02:40:47     28              0               -
2019-06-06 03:43:26     18              0               -
2019-05-20 17:43:54     7               45.5714         153
2019-05-20 17:43:55     7               41.5714         168
2019-05-20 17:43:56     7               36.1429         193
2019-05-28 09:49:14     6               77.8333         77
```
