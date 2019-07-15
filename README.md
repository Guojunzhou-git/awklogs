# awklogs
Using awk to analyze various log files, such as: nginx.access.log, nginx.error.log

### usage:
```linux
Usage: awklogs [--option=value] [...]
        --log_type
                nginx.access            analysis nginx.access.log
                nginx.error             analysis nginx.error.log
        --log_file
                /path/to/xxx.log        input path of log file
        --ana_action
                remote_addr_count       output how many requests every remote_addr makes
```
