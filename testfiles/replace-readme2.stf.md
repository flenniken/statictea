stf file, version 0.1.0

# Readme Replace 2

The second replace readme example.

### File cmd.sh command

~~~
$statictea -o shared.tea -s server.json -t replace.html >stdout 2>stderr
~~~

### File replace.html

~~~
<!--$ replace t.content=o.header -->
<!DOCTYPE html>
<html lang="{s.languageCode}" dir="{s.languageDirection}">
<head>
<meta charset="UTF-8"/>
<title>{s.title}</title>
<--$ endblock -->
~~~

### File server.json

~~~
{
"languageCode": "en",
"languageDirection": "ltr",
"title": "Teas in England"
}
~~~

### File shared.tea

~~~
o.header = """
<!DOCTYPE html>
<html lang="{s.languageCode}" dir="{s.languageDirection}">
<head>
<meta charset="UTF-8"/>
<title>{s.title}</title>
"""
~~~

### File stdout.expected

~~~
<!DOCTYPE html>
<html lang="en" dir="ltr">
<head>
<meta charset="UTF-8"/>
<title>Teas in England</title>
~~~

### Expected stdout == stdout.expected
### Expected stderr == empty

