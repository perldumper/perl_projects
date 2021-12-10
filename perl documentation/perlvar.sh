#!/bin/bash

function list_func()
{
cat <<"EOF"
%!
%+
%-
@+
@-
@_
$!
$"
$#
$%
$&
$'
$(
$)
$*
$+
$,
$-
$.
$/
$:
$;
$<
$=
$>
$?
$@
$[
$\
$]
$^
$_
$`
$|
$~
$$
$0
$^A
$a
$ACCUMULATOR
$ARG
$ARGV
$b
$BASETIME
$^C
$CHILD_ERROR
${^CHILD_ERROR_NATIVE}
$COMPILING
$^D
$DEBUGGING
$<digits>
$^E
$EFFECTIVE_GROUP_ID
$EFFECTIVE_USER_ID
$EGID
${^ENCODING}
$ERRNO
$EUID
$EVAL_ERROR
$EXCEPTIONS_BEING_CAUGHT
$EXECUTABLE_NAME
$EXTENDED_OS_ERROR
$^F
$FORMAT_FORMFEED
$FORMAT_LINE_BREAK_CHARACTERS
$FORMAT_LINES_LEFT
$FORMAT_LINES_PER_PAGE
$FORMAT_NAME
$FORMAT_PAGE_NUMBER
$FORMAT_TOP_NAME
$GID
${^GLOBAL_PHASE}
$^H
$^I
$INPLACE_EDIT
$INPUT_LINE_NUMBER
$INPUT_RECORD_SEPARATOR
$^L
${^LAST_FH}
$LAST_PAREN_MATCH
$LAST_REGEXP_CODE_RESULT
$LAST_SUBMATCH_RESULT
$LIST_SEPARATOR
$^M
${^MATCH}
$MATCH
$^N
$NR
$^O
$OFS
$OLD_PERL_VERSION
${^OPEN}
$ORS
$OS_ERROR
$OSNAME
$OUTPUT_AUTOFLUSH
$OUTPUT_FIELD_SEPARATOR
$OUTPUT_RECORD_SEPARATOR
$^P
$PERLDB
$PERL_VERSION
$PID
${^POSTMATCH}
$POSTMATCH
${^PREMATCH}
$PREMATCH
$PROCESS_ID
$PROGRAM_NAME
$^R
$REAL_GROUP_ID
$REAL_USER_ID
${^RE_DEBUG_FLAGS}
${^RE_TRIE_MAXBUF}
$RS
$^S
${^SAFE_LOCALES}
$SUBSCRIPT_SEPARATOR
$SUBSEP
$SYSTEM_FD_MAX
$^T
${^TAINT}
$UID
${^UNICODE}
${^UTF8CACHE}
${^UTF8LOCALE}
$^V
$^W
$WARNING
${^WARNING_BITS}
${^WIN32_SLOPPY_STAT}
$^X
@ARG
@ARGV
ARGV
ARGVOUT
%{^CAPTURE}
@{^CAPTURE}
%{^CAPTURE_ALL}
%ENV
%ERRNO
@F
%^H
HANDLE->autoflush(
HANDLE->format_lines_left(EXPR)
HANDLE->format_lines_per_page(EXPR)
HANDLE->format_name(EXPR)
HANDLE->format_page_number(EXPR)
HANDLE->format_top_name(EXPR)
HANDLE->input_line_number(
%INC
@INC
IO::Handle->format_formfeed(EXPR)
IO::Handle->format_line_break_characters
IO::Handle->input_record_separator(
IO::Handle->output_field_separator(
IO::Handle->output_record_separator(
@ISA
@LAST_MATCH_END
@LAST_MATCH_START
%LAST_PAREN_MATCH
%OS_ERROR
%SIG
EOF
}


selection="$(list_func | dmenu -i -l 30 )"
# selection="$(list_func | dmenu -i -l 30 -fn 'Droid Sans Mono-11' )"

[ "$?" -ne 0  ] && exit

#if[ "$sel" = "$"" ] ; then
#
#${TERMINAL} -T "$selection - perlvar" -e "perldoc -v '$selection'"
#exit
#
#fi
#	
#
#selection="\""$selection
#selection+="\""



#${TERMINAL} -T "$selection - perlvar" -e "perldoc -v '$selection'"

#xfce4-terminal -T "$selection - perlvar" -e "perldoc -v '$selection'"
st -e perldoc -v "$selection"


