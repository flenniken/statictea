stf file, version 0.1.0

# t.row

Text the t.row variable.

### File cmd.sh command

~~~
$statictea \
  -l=log.txt \
  -s=server.json \
  -t=tmpl.txt \
  -r=result.html >stdout 2>stderr
~~~

### File log.sh command

~~~
cat log.txt | cut -c 26- | grep "^tmpl.txt" >log.filtered | true
~~~

### File tmpl.txt

~~~
The readme example.

  Here is an example using the row variable.  In the example the
  row is used in three places.

<ul>
<!--$ nextline t.repeat=len(s.companies)-->
<!--$ : company = get(s.companies, t.row) -->
<!--$ : num = add(t.row, 1) -->
  <li id="r{t.row}">{num}. {company}</li>
</ul>
~~~

### File server.json

~~~
{
  "companies": [
    "Mighty Leaf Tea",
    "Numi Organic Tea",
    "Peet's Coffee & Tea",
    "Red Diamond"
  ]
}
~~~

### File shared.json

~~~
{
  "name": "shared",
  "type": "json"
}
~~~

### File result.expected

~~~
The readme example.

  Here is an example using the row variable.  In the example the
  row is used in three places.

<ul>
  <li id="r0">1. Mighty Leaf Tea</li>
  <li id="r1">2. Numi Organic Tea</li>
  <li id="r2">3. Peet's Coffee & Tea</li>
  <li id="r3">4. Red Diamond</li>
</ul>
~~~

### Expected result.expected == result.html
### Expected stdout == empty
### Expected stderr == empty
### Expected log.filtered == empty
