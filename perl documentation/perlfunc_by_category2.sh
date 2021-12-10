#!/bin/bash

function list_func()
{
cat <<"EOF"
FUNCTIONS FOR SCALARS OR STRINGS
chomp
chop
chr
crypt
fc
hex
index
lc
lcfirst
length
oct
ord
pack
q
qq
reverse
rindex
sprintf
substr
tr
uc
ucfirst
y

REGULAR EXPRESSIONS AND PATTERN MATCHING
m
pos
qr
quotemeta
s
split
study

NUMERIC FUNCTIONS
abs
atan2
cos
exp
hex
int
log
oct
rand
sin
sqrt
srand

FUNCTIONS FOR REAL @ARRAYS
each
keys
pop
push
shift
splice
unshift
values

FUNCTIONS FOR LIST DATA
grep
join
map
qw
reverse
sort
unpack

FUNCTIONS FOR REAL %HASHES
delete
each
exists
keys
values

INPUT AND OUTPUT FUNCTIONS
binmode
close
closedir
dbmclose
dbmopen
die
eof
fileno
flock
format
getc
print
printf
read
readdir
readline
rewinddir
say
seek
seekdir
select
syscall
sysread
sysseek
syswrite
tell
telldir
truncate
warn
write

FUNCTIONS FOR FIXED-LENGTH DATA OR RECORDS
pack
read
syscall
sysread
sysseek
syswrite
unpack
vec

FUNCTIONS FOR FILEHANDLES FILES OR DIRECTORIES
-X
chdir
chmod
chown
chroot
fcntl
glob
ioctl
link
lstat
mkdir
open
opendir
readlink
rename
rmdir
select
stat
symlink
sysopen
umask
unlink
utime

KEYWORDS RELATED TO THE CONTROL FLOW OF YOUR PERL PROGRAM
break
caller
continue
die
do
dump
eval
evalbytes
exit
__FILE__
goto
last
__LINE__
next
__PACKAGE__
redo
return
sub
__SUB__
wantarray

KEYWORDS RELATED TO SCOPING
caller
import
local
my
our
package
state
use

MISCELLANEOUS FUNCTIONS
defined
formline
lock
prototype
reset
scalar
undef

FUNCTIONS FOR PROCESSES AND PROCESS GROUPS
alarm
exec
fork
getpgrp
getppid
getpriority
kill
pipe
qx
readpipe
setpgrp
setpriority
sleep
system
times
wait
waitpid

KEYWORDS RELATED TO PERL MODULES
do
import
no
package
require
use

KEYWORDS RELATED TO CLASSES AND OBJECT-ORIENTATION
bless
dbmclose
dbmopen
package
ref
tie
tied
untie
use

LOW-LEVEL SOCKET FUNCTIONS
accept
bind
connect
getpeername
getsockname
getsockopt
listen
recv
send
setsockopt
shutdown
socket
socketpair

SYSTEM V INTERPROCESS COMMUNICATION FUNCTIONS
msgctl
msgget
msgrcv
msgsnd
semctl
semget
semop
shmctl
shmget
shmread
shmwrite

FETCHING USER AND GROUP INFO
endgrent
endhostent
endnetent
endpwent
getgrent
getgrgid
getgrnam
getlogin
getpwent
getpwnam
getpwuid
setgrent
setpwent

FETCHING NETWORK INFO
endprotoent
endservent
gethostbyaddr
gethostbyname
gethostent
getnetbyaddr
getnetbyname
getnetent
getprotobyname
getprotobynumber
getprotoent
getservbyname
getservbyport
getservent
sethostent
setnetent
setprotoent
setservent

TIME-RELATED FUNCTIONS
gmtime
localtime
time
times

NON-FUNCTION KEYWORDS
and
AUTOLOAD
BEGIN
CHECK
cmp
CORE
__DATA__
default
DESTROY
else
elseif
elsif
END
__END__
eq
for
foreach
ge
given
gt
if
INIT
le
lt
ne
not
or
UNITCHECK
unless
until
when
while
x
xor
EOF
}




selection="$(list_func | dmenu -i -l 30)"
# selection="$(list_func | dmenu -i -l 30 -fn 'Droid Sans Mono-11' )"

[[ "$?" -ne 0 ]] && exit


#${TERMINAL} -T "$selection - perlfunc" -e "perldoc -f "$selection""

#xfce4-terminal -T "$selection - perlfunc" -e "perldoc -f "$selection""
st -T "$selection - perlfunc" -e perldoc -f "$selection"
