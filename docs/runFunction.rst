===============
runFunction.nim
===============

The module contains all the built in functions.

Index:
------

* type: FunctionPtr__ -- Signature of a statictea function.

* type: FunResultKind__ -- The kind of a FunResult object, either a value or warning.

* type: FunResult__ -- Functions return a FunResult object.

* newFunResultWarn__ -- Create a FunResult containing a warning message.

* newFunResult__ -- Create a FunResult containing a return value.

* `==`__ -- Compare two FunResult objects and return true when equal.

* `$`__ -- Return a string representation of a FunResult object.

* cmpString__ -- Compares two UTF-8 strings.

* funCmp__ -- Compare two values.

* funConcat__ -- Concatentate two or more strings.

* funLen__ -- Return the len of a value.

* funGet__ -- Return a value contained in a list or dictionary.

* funIf__ -- You use the if function to return a value based on a condition.

* funAdd__ -- Return the sum of two or more values.

* funExists__ -- Return 1 when a variable exists in a dictionary, else return 0.

* funCase__ -- <p>The case function returns a value from multiple choices.

* parseVersion__ -- Parse a Statictea version number and return its three components.

* funCmpVersion__ -- <p>Compare two StaticTea type version numbers.

* funFloat__ -- <p>Convert an int or an int number string to a float.

* funInt__ -- Convert a float or a number string to an int.

* funFind__ -- <p>Find a substring in a string and return its position when found.

* funSubstr__ -- <p>Extract a substring from a string.

* funDup__ -- Duplicate a string.

* getFunction__ -- Look up a function by its name.

.. __:

FunctionPtr
-----------

.. code::

 FunctionPtr = proc (parameters: seq[Value]): FunResult

Signature of a statictea function. It takes any number of values and returns a value or a warning message.

.. __:

FunResultKind
-------------

.. code::

 FunResultKind = enum
  frValue, frWarning

The kind of a FunResult object, either a value or warning.

.. __:

FunResult
---------

.. code::

 FunResult = object
  case kind*: FunResultKind
  of frValue:
      value*: Value          ## Return value of the function.
    
  of frWarning:
      warning*: Warning      ## Warning message id.
      parameter*: Natural    ## Index of problem parameter.
      p1*: string            ## Extra warning info.
      p2*: string            ## Extra warning info.
    
  

Functions return a FunResult object.

.. __:

newFunResultWarn
----------------

.. code::

 proc newFunResultWarn(warning: Warning; parameter: Natural = 0; p1: string = "";
                      p2: string = ""): FunResult 

Create a FunResult containing a warning message. The parameter is the index of the problem parameter, or 0. Both p1 and p2 are the optional strings that go with the warning message.

.. __:

newFunResult
------------

.. code::

 proc newFunResult(value: Value): FunResult 

Create a FunResult containing a return value.

.. __:

`==`
----

.. code::

 proc `==`(funResult1: FunResult; funResult2: FunResult): bool 

Compare two FunResult objects and return true when equal.

.. __:

`$`
---

.. code::

 func `$`(funResult: FunResult): string 

Return a string representation of a FunResult object.

.. __:

cmpString
---------

.. code::

 proc cmpString(a, b: string; ignoreCase: bool = false): int 

Compares two UTF-8 strings. Returns 0 when equal, 1 when a is greater than b and -1 when a less than b. Optionally Ignore case.

.. __:

funCmp
------

.. code::

 proc funCmp(parameters: seq[Value]): FunResult 

Compare two values.  The values are either numbers or strings (both the same type), and it returns whether the first parameter is less than, equal to or greater than the second parameter. It returns -1 for less, 0 for equal and 1 for greater than. The optional third parameter compares strings case insensitive when it is 1. Added in version 0.1.0.

.. __:

funConcat
---------

.. code::

 proc funConcat(parameters: seq[Value]): FunResult 

Concatentate two or more strings.  Added in version 0.1.0.

.. __:

funLen
------

.. code::

 proc funLen(parameters: seq[Value]): FunResult 

Return the len of a value. It takes one parameter and returns the number of characters in a string (not bytes), the number of elements in a list or the number of elements in a dictionary.  Added in version 0.1.0.

.. __:

funGet
------

.. code::

 proc funGet(parameters: seq[Value]): FunResult 

Return a value contained in a list or dictionary. You pass two or three parameters, the first is the dictionary or list to use, the second is the dictionary's key name or the list index, and the third optional parameter is the default value when the element doesn't exist. If you don't specify the default, a warning is generated when the element doesn't exist and the statement is skipped.<table frame="void"><tr><th align="left">-p1: dictionary or list</th><td align="left"></td>
</tr>
<tr><th align="left">-p2: string or int</th><td align="left"></td>
</tr>
<tr><th align="left">-p3: optional, any type</th><td align="left"></td>
</tr>
</table><p>Added in version 0.1.0.</p>


.. __:

funIf
-----

.. code::

 proc funIf(parameters: seq[Value]): FunResult 

You use the if function to return a value based on a condition. It has three parameters, the condition, the true case and the false case.<ol class="simple"><li>Condition is an integer.</li>
<li>True case, is the value returned when condition is 1.</li>
<li>Else case, is the value returned when condition is not 1.</li>
</ol>
<p>Added in version 0.1.0.</p>


.. __:

funAdd
------

.. code::

 proc funAdd(parameters: seq[Value]): FunResult 

Return the sum of two or more values.  The parameters must be all integers or all floats.  A warning is generated on overflow. Added in version 0.1.0.

.. __:

funExists
---------

.. code::

 proc funExists(parameters: seq[Value]): FunResult 

Return 1 when a variable exists in a dictionary, else return 0. The first parameter is the dictionary to check and the second parameter is the name of the variable.<table frame="void"><tr><th align="left">-p1: dictionary: The dictionary to use.</th><td align="left"></td>
</tr>
<tr><th align="left">-p2: string: The name (key) to use.</th><td align="left"></td>
</tr>
</table><p>Added in version 0.1.0.</p>


.. __:

funCase
-------

.. code::

 proc funCase(parameters: seq[Value]): FunResult 

<p>The case function returns a value from multiple choices. It requires at least four parameters, the main condition a case pair and the else condition. You can have any number of case pairs with the else case at the end.</p>
<p>The first parameter of a case pair is the condition and the second is the return value when that condition matches the main condition.</p>
<p>When none of the cases match the main condition, the &quot;else&quot; value is returned.  All the conditions must be the same type, either strings or ints and the return values any be any type.</p>
<p>The function compares the conditions left to right and returns the first match.</p>
<table frame="void"><tr><th align="left">-p1c: The main condition value.</th><td align="left"></td>
</tr>
<tr><th align="left">-p2c: The first case condition value.</th><td align="left"></td>
</tr>
<tr><th align="left">-p3v: The return value when p1 equals p2.</th><td align="left"></td>
</tr>
</table><p>...</p>
<table frame="void"><tr><th align="left">-pnc: The last case condition.</th><td align="left"></td>
</tr>
<tr><th align="left">-pnv: The return value when p1 equals pnc.</th><td align="left"></td>
</tr>
<tr><th align="left">-plastv: The &quot;else&quot; value returned when nothing matches.</th><td align="left"></td>
</tr>
</table><p>Added in version 0.1.0.</p>


.. __:

parseVersion
------------

.. code::

 proc parseVersion(version: string): Option[(int, int, int)] 

Parse a Statictea version number and return its three components.

.. __:

funCmpVersion
-------------

.. code::

 proc funCmpVersion(parameters: seq[Value]): FunResult 

<p>Compare two StaticTea type version numbers. Return whether the first parameter is less than, equal to or greater than the second parameter. It returns -1 for less, 0 for equal and 1 for greater than.</p>
<p>StaticTea uses <a class="reference external" href="https://semver.org/">Semantic Versioning</a> with the added restriction that each version component has one to three digits (no letters).</p>
<p>Added in version 0.1.0.</p>


.. __:

funFloat
--------

.. code::

 proc funFloat(parameters: seq[Value]): FunResult 

<p>Convert an int or an int number string to a float.</p>
<p>Added in version 0.1.0.</p>
<p>Note: if you want to convert a number to a string, use the format function.</p>


.. __:

funInt
------

.. code::

 proc funInt(parameters: seq[Value]): FunResult 

Convert a float or a number string to an int.<ul class="simple"><li>p1: value to convert, float or float number string</li>
<li>p2: optional round options. &quot;round&quot; is the default.</li>
</ul>
<p>Round options:</p>
<ul class="simple"><li>&quot;round&quot; - nearest integer</li>
<li>&quot;floor&quot; - integer below (to the left on number line)</li>
<li>&quot;ceiling&quot; - integer above (to the right on number line)</li>
<li>&quot;truncate&quot; - remove decimals</li>
</ul>
<p>Added in version 0.1.0.</p>


.. __:

funFind
-------

.. code::

 proc funFind(parameters: seq[Value]): FunResult 

<p>Find a substring in a string and return its position when found. The first parameter is the string and the second is the substring. The third optional parameter is returned when the substring is not found.  A warning is generated when the substring is missing and no third parameter. Positions start at</p>
<p>0. Added in version 0.1.0.</p>
<p>#+BEGIN_SRC msg = &quot;Tea time at 3:30.&quot; find(msg, &quot;Tea&quot;) =&gt; 0 find(msg, &quot;time&quot;) =&gt; 4 find(msg, &quot;party&quot;, -1) =&gt; -1 find(msg, &quot;party&quot;, len(msg)) =&gt; 17 find(msg, &quot;party&quot;, 0) =&gt; 0 #+END_SRC</p>


.. __:

funSubstr
---------

.. code::

 proc funSubstr(parameters: seq[Value]): FunResult 

<p>Extract a substring from a string.  The first parameter is the string, the second is the substring's starting position and the third is one past the end. The first position is 0. The third parameter is optional and defaults to one past the end of the string. Added in version 0.1.0.</p>
<p>This kind of positioning is called a half-open range that includes the first position but not the second. For example, [3, 7) includes 3, 4, 5, 6. The end minus the start is equal to the length of the substring.</p>


.. __:

funDup
------

.. code::

 proc funDup(parameters: seq[Value]): FunResult 

Duplicate a string. The first parameter is the string to dup and the second parameter is the number of times to duplicate it. Added in version 0.1.0.

.. __:

getFunction
-----------

.. code::

 proc getFunction(functionName: string): Option[FunctionPtr] 

Look up a function by its name.

.. class:: align-center

Document produced from nim doc comments and formatted with Statictea.
