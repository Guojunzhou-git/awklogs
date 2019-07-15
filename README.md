# awklogs
Using awk to analyze various log files, such as: nginx.access.log, nginx.error.log

## usage:
```linux
Usage: awklogs [--option=value] [...]
        --log_type
                nginx.access            analysis nginx.access.log
                nginx.error             analysis nginx.error.log
        --log_file
                /path/to/xxx.log        input path of log file
        --ana_action
                remote_addr_count       output how many requests every remote_addr makes
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
