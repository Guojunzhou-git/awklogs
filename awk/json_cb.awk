function cb_parse_array_empty(jpath) {return "[]";}
function cb_parse_object_empty(jpath) {return "{}";}
function cb_parse_array_enter(jpath) {}
function cb_parse_array_exit(jpath, status) {}
function cb_parse_object_enter(jpath) {}
function cb_parse_object_exit(jpath, status) {}
function cb_append_jpath_component (jpath, component) {gsub(/"/, "", component);return (jpath != "" ? jpath "." : "") component;}
function cb_append_jpath_value (jpath, value) {return sprintf("[%s]\t%s", jpath, value)}
function cb_fails(a, b){}
function cb_fail1(a){}
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
function cb_jpaths(a,b){
    delete json_row;
    json_row["____line"] = NR;
    for(k in a){
        split(a[k], akarr, "\t");
        gsub(/\[/, "", akarr[1])
        gsub(/\]/, "", akarr[1])
        if(akarr[1]){
            json_row[akarr[1]]=akarr[2]
        }
    }
    if(length(json_row) > 1){
        if(analysis_field in json_row){
            ++analysised_row;
            analysis_result["count", json_row[analysis_field]]++;
        }
    }
}
BEGIN {
    BRIEF=0; STREAM=0;
    analysis_start_time = systime();
}
END {
	if (0 == STREAM) {cb_fails(FAILS, NFAILS);}
    for(k in analysis_result){
        split(k, karr, SUBSEP);
        if(karr[1] == "count"){
            analysis_field_count[karr[2]] = analysis_result[k];
        }
    }
    count_len = sort_arr(analysis_field_count, analysis_field_count_sorted);
    print "------------------------------------------------"
    print "field\t\t\t\t\tcount"
    print "------------------------------------------------"
    for(i=1; i<=count_len; ++i){
        split(analysis_field_count_sorted[i], karr, ",");
        if(length(karr[1])<40){
            print sprintf("%-40s", karr[1])karr[2];
        }else{
            print substr(karr[1], 1, 36)"...\t"karr[2];
        }
    }
    print "------------------------------------------------"
    analysis_end_time = systime();
    analysis_used_time = int(analysis_end_time-analysis_start_time);
    if(analysis_used_time == 0){
        analysis_used_time = "<1";
    }
    print analysised_row" rows analysised, "int(NR-analysised_row)" rows ignored. "analysis_used_time" seconds used."
}