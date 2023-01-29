stf file, version 0.1.0

# Mutable Tea Variables

Test that you cannot change the tea variables lists and dicts.

### File cmd.sh command nonZeroReturn

~~~
$statictea \
  -o shared.tea \
  -t tmpl.txt \
  -r result >stdout 2>stderr
~~~


### File tmpl.txt

~~~
$$ block args = string(t.args, "dn")
{args}
$$ endblock
~~~

### File shared.tea

~~~
args = t.args
args.extra = 5
args.serverList &= "another"
args.codeList &= "code"
args.prepostList &= 3
~~~

### File result.expected

~~~
help = false
version = false
update = false
log = false
repl = false
serverList = []
codeList = ["shared.tea"]
resultFilename = "result"
templateFilename = "tmpl.txt"
logFilename = ""
prepostList = []
~~~

### File stdout.expected

~~~
~~~

### File stderr.expected

~~~
shared.tea(2): w261: You cannot assign to an immutable dictionary.
statement: args.extra = 5
           ^
shared.tea(3): w262: You cannot append to an immutable list.
statement: args.serverList &= "another"
           ^
shared.tea(4): w262: You cannot append to an immutable list.
statement: args.codeList &= "code"
           ^
shared.tea(5): w262: You cannot append to an immutable list.
statement: args.prepostList &= 3
           ^
~~~

### Expected result == result.expected
### Expected stdout == stdout.expected
### Expected stderr == stderr.expected
