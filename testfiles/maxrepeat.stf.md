stf file, version 0.1.0

# maxRepeat

Test the t maxRepeat tea variable.

### File cmd.sh command nonZeroReturn

~~~
$statictea -t template.html -r result.html >stdout 2>stderr
~~~

### File template.html

~~~
Set max repeat to 3 then repeat to 4. Expect one line.
$$ nextline
$$ : t.maxRepeat = 3
$$ : t.repeat = 4
hello

Set max repeat to 3 then repeat to 3. Expect 3 lines.
$$ nextline
$$ : t.maxRepeat = 3
$$ : t.repeat = 3
hello

Set max repeat to 3 then repeat to -1. Expect 1 line.
$$ nextline
$$ : t.maxRepeat = 3
$$ : t.repeat = -1
hello

Set max repeat to 3 then repeat to 0. Expect no lines.
$$ nextline
$$ : t.maxRepeat = 3
$$ : t.repeat = 0
hidden

Set max repeat to 3 then repeat to 2. Expect 2 lines.
$$ nextline
$$ : t.maxRepeat = 3
$$ : t.repeat = 2
t.maxRepeat = {t.maxRepeat}, t.repeat = {t.repeat}

Repeat and max repeat are not set by default. Expect 1 line and warnings.
$$ nextline
t.maxRepeat = {t.maxRepeat}, t.repeat = {t.repeat}

Set max repeat to 0. Expect 1 line and a warning.
$$ nextline
$$ : t.maxRepeat = 0
hello

Set max repeat to -1. Expect 1 line and a warning.
$$ nextline
$$ : t.maxRepeat = -1
hello

Set repeat to 2 and max repeat to 1. Expect 2 lines and a warning.
$$ nextline
$$ : t.repeat = 2
$$ : t.maxRepeat = 1
hello

Set max repeat to 1 then repeat to 2. Expect 1 line and a warning.
$$ nextline
$$ : t.maxRepeat = 1
$$ : t.repeat = 2
hello

Set max repeat to 2 then set it to 1. Expect 1 line and a warning.
$$ nextline
$$ : t.maxRepeat = 2
$$ : t.maxRepeat = 1
hello
~~~

### File result.expected

~~~
Set max repeat to 3 then repeat to 4. Expect one line.
hello

Set max repeat to 3 then repeat to 3. Expect 3 lines.
hello
hello
hello

Set max repeat to 3 then repeat to -1. Expect 1 line.
hello

Set max repeat to 3 then repeat to 0. Expect no lines.

Set max repeat to 3 then repeat to 2. Expect 2 lines.
t.maxRepeat = 3, t.repeat = 2
t.maxRepeat = 3, t.repeat = 2

Repeat and max repeat are not set by default. Expect 1 line and warnings.
t.maxRepeat = {t.maxRepeat}, t.repeat = {t.repeat}

Set max repeat to 0. Expect 1 line and a warning.
hello

Set max repeat to -1. Expect 1 line and a warning.
hello

Set repeat to 2 and max repeat to 1. Expect 2 lines and a warning.
hello
hello

Set max repeat to 1 then repeat to 2. Expect 1 line and a warning.
hello

Set max repeat to 2 then set it to 1. Expect 1 line and a warning.
hello
~~~

### File stderr.expected

~~~
template.html(4): w44: The variable t.repeat must be an integer between 0 and t.maxRepeat.
statement: t.repeat = 4
           ^
template.html(16): w44: The variable t.repeat must be an integer between 0 and t.maxRepeat.
statement: t.repeat = -1
           ^
template.html(33): w58: The replacement variable doesn't exist: t.maxRepeat.
template.html(33): w58: The replacement variable doesn't exist: t.repeat.
template.html(37): w67: The maxRepeat value must be greater than or equal to t.repeat.
statement: t.maxRepeat = 0
           ^
template.html(42): w67: The maxRepeat value must be greater than or equal to t.repeat.
statement: t.maxRepeat = -1
           ^
template.html(48): w67: The maxRepeat value must be greater than or equal to t.repeat.
statement: t.maxRepeat = 1
           ^
template.html(48): w67: The maxRepeat value must be greater than or equal to t.repeat.
statement: t.maxRepeat = 1
           ^
template.html(54): w44: The variable t.repeat must be an integer between 0 and t.maxRepeat.
statement: t.repeat = 2
           ^
template.html(60): w129: You cannot reassign a variable.
statement: t.maxRepeat = 1
           ^
~~~

### Expected result.expected == result.html
### Expected stdout == empty
### Expected stderr.expected == stderr

