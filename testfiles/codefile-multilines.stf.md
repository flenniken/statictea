stf file, version 0.1.0

# Multiline Strings

Test multiline strings.

### File cmd.sh command nonZeroReturn

~~~
$statictea \
  -s server.json \
  -o shared.tea \
  -t tmpl.txt \
  -r result \
  >stdout 2>stderr
~~~

### File server.json

~~~
{
  "languageCode": "en",
  "languageDirection": "ltr",
  "title": "tester"
}
~~~

### File tmpl.txt

~~~
$$ block
{o.header}
$$ endblock

$$ replace t.content = o.header2
$$ endblock

$$ block str = """invalid in template"""
$$ endblock

$$ block str = """+
$$ : still invalid in template"""
$$ endblock

$$ block
{o.middle-quotes}
{o.a} = 5
$$ endblock
~~~

### File shared.tea

~~~
o.header = """
<!doctype html>
<html lang="en">
"""

str1 = """
All the tea in China.
"""
str2 = "All the tea in China.\n"
if((str1 != str2), warn("error1"))

str3 = """
All the tea in China."""
str4 = "All the tea in China."
if((str3 != str4), warn("error1"))

str5 = """
Teas of China
"""
count = len(str5)
if((count != 14), warn(format("unexpected count: {count}")))

o.header2 = """
<!DOCTYPE html>
<html lang="{s.languageCode}" dir="{s.languageDirection}">
<head>
<meta charset="UTF-8"/>
<title>{s.title}</title>
"""

o.middle-quotes = """
"quotes"" """ in the middle are ok"
"""

# Commented out lines with ending triple quotes.
#first-line = """invalid"""

o.a = 5
~~~

### File result.expected

~~~
<!doctype html>
<html lang="en">


<!DOCTYPE html>
<html lang="en" dir="ltr">
<head>
<meta charset="UTF-8"/>
<title>tester</title>



"quotes"" """ in the middle are ok"

5 = 5
~~~

### File stdout.expected

~~~
~~~

### File stderr.expected

~~~
tmpl.txt(8): w185: A multiline string's leading and ending triple quotes must end the line.
statement: str = """invalid in template"""
                    ^
tmpl.txt(11): w185: A multiline string's leading and ending triple quotes must end the line.
statement: str = """still invalid in template"""
                    ^
~~~

### Expected result == result.expected
### Expected stdout == stdout.expected
### Expected stderr == stderr.expected
