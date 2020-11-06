type
  Test = object
    value: int

var test = Test(value: 2)
echo $test

var test2 = Test(value: 2)
echo $test2

if test == test2:
  echo "they're the same"
