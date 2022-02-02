stf file, version 0.1.0

# Readme Statements

Test readme statements section.

### File cmd.sh command

~~~
$statictea -s=server.json \
  -t=template.html -r=result.html >stdout 2>stderr
~~~

### File template.html

~~~
$$ block
$$ : tea = "Earl Grey"
$$ : num = 5
$$ : t.repeat = 2
$$ : nameLen = len(s.name)
$$ : name = concat(substr(s.name, 0, 7), "...")
tea => {tea}
num => {num}
nameLen => {nameLen}
name => {name}
$$ endblock
~~~

### File server.json

~~~
{
  "name": "server json file",
}
~~~

### File result.expected

~~~
tea => Earl Grey
num => 5
nameLen => 16
name => server ...
tea => Earl Grey
num => 5
nameLen => 16
name => server ...
~~~

### Expected result.expected == result.html
### Expected stdout == empty
### Expected stderr == empty

