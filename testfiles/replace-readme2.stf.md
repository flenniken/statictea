stf file, version 0.1.0

# Readme Replace 2

The second replace readme example.

### File cmd.sh command

~~~
$statictea -j=shared.json -s=server.json -t=replace.html >stdout 2>stderr
~~~

### File replace.html

~~~
<!--$ replace t.content=h.header -->
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

### File shared.json

~~~
{
  "header": "<!DOCTYPE html>
<html lang=\"{s.languageCode}\" dir=\"{s.languageDirection}\">
<head>
<meta charset=\"UTF-8\"/>
<title>{s.title}</title>\n"
}
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

