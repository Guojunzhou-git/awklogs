# awklogs
Using awk to analyze nginx.access.log, based on all possible fields.<br/>Bugs Report: php20141104@163.com
## usage:
```linux
awklogs.sh
Usage: awklogs [--option=value] [...]
	--log_type
		nginx.access		analysis nginx.access.log
		json			analysis json format file
	--log_file
		/path/to/xxx.log	input path of log file
	--analysis_field
		request_uri		analysis access.log file based on request_uri field, give result of:
					- 1. how many request every uri makes
					- 2. how many request with every http code
					- 3. request_time time_range with every http_code
		remote_addr		analysis access.log file based on remote_addr field, give result of:
					- 1. how many remote_addr have sent request
					- 2. how many request every remote_addr makes
					- 3. how many bytes every remote_addr used
		time_local		analysis access.log file based on time_local field, give result of:
					- 1. how many request every second makes(concurrency)
					- 2. when comes the top N concurrency
					- 3. QPS of every seconds
		xxx			analysis json format file, analysis_field need to be given
	--filter_timestamp_start		add rows filter time_local start, timestamp like 1500000000
	--filter_timestamp_end		add rows filter time_local end, timestamp like 1500000000,
					ignored when timestamp_end < timestamp_start
	--filter_datetime_start		add rows filter time_local start, datetime with format "%Y-%m-%d_%H:%M:%S" like 2019-01-01_01:01:01
	--filter_datetime_end		add rows filter time_local end, datetime with format "%Y-%m-%d_%H:%M:%S" like 2019-01-01_01:01:01,
					ignored when datetime_end < datetime_start
	--filter_request_uri		only analysis the special REQUEST_URI
```
## log type
### 1. --log_type=nginx.access
analysis nginx.access.log based on default nginx log formay.
```linux
log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                  '$status $body_bytes_sent "$http_referer" '
                  '"$http_user_agent" "$http_x_forwarded_for" "$upstream_response_time" "$request_time"';
```
### 2. --log_type=json
analysis json format log file.
> based on [JSON.awk](https://github.com/step-/JSON.awk). thanks for [JSON.awk](https://github.com/step-/JSON.awk)

## analysis_field
analysis log file based on field
### 1. request_uri based analysis [--log_type=nginx.access]
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
### 2. remote_addr based analysis [--log_type=nginx.access]
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
### 3. time_local based analysis [--log_type=nginx.access]
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
### 4. json field count analysis [--log_type=json]
analysis json format log file based on `function` field.
```linux
awklogs.sh --log_type=json --log_file=test/log_10000.json --analysis_field=function
------------------------------------------------
field					count
------------------------------------------------
"event_upload_offline_evalute_audio_...	6341
"send"                                  1145
"start"                                 919
"on_event_dev_status_result"            634
"on_message"                            420
"handle"                                420
"event_submit_answers_run"              58
"event_submit_category_run"             58
"on_connect"                            2
"do_answer_submit_post"                 2
"on_disconnect"                         1
------------------------------------------------
10000 rows analysised, 0 rows ignored. 6 seconds used.
```
## filter
add condition to filter rows
### 1. time_local based filter: --filter_timestamp_start & --filter_timestamp_end
second timestamp like 1560000000
```linux
awklogs.sh --log_type=nginx.access --log_file=test/teacher.cd.singsound.com_access.log --analysis_field=remote_addr --filter_timestamp_start=1560000000 --filter_timestamp_end=1561000000
2009 rows analysised.
----------------------------------------------------------
remote_addr     request byte_sum        human_sum
----------------------------------------------------------
124.42.59.17    1547    12700363                12.112 MB       
222.92.255.178  57      251073          245.188 KB      
117.136.31.217  42      161848          158.055 KB      
113.88.12.202   42      176401          172.267 KB      
113.88.14.85    31      169646          165.67 KB      
```
### 2. time_local based filter: --filter_datetime_start & --filter_datetime_end
datetime with format "%Y-%m-%d_%H:%M:%S" like 2019-06-08_21:20:00
```linux
awklogs.sh --log_type=nginx.access --log_file=test/teacher.cd.singsound.com_access.log --analysis_field=remote_addr --filter_datetime_start=2019-06-08_21:20:00 --filter_datetime_end=2019-06-20_11:06:40
2009 rows analysised.
----------------------------------------------------------
remote_addr     request byte_sum        human_sum
----------------------------------------------------------
124.42.59.17    1547    12700363                12.112 MB       
222.92.255.178  57      251073          245.188 KB      
117.136.31.217  42      161848          158.055 KB      
113.88.12.202   42      176401          172.267 KB      
113.88.14.85    31      169646          165.67 KB    
```
### 3. request_uri based filter: --filter_request_uri
only analysis the special REQUEST_URI
```linux
awklogs.sh --log_type=nginx.access --log_file=test/api2.cd.singsound.com_access.log --analysis_field=request_uri --filter_request_uri=/business/frontDynamic/Config
3982 rows analysised. <1 seconds used.
----------------------------------------------------------------------------------------------------------------
request_uri			total	status	count	<100ms	<200ms	<500ms	<1000ms	<2000ms	>2000ms
----------------------------------------------------------------------------------------------------------------
/business/frontDynamic/Config	3982
					200	3976	40	3676	12	0	0	248
					499	5	2	3	0	0	0	0
					400	1	1	0	0	0	0	0
----------------------------------------------------------------------------------------------------------------
```
## result
analysis result output
### 1. analysised rows
output how many rows analysised filtered by `filters`
### 2. used_time
output how many seconds used during this analysis
