stf file, version 0.1.0

# Test Int Type

Test the int type.

### File cmd.sh command nonZeroReturn

~~~
$statictea \
  -s=server.json \
  -t=tmpl.txt \
  -r=result >stdout 2>stderr
~~~

### File tmpl.txt

~~~
$$ block
$$ : a = 5
$$ : b = -5
$$ : zero = 0
$$ : big = 123456789
$$ : bigminus = -123456789
$$ : max = 9_223_372_036_854_775_807
$$ : min = -9_223_372_036_854_775_808
5 == {a} == {s.five}
-5 == {b} == {s.negative5}
0 = {zero}
123456789 =
{big}

-123456789 =
{bigminus}

 {max} = 9_223_372_036_854_775_807
{min} = -9_223_372_036_854_775_808
$$ endblock

Try one more than the max and one less than the min.
$$ block
$$ : maxPlus1 = 9_223_372_036_854_775_808
$$ : minMinus1 = -9_223_372_036_854_775_809
$$ endblock
~~~

### File server.json

~~~
{
  "five": 5,
  "negative5": -5
}
~~~

### File result.expected

~~~
5 == 5 == 5
-5 == -5 == -5
0 = 0
123456789 =
123456789

-123456789 =
-123456789

 9223372036854775807 = 9_223_372_036_854_775_807
-9223372036854775808 = -9_223_372_036_854_775_808

Try one more than the max and one less than the min.
~~~

### File stderr.expected

~~~
tmpl.txt(24): w27: The number is too big or too small.
statement: maxPlus1 = 9_223_372_036_854_775_808
                      ^
tmpl.txt(25): w27: The number is too big or too small.
statement: minMinus1 = -9_223_372_036_854_775_809
                       ^
~~~

### Expected result == result.expected
### Expected stdout == empty
### Expected stderr == stderr.expected
