stf file, version 0.1.0

# Template warn-log

Test that the warn command increments the warning count and returns a
non-zero return code.

### File cmd.sh command nonZeroReturn

~~~
$statictea \
  -l log.txt \
  -t tmpl.txt \
  -r result >stdout 2>stderr
~~~

### File log.sh command

Create the log.filtered file which contains the lines with Warnings:
in them.

~~~
cat log.txt | grep -o "; Warnings: .*" >log.filtered | true
~~~

### File tmpl.txt

~~~
$$ block a = warn("a warning happened")
$$ : b = warn("another one")
$$ endblock
~~~

### File stderr.expected

~~~
tmpl.txt(1): a warning happened
tmpl.txt(2): another one
~~~

### File log.filtered.expected

~~~
; Warnings: 2
~~~

### Expected result == empty
### Expected stdout == empty
### Expected stderr == stderr.expected
### Expected log.filtered == log.filtered.expected

Expected log.txt == empty