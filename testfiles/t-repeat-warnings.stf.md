stf file, version 0.1.0

# Tea Repeat Warnings

Test t repeat warnings.

### File cmd.sh command nonZeroReturn

~~~
$statictea \
  -l log.txt \
  -s server.json \
  -s shared.json \
  -t tmpl.txt \
  -r result.html \
  >stdout 2>stderr
~~~

### File log.sh command

~~~
cat log.txt | cut -c 26- | grep "^tmpl.txt" >log.filtered | true
~~~

### File tmpl.txt

~~~
Set t.repeat to -1.
$$ nextline t.repeat = -1

Set t.repeat to 3000.
$$ nextline t.repeat = 3000

Set t.repeat to five.
$$ nextline t.repeat = "five"

Set t.repeat to [2].
$$ nextline list = list(2)
$$ : t.repeat = list

Set t.repeat to maxRepeat.
$$ block t.repeat = 100
$$ endblock

Setting t.repeat to 0, short curcuits the command.
$$ block a = warn("hit")
$$ : t.repeat = 0
$$ : b = warn("not hit")
short curcuit example
$$ endblock

Increase maxRepeat then set t.repeat to it.
$$ block t.maxRepeat = 200
$$ : t.repeat = 200
$$ endblock

Increase maxRepeat then set t.repeat one past it.
$$ block t.maxRepeat = 200
$$ : t.repeat = 201
$$ endblock

Set maxRepeat to 2 and repeat to 3. It repeats 1 time because
t.repeat cannot be set.

$$ block t.maxRepeat = 2
$$ : t.repeat = 3
repeat this {t.repeat} times
$$ endblock
after

Set t.repeat twice. Expect it two repeat 4 times.
$$ block t.repeat = 4
$$ : t.repeat = 3
repeat this {t.repeat} times
$$ endblock
after
~~~

### File server.json

~~~
{
  "name": "server",
  "type": "json"
}
~~~

### File shared.json

~~~
{
  "name2": "shared",
  "type2": "json"
}
~~~

### File result.expected

~~~
Set t.repeat to -1.

Set t.repeat to 3000.

Set t.repeat to five.

Set t.repeat to [2].

Set t.repeat to maxRepeat.

Setting t.repeat to 0, short curcuits the command.

Increase maxRepeat then set t.repeat to it.

Increase maxRepeat then set t.repeat one past it.

Set maxRepeat to 2 and repeat to 3. It repeats 1 time because
t.repeat cannot be set.

repeat this {t.repeat} times
after

Set t.repeat twice. Expect it two repeat 4 times.
repeat this 4 times
repeat this 4 times
repeat this 4 times
repeat this 4 times
after
~~~

### File stderr.expected

~~~
tmpl.txt(2): w44: The variable t.repeat must be an integer between 0 and t.maxRepeat.
statement: t.repeat = -1
           ^
tmpl.txt(5): w44: The variable t.repeat must be an integer between 0 and t.maxRepeat.
statement: t.repeat = 3000
           ^
tmpl.txt(8): w44: The variable t.repeat must be an integer between 0 and t.maxRepeat.
statement: t.repeat = "five"
           ^
tmpl.txt(12): w44: The variable t.repeat must be an integer between 0 and t.maxRepeat.
statement: t.repeat = list
           ^
tmpl.txt(19): hit
tmpl.txt(32): w44: The variable t.repeat must be an integer between 0 and t.maxRepeat.
statement: t.repeat = 201
           ^
tmpl.txt(39): w44: The variable t.repeat must be an integer between 0 and t.maxRepeat.
statement: t.repeat = 3
           ^
tmpl.txt(40): w58: The replacement variable doesn't exist: t.repeat.
tmpl.txt(46): w129: You cannot reassign a variable.
statement: t.repeat = 3
           ^
tmpl.txt(46): w129: You cannot reassign a variable.
statement: t.repeat = 3
           ^
tmpl.txt(46): w129: You cannot reassign a variable.
statement: t.repeat = 3
           ^
tmpl.txt(46): w129: You cannot reassign a variable.
statement: t.repeat = 3
           ^
~~~

### Expected stdout == empty
### Expected stderr == stderr.expected
### Expected log.filtered == empty
### Expected result.html == result.expected
