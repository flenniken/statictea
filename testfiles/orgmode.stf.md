stf file, version 0.1.0

# Org Mode Prefix

Test the org mode prefix (# $).

### File cmd.sh command

~~~
$statictea \
  -p "# $" \
  -t orgmode.org \
  >stdout 2>stderr
~~~

### File orgmode.org

~~~
# $ # Testing the org mode prefix.

# $ nextline name = "org mode"
hello {name}

# Normal org mode comment.
~~~

### File stdout.expected

~~~

hello org mode

# Normal org mode comment.
~~~

### Expected stdout.expected == stdout
### Expected stderr == empty

