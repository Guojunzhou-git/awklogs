#!/usr/bin/awk -f
BEGIN {
	if (BRIEF  == "") BRIEF=1
	if (STREAM == "") STREAM=1
	NO_EMPTY_STR = 0; NO_EMPTY_ARY = NO_EMPTY_OBJ = 1
	if (BRIEF > 0) {
		NO_EMPTY_STR = !(x=bit_on(BRIEF, 0))
		NO_EMPTY_ARY = !(x=bit_on(BRIEF, 1))
		NO_EMPTY_OBJ = !(x=bit_on(BRIEF, 2))
		if (x=bit_on(BRIEF, 3)) NO_EMPTY_STR = 1
	}
	delete FAILS
	reset()
	if (1 == ARGC) {
		while (getline ARGV[++ARGC] < "/dev/stdin") {
			if (ARGV[ARGC] == "")
				break
		}
	}
}
{
	reset()
	++FILEINDEX
	tokenize($0)
	if (0 == parse() && 0 == STREAM) {
		cb_jpaths(JPATHS, NJPATHS)
	}
}
function bit_on(n, b) {
	if (b == 0) return n % 2
	return int(n / 2^b) % 2
}
function append_jpath_component(jpath, component) {
	if (0 == STREAM) {
		return cb_append_jpath_component(jpath, component)
	} else {
		return (jpath != "" ? jpath "," : "") component
	}
}
function append_jpath_value(jpath, value) {
	if (0 == STREAM) {
		return cb_append_jpath_value(jpath, value)
	} else {
		return sprintf("[%s]\t%s", jpath, value)
	}
}
function get_token() {
	TOKEN = TOKENS[++ITOKENS]
	return ITOKENS < NTOKENS
}
function parse_array_empty(jpath) {
	if (0 == STREAM) {
		return cb_parse_array_empty(jpath)
	}
	return "[]"
}
function parse_array_enter(jpath) {
	if (0 == STREAM) {
		cb_parse_array_enter(jpath)
	}
}
function parse_array_exit(jpath, status) {
	if (0 == STREAM) {
		cb_parse_array_exit(jpath, status)
	}
}
function parse_array(a1,   idx,ary,ret) {
	idx=0
	ary=""
	get_token()
	if (TOKEN != "]") {
		while (1) {
			if (ret = parse_value(a1, idx)) {
				return ret
			}
			idx=idx+1
			ary=ary VALUE
			get_token()
			if (TOKEN == "]") {
				break
			} else if (TOKEN == ",") {
				ary = ary ","
			} else {
				report(", or ]", TOKEN ? TOKEN : "EOF")
				return 2
			}
			get_token()
		}
		CB_VALUE = sprintf("[%s]", ary)
		VALUE = 0 == BRIEF ? CB_VALUE : ""
	} else {
		VALUE = CB_VALUE = parse_array_empty(a1)
	}
	return 0
}
function parse_object_empty(jpath) {
	if (0 == STREAM) {
		return cb_parse_object_empty(jpath)
	}
	return "{}"
}
function parse_object_enter(jpath) {
	if (0 == STREAM) {
		cb_parse_object_enter(jpath)
	}
}
function parse_object_exit(jpath, status) {
	if (0 == STREAM) {
		cb_parse_object_exit(jpath, status)
	}
}
function parse_object(a1,   key,obj) {
	obj=""
	get_token()
	if (TOKEN != "}") {
		while (1) {
			if (TOKEN ~ /^".*"$/) {
				key=TOKEN
			} else {
				report("string", TOKEN ? TOKEN : "EOF")
				return 3
			}
			get_token()
			if (TOKEN != ":") {
				report(":", TOKEN ? TOKEN : "EOF")
				return 4
			}
			get_token()
			if (parse_value(a1, key)) {
				return 5
			}
			obj=obj key ":" VALUE
			get_token()
			if (TOKEN == "}") {
				break
			} else if (TOKEN == ",") {
				obj=obj ","
			} else {
				report(", or }", TOKEN ? TOKEN : "EOF")
				return 6
			}
			get_token()
		}
		CB_VALUE = sprintf("{%s}", obj)
		VALUE = 0 == BRIEF ? CB_VALUE : ""
	} else {
		VALUE = CB_VALUE = parse_object_empty(a1)
	}
	return 0
}
function parse_value(a1, a2,   jpath,ret,x) {
	jpath = append_jpath_component(a1, a2)
	if (TOKEN == "{") {
		parse_object_enter(jpath)
		if (parse_object(jpath)) {
			parse_object_exit(jpath, 7)
			return 7
		}
		parse_object_exit(jpath, 0)
	} else if (TOKEN == "[") {
		parse_array_enter(jpath)
		if (ret = parse_array(jpath)) {
			parse_array_exit(jpath, ret)
			return ret
		}
		parse_array_exit(jpath, 0)
	} else if (TOKEN == "") {
		report("value", "EOF")
		return 9
	} else if (TOKEN ~ /^([^0-9])$/) {
		report("value", TOKEN)
		return 9
	} else {
		CB_VALUE = VALUE = TOKEN
	}
	if (0 < BRIEF && ("" == jpath || "" == VALUE)) {
		return 0
	}
	if (0 < BRIEF && (NO_EMPTY_STR && VALUE=="\"\"" || NO_EMPTY_ARY && VALUE=="[]" || NO_EMPTY_OBJ && VALUE=="{}")) {
		return 0
	}
	x = append_jpath_value(jpath, VALUE)
	if(0 == STREAM) {
		JPATHS[++NJPATHS] = x
	} else {
		print x
	}
	return 0
}
function parse(   ret) {
	get_token()
	if (ret = parse_value()) {
		return ret
	}
	if (get_token()) {
		report("EOF", TOKEN)
		return 11
	}
	return 0
}
function report(expected, got,   i,from,to,context) {
	from = ITOKENS - 10; if (from < 1) from = 1
	to = ITOKENS + 10; if (to > NTOKENS) to = NTOKENS
	for (i = from; i < ITOKENS; i++)
		context = context sprintf("%s ", TOKENS[i])
	context = context "<<" got ">> "
	for (i = ITOKENS + 1; i <= to; i++)
		context = context sprintf("%s ", TOKENS[i])
	scream("expected <" expected "> but got <" got "> at input token " ITOKENS "\n" context)
}
function reset() {
	TOKEN=""; delete TOKENS; NTOKENS=ITOKENS=0
	delete JPATHS; NJPATHS=0
	CB_VALUE = VALUE = ""
}
function scream(msg) {
	NFAILS += (FILENAME in FAILS ? 0 : 1)
	FAILS[FILENAME] = FAILS[FILENAME] (FAILS[FILENAME]!="" ? "\n" : "") msg
	if(0 == STREAM) {
		if(cb_fail1(msg)) {
			print FILENAME ": " msg >"/dev/stderr"
		}
	} else {
		print FILENAME ": " msg >"/dev/stderr"
	}
}
function tokenize(a1,   pq,pb,ESCAPE,CHAR,STRING,NUMBER,KEYWORD,SPACE) {
	SPACE="[[:space:]]+"
	gsub(/"[^[:cntrl:]"\\]*((\\[^u[:cntrl:]]|\\u[0-9a-fA-F]{4})[^[:cntrl:]"\\]*)*"|-?(0|[1-9][0-9]*)([.][0-9]*)?([eE][+-]?[0-9]*)?|null|false|true|[[:space:]]+|./, "\n&", a1)
	gsub("\n" SPACE, "\n", a1)
	sub(/^\n/, "", a1)
	ITOKENS=0
	return NTOKENS = split(a1, TOKENS, /\n/)
}