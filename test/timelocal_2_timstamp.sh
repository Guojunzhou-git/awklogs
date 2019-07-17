#!/bin/bash
awk '
    BEGIN{
        timestamp = timelocal_2_timestamp("06/May/2019:10:04:16 +0800");
        print "timestamp of [06/May/2019:10:04:16 +0800] is: "timestamp
        datetime = strftime("%Y-%m-%d %H:%M:%S", timestamp);
        print "datetime of "timestamp" is: "datetime
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
'