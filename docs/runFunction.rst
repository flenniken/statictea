===============
runFunction.nim
===============

Module containing StaticTea functions.

Index:
------
* type: FunctionPtr_ -- Signature of a statictea function.
* type: FunResultKind_ -- The kind of a FunResult object, either a value or warning.
* type: FunResult_ -- Contains the result of calling a function, either a value or a warning.
* newFunResultWarn_ -- Return a new FunResult object.
* newFunResult_ -- Return a new FunResult object containing a value.
* `==`_ -- Compare two FunResult objects and return true when equal.
* `$`_ -- Return a string representation of a FunResult object.
* cmpString_ -- Compares two UTF-8 strings.
* funCmp_ -- Compare two values.
* funConcat_ -- Concatentate two or more strings.
* funLen_ -- Return the len of a value.
* funGet_ -- Return a value contained in a list or dictionary.
* funIf_ -- You use the if function to return a value based on a condition.
* funAdd_ -- Return the sum of two or more values.
* funExists_ -- Return 1 when a variable exists in a dictionary, else return @:0.
* funCase_ -- The case function returns a value from multiple choices.
* parseVersion_ -- Parse a StaticTea version number and return its three components.
* funCmpVersion_ -- Compare two StaticTea type version numbers.
* funFloat_ -- Convert an int or an int number string to a float.
* funInt_ -- Convert a float or a number string to an int.
* funFind_ -- Find a substring in a string and return its position when found.
* funSubstr_ -- Extract a substring from a string.
* funDup_ -- Duplicate a string.
* funDict_ -- Create a dictionary from a list of key, value pairs.
* funList_ -- Create a list of values.
* funReplace_ -- Replace a part of a string (substring) with another string.
* funReplaceRe_ -- Replace multiple parts of a string defined by regular expressions with replacement strings.
* getFunction_ -- Look up a function by its name.

.. _FunctionPtr:

FunctionPtr
-----------

Signature of a statictea function. It takes any number of values and returns a value or a warning message.

.. code::

 FunctionPtr = proc (parameters: seq[Value]): FunResult 

.. _FunResultKind:

FunResultKind
-------------

The kind of a FunResult object, either a value or warning.

.. code::

 FunResultKind = enum
  frValue, frWarning

.. _FunResult:

FunResult
---------

Contains the result of calling a function, either a value or a warning.

.. code::

 FunResult = object
  case kind*: FunResultKind
  of frValue:
      value*: Value          ## Return value of the function.
    
  of frWarning:
      parameter*: Natural    ## Index of problem parameter.
      warningData*: WarningData

  

.. _newFunResultWarn:

newFunResultWarn
----------------

Return a new FunResult object. It contains a warning, the index of the problem parameter, and the two optional strings that go with the warning.

.. code::

 func newFunResultWarn(warning: Warning; parameter: Natural = 0; p1: string = "";
                      p2: string = ""): FunResult 

.. _newFunResult:

newFunResult
------------

Return a new FunResult object containing a value.

.. code::

 func newFunResult(value: Value): FunResult 

.. _`==`:

`==`
----

Compare two FunResult objects and return true when equal.

.. code::

 func `==`(r1: FunResult; r2: FunResult): bool 

.. _`$`:

`$`
---

Return a string representation of a FunResult object.

.. code::

 func `$`(funResult: FunResult): string 

.. _cmpString:

cmpString
---------

Compares two UTF-8 strings. Returns 0 when equal, 1 when a is greater than b and -1 when a less than b. Optionally Ignore case.

.. code::

 func cmpString(a, b: string; ignoreCase: bool = false): int 

.. _funCmp:

funCmp
------

Compare two values.  The values are either numbers or strings (both the same type), and it returns whether the first parameter is less than, equal to or greater than the second parameter. It returns -1 for less, 0 for equal and 1 for greater than. The optional third parameter compares strings case insensitive when it is 1. Added in version 0.1.0.

.. code::

 func funCmp(parameters: seq[Value]): FunResult 

.. _funConcat:

funConcat
---------

Concatentate two or more strings.  Added in version 0.1.0.

.. code::

 func funConcat(parameters: seq[Value]): FunResult 

.. _funLen:

funLen
------

Return the len of a value. It takes one parameter and returns the number of characters in a string (not bytes), the number of elements in a list or the number of elements in a dictionary.  Added in version 0.1.0.

.. code::

 func funLen(parameters: seq[Value]): FunResult 

.. _funGet:

funGet
------

Return a value contained in a list or dictionary. You pass two or three parameters, the first is the dictionary or list to use, the second is the dictionary's key name or the list index, and the third optional parameter is the default value when the element doesn't exist. If you don't specify the default, a warning is generated when the element doesn't exist and the statement is skipped. Added in version 0.1.0.

Get Dictionary Item:

- p1: dictionary to search
- p2: variable (key name) to find
- p3: optional default value returned when key is missing

Get List Item:

- p1: list to use
- p2: index of item in the list
- p3: optional default value returned when index is too big

.. code::

 func funGet(parameters: seq[Value]): FunResult 

.. _funIf:

funIf
-----

You use the if function to return a value based on a condition. It has three parameters, the condition, the true case and the false case. Added in version 0.1.0.

- p1: the integer condition
- p2: true case: the value returned when condition is 1
- p3: else case: the value returned when condition is not 1.

.. code::

 func funIf(parameters: seq[Value]): FunResult 

.. _funAdd:

funAdd
------

Return the sum of two or more values.  The parameters must be all integers or all floats.  A warning is generated on overflow. Added in version 0.1.0.

.. code::

 func funAdd(parameters: seq[Value]): FunResult 

.. _funExists:

funExists
---------

Return 1 when a variable exists in a dictionary, else return
0. The first parameter is the dictionary to check and the second
parameter is the name of the variable. Added in version 0.1.0.

- p1: dictionary: the dictionary containing the variable
- p2: string: the variable name (key name) to look for

.. code::

 func funExists(parameters: seq[Value]): FunResult 

.. _funCase:

funCase
-------

The case function returns a value from multiple choices. It takes a main condition, any number of case pairs then an optional else value.

The first parameter of a case pair is the condition and the second is the return value when that condition matches the main condition. The function compares the conditions left to right and returns the first match.

When none of the cases match the main condition, the "else" value is returned. If none match and the else is missing, a warning is generated and the statement is skipped. The conditions must be integers or strings. The return values can be any type. Added in version 0.1.0.

- p1: the main condition value
- p2: the first case condition
- p3: the first case value

- ...

- pn-2: the last case condition
- pn-1: the last case value
- pn: the optional "else" value returned when nothing matches

.. code::

 func funCase(parameters: seq[Value]): FunResult 

.. _parseVersion:

parseVersion
------------

Parse a StaticTea version number and return its three components.

.. code::

 func parseVersion(version: string): Option[(int, int, int)] 

.. _funCmpVersion:

funCmpVersion
-------------

Compare two StaticTea type version numbers. Return whether the first parameter is less than, equal to or greater than the second parameter. It returns -1 for less, 0 for equal and 1 for greater than.

StaticTea uses `Semantic Versioning`_ with the added restriction that each version component has one to three digits (no letters). Added in version 0.1.0.

 .. _`Semantic Versioning`: https://semver.org/

.. code::

 func funCmpVersion(parameters: seq[Value]): FunResult 

.. _funFloat:

funFloat
--------

Convert an int or an int number string to a float.  Added in version 0.1.0.

.. note::
  Use the format function to convert a number to a string.

.. code::

 func funFloat(parameters: seq[Value]): FunResult 

.. _funInt:

funInt
------

Convert a float or a number string to an int. Added in version 0.1.0.

- p1: value to convert, float or float number string
- p2: optional round options. "round" is the default.

Round options:

- "round" - nearest integer
- "floor" - integer below (to the left on number line)
- "ceiling" - integer above (to the right on number line)
- "truncate" - remove decimals

.. code::

 func funInt(parameters: seq[Value]): FunResult 

.. _funFind:

funFind
-------

Find a substring in a string and return its position when found. The first parameter is the string and the second is the substring. The third optional parameter is returned when the substring is not found.  A warning is generated when the substring is missing and no third parameter. Positions start at
0. Added in version 0.1.0.

.. code::

  msg = "Tea time at 3:30."
         0123456789 1234567
  find(msg, "Tea") => 0
  find(msg, "time") => 4
  find(msg, "party", -1) => -1
  find(msg, "party", len(msg)) => 17
  find(msg, "party", 0) => 0

.. code::

 func funFind(parameters: seq[Value]): FunResult 

.. _funSubstr:

funSubstr
---------

Extract a substring from a string.  The first parameter is the string, the second is the substring's starting position and the third is one past the end. The first position is 0. The third parameter is optional and defaults to one past the end of the string. Added in version 0.1.0.

This kind of positioning is called a half-open range that includes the first position but not the second. For example, [3, 7) includes 3, 4, 5, 6. The end minus the start is equal to the length of the substring.

.. code::

 func funSubstr(parameters: seq[Value]): FunResult 

.. _funDup:

funDup
------

Duplicate a string. The first parameter is the string to dup and the second parameter is the number of times to duplicate it. Added in version 0.1.0.

.. code::

 func funDup(parameters: seq[Value]): FunResult 

.. _funDict:

funDict
-------

Create a dictionary from a list of key, value pairs. You can specify as many pairs as you want. The keys must be strings and the values can be any type. Added in version 0.1.0.

.. code::

  dict("a", 5) => {"a": 5}
  dict("a", 5, "b", 33, "c", 0) =>
      {"a": 5, "b": 33, "c": 0}

.. code::

 func funDict(parameters: seq[Value]): FunResult 

.. _funList:

funList
-------

Create a list of values. You can specify as many variables as you want.  Added in version 0.1.0.

.. code::

  list(1) => [1]
  list(1, 2, 3) => [1, 2, 3]
  list("a", 5, "b") => ["a", 5, "b"]

.. code::

 func funList(parameters: seq[Value]): FunResult 

.. _funReplace:

funReplace
----------

Replace a part of a string (substring) with another string.

The first parameter is the string, the second is the substring's starting position, starting a 0, the third is the length of the substring and the fourth is the replacement string.

.. code::

  replace("Earl Grey", 5, 4, "of Sandwich")
    => "Earl of Sandwich"
  replace("123", 0, 0, "abcd") => abcd123
  replace("123", 0, 1, "abcd") => abcd23
  replace("123", 0, 2, "abcd") => abcd3
  replace("123", 0, 3, "abcd") => abcd
  replace("123", 3, 0, "abcd") => 123abcd
  replace("123", 2, 1, "abcd") => 12abcd
  replace("123", 1, 2, "abcd") => 1abcd
  replace("123", 0, 3, "abcd") => abcd
  replace("123", 1, 0, "abcd") => 1abcd23
  replace("123", 1, 1, "abcd") => 1abcd3
  replace("123", 1, 2, "abcd") => 1abcd
  replace("", 0, 0, "abcd") => abcd
  replace("", 0, 0, "abc") => abc
  replace("", 0, 0, "ab") => ab
  replace("", 0, 0, "a") => a
  replace("", 0, 0, "") =>
  replace("123", 0, 0, "") => 123
  replace("123", 0, 1, "") => 23
  replace("123", 0, 2, "") => 3
  replace("123", 0, 3, "") =>

.. code::

 func funReplace(parameters: seq[Value]): FunResult 

.. _funReplaceRe:

funReplaceRe
------------

Replace multiple parts of a string defined by regular expressions with replacement strings.

The basic case uses one replacement pattern. It takes three
parameters, the first parameter is the string to work on, the
second is the regular expression pattern, and the fourth is the
replacement string.

In general you can have multiple sets of patterns and associated
replacements. You add each pair of parameters at the end.

.. code::

  replaceRe("abcdefabc", "abc", "456")
    => "456def456"
  replaceRe("abcdefabc", "abc", "456", "def", "")
    => "456456"

.. code::

 func funReplaceRe(parameters: seq[Value]): FunResult 

.. _getFunction:

getFunction
-----------

Look up a function by its name.

.. code::

 proc getFunction(functionName: string): Option[FunctionPtr] 



.. class:: align-center

= StaticTea reStructuredText template for nim doc comments. =
