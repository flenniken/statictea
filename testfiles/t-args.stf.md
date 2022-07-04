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
$$ block a = t.args.help
t.args.help = {t.args.help}
t.args.version = {t.args.version}
t.args.update = {t.args.update}
t.args.log = {t.args.log}
t.args.serverList = {t.args.serverList}
t.args.codeList = {t.args.codeList}
t.args.resultFilename = {t.args.resultFilename}
t.args.templateFilename = {t.args.templateFilename}
t.args.logFilename = {t.args.logFilename}
t.args.prepostList = {t.args.prepostList}
$$ endblock
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
t.args.help = 0
t.args.version = 0
t.args.update = 0
t.args.log = 1
t.args.serverList = ["server.json"]
t.args.codeList = ["shared.tea"]
t.args.resultFilename = result
t.args.templateFilename = tmpl.txt
t.args.logFilename = log.txt
t.args.prepostList = [["$$",""],["pre$","post"]]
~~~

### Expected result == result.expected
### Expected stdout == empty
### Expected stderr == empty
