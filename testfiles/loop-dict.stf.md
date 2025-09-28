stf file, version 0.1.0

# List Loop Dict

Test the loop function where it loops over a list of dictionaries and
creates a dictionary.

### File cmd.sh command

~~~
$statictea \
  -s server.json \
  -o shared.tea \
  -t tmpl.txt \
  -r result \
  >stdout 2>stderr
~~~


### File tmpl.txt

~~~
$$ block dn = string(o.mapping, "dn", "o.mapping")
{dn}
$$ endblock
~~~

### File server.json

~~~
{
  "listOfDicts": [
    {
      "name": "Washington",
      "num": 42,
    },
    {
      "name": "Oregon",
      "num": 33,
    },
  ]
}
~~~

### File shared.tea

~~~ nim
callback = func(ix: int, value: dict, mapping: dict) bool
  ## Map the num to name.
  ## Note: keys must follow the rules for a variable name.
  key = format("n{value.num}")
  mapping[key] = value.name
  return(false)

o.mapping = dict()
loop(s.listOfDicts, o.mapping, callback)
~~~

### File result.expected

~~~
o.mapping.n42 = "Washington"
o.mapping.n33 = "Oregon"
~~~

### Expected result == result.expected
### Expected stdout == empty
### Expected stderr == empty
