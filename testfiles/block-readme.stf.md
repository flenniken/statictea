stf file, version 0.1.0

# Readme Block Example

Test the readme block example.

### File cmd.sh command

~~~
$statictea \
  -s block.json \
  -t block.html \
  >stdout 2>stderr
~~~

### File block.html

~~~
<!--$ block -->
Join our tea party on
{s.weekday} at {s.name}'s
house at {s.time}.
<!--$ endblock -->
~~~

### File block.json

~~~
{
  "weekday": "Friday",
  "name": "John",
  "time": "5:00 pm"
}
~~~

### File stdout.expected

~~~
Join our tea party on
Friday at John's
house at 5:00 pm.
~~~

### Expected stdout == stdout.expected
### Expected stderr == empty
