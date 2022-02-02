stf file, version 0.1.0

# Readme Nextline Example

The nextline readme example.

### File cmd.sh command

~~~
$statictea -s=nextline.json -t=nextline.html >stdout 2>stderr
~~~

### File nextline.html

~~~
<!--$ nextline -->
Drink {s.drink} -- {s.drinkType} is my favorite.
~~~

### File nextline.json

~~~
{
  "drink": "tea",
  "drinkType": "Earl Grey"
}
~~~

### File stdout.expected

~~~
Drink tea -- Earl Grey is my favorite.
~~~

### Expected stdout.expected == stdout
### Expected stderr == empty

