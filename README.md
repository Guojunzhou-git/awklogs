# awklogs
Using awk to analyze various log files, such as: nginx.access.log, nginx.error.log

## usage:
```linux
awklogs.sh 
Usage: awklogs [--option=value] [...]
        --log_type
                nginx.access            analysis nginx.access.log
                nginx.error             analysis nginx.error.log
        --log_file
                /path/to/xxx.log        input path of log file
        --ana_action
                remote_addr_count       output how many requests every remote_addr makes
                remote_addr_bytes_sum   output how many bytes every remote_addr used
                request_uri_count       output how many times every uri been requested
                request_uri_status      output how many times every uri been requested with http status
        --output_limit
                10                      how many result output, default 10
```

## examples
### 1. remote_addr_count
output how many requests every remote_addr makes
```linux
awklogs.sh --log_type=nginx.access --log_file=./test/teacher.cd.singsound.com_access.log --ana_action=remote_addr_count --output_limit=3
---------------------
remote_addr     count
---------------------
124.42.59.17    12713
183.136.190.62  102
112.124.3.0     65
```
### 2. request_uri_count
output how many times every uri been requested
```linux
awklogs.sh --log_type=nginx.access --log_file=./test/teacher.cd.singsound.com_access.log --ana_action=request_uri_count --output_limit=5
---------------------
request_uri     count
---------------------
/       2356
/list.php       2175
/main.php       1972
/sync.php       630
/cleverassign.php       439
```
### 3. remote_addr_bytes_sum
output how many bytes every remote_addr used
```linux
./awklogs.sh --log_type=nginx.access --log_file=./test/teacher.cd.singsound.com_access.log --ana_action=remote_addr_bytes_sum --output_limit=5
------------------------------------------------------
remote_addr_bytes       bytes_sum       human_sum
------------------------------------------------------
124.42.59.17            191631083       182.754 MB
183.136.190.62          3097813 2.9543 MB
60.191.38.77            546857          534.04 KB
180.163.220.3           418317          408.513 KB
180.163.220.66          414069          404.364 KB
```
### 4. request_uri_status
output how many times every uri been requested with http status
```linux
./awklogs.sh --log_type=nginx.access --log_file=./test/teacher.cd.singsound.com_access.log --ana_action=request_uri_status --output_limit=5
------------------------------------------------------
request_uri     code    count
------------------------------------------------------
/       200     2345
/list.php       200     2174
/main.php       200     1970
/sync.php       200     620
/cleverassign.php       200     439
```
