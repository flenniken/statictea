stf file, version 0.1.0

# t.args

Test t.args with normal arguments.

### File cmd.sh command

~~~
$statictea -l -s=server.json -j=shared.json \
  -s=server2.json -j=shared2.json \
  -p='abc$,def' -p='$$' \
  -t=template.html -r=result.html >stdout 2>stderr
~~~

### File template.html

~~~
t.args keys:

$$ nextline g.keys = keys(t.args)
  {g.keys}

t.args keys:

$$ nextline
$$ : t.repeat = len(g.keys)
$$ : num = add(t.row, 1)
$$ : key = get(g.keys, t.row)
  {num}: {key}

t.args:

$$ nextline
  {t.args}

t.args:

$$ nextline t.repeat = len(g.keys)
$$ : key = get(g.keys, t.row)
$$ : value = get(t.args, key)
  {key}: {value}

Command line from t.args:

$$ block t.repeat = len(t.args.serverList)
$$ : g.serverParts &= concat("--server=", get(t.args.serverList, t.row))
$$ endblock
$$ block t.repeat = len(t.args.serverList)
$$ : g.sharedParts &= concat("--server=", get(t.args.sharedList, t.row))
$$ endblock
$$ block t.repeat = len(t.args.templateList)
$$ : g.templateParts &= concat("--server=", get(t.args.templateList, t.row))
$$ endblock
$$ block t.repeat = len(t.args.prepostList)
$$ : prepost = get(t.args.prepostList, t.row)
$$ : prefix = get(prepost, 0)
$$ : postfix = get(prepost, 1)
$$ : part = concat("--prepost='", concat(join(list(prefix, postfix), ",", 1), "'"))
$$ : g.prepostParts &= part
$$ endblock
$$ nextline
$$ : parts &= "statictea"
$$ : parts &= if0(t.args.help, "", "--help")
$$ : parts &= if0(t.args.version, "", "--version")
$$ : parts &= if0(t.args.update, "", "--update")
$$ : parts &= if0(t.args.log, "", "--log")
$$ :
$$ : parts &= if0(len(t.args.resultFilename), "", +
$$ :   concat("--result=", t.args.resultFilename))
$$ :
$$ : parts &= if0(len(t.args.logFilename), "", +
$$ :   concat("--log=", t.args.logFilename))
$$ :
$$ : parts &= join(g.serverParts, " ")
$$ : parts &= join(g.sharedParts, " ")
$$ : parts &= join(g.templateParts, " ")
$$ : parts &= join(g.prepostParts, " ")
$$ : cmd = join(parts, " ", 1)
  {cmd}
~~~


### File server.json

~~~
{}
~~~

### File shared.json

~~~
{}
~~~

### File server2.json

~~~
{}
~~~

### File shared2.json

~~~
{}
~~~

### File result.expected

~~~
t.args keys:

  ["help","version","update","log","serverList","sharedList","resultFilename","templateList","logFilename","prepostList"]

t.args keys:

  1: help
  2: version
  3: update
  4: log
  5: serverList
  6: sharedList
  7: resultFilename
  8: templateList
  9: logFilename
  10: prepostList

t.args:

  {"help":0,"version":0,"update":0,"log":1,"serverList":["server.json","server2.json"],"sharedList":["shared.json","shared2.json"],"resultFilename":"result.html","templateList":["template.html"],"logFilename":"","prepostList":[["abc$","def"],["$$",""]]}

t.args:

  help: 0
  version: 0
  update: 0
  log: 1
  serverList: ["server.json","server2.json"]
  sharedList: ["shared.json","shared2.json"]
  resultFilename: result.html
  templateList: ["template.html"]
  logFilename: 
  prepostList: [["abc$","def"],["$$",""]]

Command line from t.args:

  statictea --log --result=result.html --server=server.json --server=server2.json --server=shared.json --server=shared2.json --server=template.html --prepost='abc$,def' --prepost='$$'
~~~

### Expected result.html == result.expected
### Expected stdout == empty
### Expected stderr == empty
