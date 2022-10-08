stf file, version 0.1.0

# Test t.args

Test the t args variable.

### File cmd.sh command

~~~
$statictea \
  -l log.txt \
  -p '$$' \
  -p "pre$,post" \
  -s server.json \
  -o shared.tea \
  -t tmpl.txt \
  -r result >stdout 2>stderr
~~~

### File tmpl.txt

~~~
$$ nextline args = string("t.args", t.args)
{args}
~~~

### File server.json

~~~
{}
~~~

### File shared.tea

~~~
~~~

### File result.expected

~~~
t.args.help = false
t.args.version = false
t.args.update = false
t.args.log = true
t.args.repl = false
t.args.serverList = ["server.json"]
t.args.codeList = ["shared.tea"]
t.args.resultFilename = "result"
t.args.templateFilename = "tmpl.txt"
t.args.logFilename = "log.txt"
t.args.prepostList = [["$$",""],["pre$","post"]]
~~~

### Expected result == result.expected
### Expected stdout == empty
### Expected stderr == empty
