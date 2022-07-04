stf file, version 0.1.0

# Readme Replace 3

Test standard readme replace example 3.

### File cmd.sh command

~~~
$statictea -s server.json -o shared.tea \
  -t template.html -r result.html >stdout 2>stderr
~~~

### File template.html

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

### File result.expected

~~~
<!DOCTYPE html>
<html lang="en" dir="ltr">
<head>
<meta charset="UTF-8"/>
<title>Teas in England</title>
~~~

### Expected result.html == result.expected
### Expected stdout == empty
### Expected stderr == empty

