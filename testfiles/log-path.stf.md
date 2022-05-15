stf file, version 0.1.0

# Log Default Path

Test the default log path when you specify -l without a filename.

Log something then check it appears in the expected file.

Mac: ~/Library/Logs/statictea.log
Other: ~/statictea.log

### File make.server.json command

Make the server.json file with a variable called random.
~~~
printf "{\"random\": \"%s%s%s\"}\n" $RANDOM $RANDOM > server.json
~~~

### File cmd.sh command

~~~
$statictea -l -s server.json \
  -t tmpl.txt -r result >stdout 2>stderr
~~~

### File log.sh command

Find the last random number line in the log file and create a file
from it called random.txt.

~~~
if [[ $OSTYPE == 'darwin'* ]]; then
  log=~/Library/Logs/statictea.log
else
  log=~/statictea.log
fi
tail -200 $log | sed 's/^.*); //' | grep "Random number " | tail -1 >random.txt
~~~

### File tmpl.txt

Template to create the result.txt file with the same random number
line that gets logged.

~~~
$$ nextline
Random number {s.random}
$$ nextline t.output = "log"
Random number {s.random}
~~~

Expected make.server.json == empty
Expected server.json == empty
Expected random.txt == empty
Expected result == empty

### Expected result == random.txt
### Expected stdout == empty
### Expected stderr == empty
