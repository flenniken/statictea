stf file, version 0.1.0

# Log Default Path

Test the default log path is written to when you specify -l without a
filename.

Log a random number then check it appears in the log file.

Mac: ~/Library/Logs/statictea.log
Other: ~/statictea.log

### File make.server.json command

Create a random number and add it to the server.json file as a
variable.

~~~
#!/bin/bash
printf "{\"random\": \"%s%s\"}\n" $RANDOM $RANDOM > server.json
~~~

### File cmd.sh command

~~~
$statictea \
  -l \
  -s server.json \
  -t tmpl.txt \
  -r result \
  >stdout 2>stderr
~~~

### File log.sh command

Create the random.txt file from the log line containing the random
number.

~~~
#!/bin/bash
if [[ $OSTYPE == 'darwin'* ]]; then
  log=~/Library/Logs/statictea.log
else
  log=~/statictea.log
fi
tail -200 $log | sed 's/^.*); //' | grep "Random number " | tail -1 >random.txt
~~~

### File tmpl.txt

The template creates the result.txt file with the same random number
line that gets logged.

~~~
$$ nextline if((s.random == ""), warn("no random number"))
Random number {s.random}
$$ nextline t.output = "log"
Random number {s.random}
~~~

### Expected result == random.txt
### Expected stdout == empty
### Expected stderr == empty
