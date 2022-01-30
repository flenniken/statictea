stf file, version 0.1.0

## Test standard invocation used for new stf test template.

# The t.output variable determines where the block output goes.  By
# default it goes to the result file.

# - "result" -- to the result file (default)
# - "stdout" -- to standard out
# - "stderr" -- to standard error
# - "log" -- to the log file
# - "skip" -- to the bit bucket


### File cmd.sh command

~~~
$statictea -l=log.txt -t=tmpl.txt -r=result.txt >stdout 2>stderr
~~~


# Remove the time prefix from the log lines then extract the template lines.
### File log.sh command

~~~
cat log.txt | cut -c 26- | grep "^tmpl.txt" >log.filtered
~~~



### File tmpl.txt

~~~
$$ block t.output = "log"
┌─────────┐
│log block│
└─────────┘
$$ endblock
$$ block t.output = "skip"
┌──────────┐
│skip block│
└──────────┘
$$ endblock
$$ block t.output = "stdout"
┌────────────┐
│stdout block│
└────────────┘
$$ endblock
$$ block t.output = "stderr"
┌────────────┐
│stderr block│
└────────────┘
$$ endblock
$$ block t.output = "result"
┌────────────┐
│result block│
└────────────┘
$$ endblock
~~~



### File stdout.expected

~~~
┌────────────┐
│stdout block│
└────────────┘
~~~

### File stderr.expected

~~~
┌────────────┐
│stderr block│
└────────────┘
~~~

### File result.expected

~~~
┌────────────┐
│result block│
└────────────┘
~~~

### File log.filtered.expected

~~~
tmpl.txt(2); ┌─────────┐
tmpl.txt(3); │log block│
tmpl.txt(4); └─────────┘
~~~

### File log.txt.expected

~~~
~~~

### Expected result.expected == result.txt
### Expected stdout.expected == stdout
### Expected stderr.expected == stderr
### Expected log.filtered.expected == log.filtered
#--- expected log.txt.expected == log.txt
