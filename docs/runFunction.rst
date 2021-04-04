===============
runFunction.nim
===============

This module contains all the built in functions.

Index:
------
* type: FunctionPtr_ -- Signature of a statictea function.
* type: FunResultKind_ -- The kind of a FunResult object, either a value or warning.
* type: FunResult_ -- Contains the result of calling a function, either a value or a warning.
* newFunResultWarn_ -- Return a new FunResult object containing a warning, the index of the problem parameter, and the two optional strings that go with the warning.
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
* funExists_ -- Return 1 when a variable exists in a dictionary, else return 0.
* funCase_ -- <p>The case function returns a value from multiple choices.
* parseVersion_ -- Parse a StaticTea version number and return its three components.
* funCmpVersion_ -- <p>Compare two StaticTea type version numbers.
* funFloat_ -- <p>Convert an int or an int number string to a float.
* funInt_ -- Convert a float or a number string to an int.
* funFind_ -- <p>Find a substring in a string and return its position when found.
* funSubstr_ -- <p>Extract a substring from a string.
* funDup_ -- Duplicate a string.
* funDict_ -- <p>Create a dictionary from a list of key, value pairs.
* funList_ -- <p>Create a list of values.
* funReplace_ -- <p>Replace a part of a string (substring) with another string.
* funReplaceRe_ -- <p>Replace multiple parts of a string defined by regular expressions with replacement strings.
* getFunction_ -- Look up a function by its name.

.. _FunctionPtr:

FunctionPtr
---------------

Signature of a statictea function. It takes any number of values and returns a value or a warning message.

.. code::

 FunctionPtr = proc (parameters: seq[Value]): FunResult 

.. _FunResultKind:

FunResultKind
-----------------

The kind of a FunResult object, either a value or warning.

.. code::

 FunResultKind = enum
  frValue, frWarning

.. _FunResult:

FunResult
-------------

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
--------------------

Return a new FunResult object containing a warning, the index of the problem parameter, and the two optional strings that go with the warning.

.. code::

 func newFunResultWarn(warning: Warning; parameter: Natural = 0; p1: string = "";
                      p2: string = ""): FunResult 

.. _newFunResult:

newFunResult
----------------

Return a new FunResult object containing a value.

.. code::

 func newFunResult(value: Value): FunResult 

.. _`==`:

`==`
--------

Compare two FunResult objects and return true when equal.

.. code::

 func `==`(r1: FunResult; r2: FunResult): bool 

.. _`$`:

`$`
-------

Return a string representation of a FunResult object.

.. code::

 func `$`(funResult: FunResult): string 

.. _cmpString:

cmpString
-------------

Compares two UTF-8 strings. Returns 0 when equal, 1 when a is greater than b and -1 when a less than b. Optionally Ignore case.

.. code::

 func cmpString(a, b: string; ignoreCase: bool = false): int 

.. _funCmp:

funCmp
----------

Compare two values.  The values are either numbers or strings (both the same type), and it returns whether the first parameter is less than, equal to or greater than the second parameter. It returns -1 for less, 0 for equal and 1 for greater than. The optional third parameter compares strings case insensitive when it is 1. Added in version 0.1.0.

.. code::

 func funCmp(parameters: seq[Value]): FunResult 

.. _funConcat:

funConcat
-------------

Concatentate two or more strings.  Added in version 0.1.0.

.. code::

 func funConcat(parameters: seq[Value]): FunResult 

.. _funLen:

funLen
----------

Return the len of a value. It takes one parameter and returns the number of characters in a string (not bytes), the number of elements in a list or the number of elements in a dictionary.  Added in version 0.1.0.

.. code::

 func funLen(parameters: seq[Value]): FunResult 

.. _funGet:

funGet
----------

Return a value contained in a list or dictionary. You pass two or three parameters, the first is the dictionary or list to use, the second is the dictionary's key name or the list index, and the third optional parameter is the default value when the element doesn't exist. If you don't specify the default, a warning is generated when the element doesn't exist and the statement is skipped. Added in version 0.1.0.

Get Dictionary Item:

- p1: dictionary to search
- p2: variable (key name) to find
- p3: default value returned when key is missing

Get List Item:

- p1: list to use
- p2: index of item in the list
- p3: default value returned when index is too big

.. code::

 func funGet(parameters: seq[Value]): FunResult 

.. _funIf:

funIf
---------

You use the if function to return a value based on a condition. It has three parameters, the condition, the true case and the false case.<ol class="simple"><li>Condition is an integer.</li>
<li>True case, is the value returned when condition is 1.</li>
<li>Else case, is the value returned when condition is not 1.</li>
</ol>
<p>Added in version 0.1.0.</p>


.. code::

 func funIf(parameters: seq[Value]): FunResult 

.. _funAdd:

funAdd
----------

Return the sum of two or more values.  The parameters must be all integers or all floats.  A warning is generated on overflow. Added in version 0.1.0.

.. code::

 func funAdd(parameters: seq[Value]): FunResult 

.. _funExists:

funExists
-------------

Return 1 when a variable exists in a dictionary, else return 0. The first parameter is the dictionary to check and the second parameter is the name of the variable.<table frame="void"><tr><th align="left">-p1: dictionary: The dictionary to use.</th><td align="left"></td>
</tr>
<tr><th align="left">-p2: string: The name (key) to use.</th><td align="left"></td>
</tr>
</table><p>Added in version 0.1.0.</p>


.. code::

 func funExists(parameters: seq[Value]): FunResult 

.. _funCase:

funCase
-----------

<p>The case function returns a value from multiple choices. It takes a main condition, any number of case pairs then an optional else value.</p>
<p>The first parameter of a case pair is the condition and the second is the return value when that condition matches the main condition.</p>
<p>When none of the cases match the main condition, the &quot;else&quot; value is returned. If none match and the else is missing, a warning is generated and the statement is skipped. The conditions must be integers or strings. The return values any be any type.</p>
<p>The function compares the conditions left to right and returns the first match.</p>
<table frame="void"><tr><th align="left">-p1: The main condition value.</th><td align="left"></td>
</tr>
<tr><th align="left">-p2: Case condition.</th><td align="left"></td>
</tr>
<tr><th align="left">-p3: Case value.</th><td align="left"></td>
</tr>
</table><p>...</p>
<table frame="void"><tr><th align="left">-pn-2: The last case condition.</th><td align="left"></td>
</tr>
<tr><th align="left">-pn-1: The case value.</th><td align="left"></td>
</tr>
<tr><th align="left">-pn: The optional &quot;else&quot; value returned when nothing matches.</th><td align="left"></td>
</tr>
</table><p>Added in version 0.1.0.</p>


.. code::

 func funCase(parameters: seq[Value]): FunResult 

.. _parseVersion:

parseVersion
----------------

Parse a StaticTea version number and return its three components.

.. code::

 func parseVersion(version: string): Option[(int, int, int)] 

.. _funCmpVersion:

funCmpVersion
-----------------

<p>Compare two StaticTea type version numbers. Return whether the first parameter is less than, equal to or greater than the second parameter. It returns -1 for less, 0 for equal and 1 for greater than.</p>
<p>StaticTea uses <a class="reference external" href="https://semver.org/">Semantic Versioning</a> with the added restriction that each version component has one to three digits (no letters).</p>
<p>Added in version 0.1.0.</p>


.. code::

 func funCmpVersion(parameters: seq[Value]): FunResult 

.. _funFloat:

funFloat
------------

<p>Convert an int or an int number string to a float.</p>
<p>Added in version 0.1.0.</p>
<p>Note: if you want to convert a number to a string, use the format function.</p>


.. code::

 func funFloat(parameters: seq[Value]): FunResult 

.. _funInt:

funInt
----------

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


.. code::

 func funInt(parameters: seq[Value]): FunResult 

.. _funFind:

funFind
-----------

<p>Find a substring in a string and return its position when found. The first parameter is the string and the second is the substring. The third optional parameter is returned when the substring is not found.  A warning is generated when the substring is missing and no third parameter. Positions start at</p>
<p>0. Added in version 0.1.0.</p>
<p>#+BEGIN_SRC msg = &quot;Tea time at 3:30.&quot; find(msg, &quot;Tea&quot;) =&gt; 0 find(msg, &quot;time&quot;) =&gt; 4 find(msg, &quot;party&quot;, -1) =&gt; -1 find(msg, &quot;party&quot;, len(msg)) =&gt; 17 find(msg, &quot;party&quot;, 0) =&gt; 0 #+END_SRC</p>


.. code::

 func funFind(parameters: seq[Value]): FunResult 

.. _funSubstr:

funSubstr
-------------

<p>Extract a substring from a string.  The first parameter is the string, the second is the substring's starting position and the third is one past the end. The first position is 0. The third parameter is optional and defaults to one past the end of the string. Added in version 0.1.0.</p>
<p>This kind of positioning is called a half-open range that includes the first position but not the second. For example, [3, 7) includes 3, 4, 5, 6. The end minus the start is equal to the length of the substring.</p>


.. code::

 func funSubstr(parameters: seq[Value]): FunResult 

.. _funDup:

funDup
----------

Duplicate a string. The first parameter is the string to dup and the second parameter is the number of times to duplicate it. Added in version 0.1.0.

.. code::

 func funDup(parameters: seq[Value]): FunResult 

.. _funDict:

funDict
-----------

<p>Create a dictionary from a list of key, value pairs. You can specify as many pair as you want. The keys must be strings and the values and be any type. Added in version 0.1.0.</p>
<p>dict(&quot;a&quot;, 5) =&gt; {&quot;a&quot;: 5} dict(&quot;a&quot;, 5, &quot;b&quot;, 33, &quot;c&quot;, 0) =&gt; {&quot;a&quot;: 5, &quot;b&quot;: 33, &quot;c&quot;: 0}} </p>


.. code::

 func funDict(parameters: seq[Value]): FunResult 

.. _funList:

funList
-----------

<p>Create a list of values. You can specify as many variables as you want.  Added in version 0.1.0.</p>
<p>list(1) =&gt; [1] list(1, 2, 3) =&gt; [1, 2, 3] list(&quot;a&quot;, 5, &quot;b&quot;) =&gt; [&quot;a&quot;, 5, &quot;b&quot;] </p>


.. code::

 func funList(parameters: seq[Value]): FunResult 

.. _funReplace:

funReplace
--------------

<p>Replace a part of a string (substring) with another string.</p>
<p>The first parameter is the string, the second is the substring's starting position, starting a 0, the third is the length of the substring and the fourth is the replacement string.</p>
<dl class="docutils"><dt>replace(&quot;Earl Grey&quot;, 5, 4, &quot;of Sandwich&quot;)</dt>
<dd>=&gt; &quot;Earl of Sandwich&quot;</dd>
</dl>
<p>replace(&quot;123&quot;, 0, 0, &quot;abcd&quot;) =&gt; abcd123 replace(&quot;123&quot;, 0, 1, &quot;abcd&quot;) =&gt; abcd23 replace(&quot;123&quot;, 0, 2, &quot;abcd&quot;) =&gt; abcd3 replace(&quot;123&quot;, 0, 3, &quot;abcd&quot;) =&gt; abcd replace(&quot;123&quot;, 3, 0, &quot;abcd&quot;) =&gt; 123abcd replace(&quot;123&quot;, 2, 1, &quot;abcd&quot;) =&gt; 12abcd replace(&quot;123&quot;, 1, 2, &quot;abcd&quot;) =&gt; 1abcd replace(&quot;123&quot;, 0, 3, &quot;abcd&quot;) =&gt; abcd replace(&quot;123&quot;, 1, 0, &quot;abcd&quot;) =&gt; 1abcd23 replace(&quot;123&quot;, 1, 1, &quot;abcd&quot;) =&gt; 1abcd3 replace(&quot;123&quot;, 1, 2, &quot;abcd&quot;) =&gt; 1abcd replace(&quot;&quot;, 0, 0, &quot;abcd&quot;) =&gt; abcd replace(&quot;&quot;, 0, 0, &quot;abc&quot;) =&gt; abc replace(&quot;&quot;, 0, 0, &quot;ab&quot;) =&gt; ab replace(&quot;&quot;, 0, 0, &quot;a&quot;) =&gt; a replace(&quot;&quot;, 0, 0, &quot;&quot;) =&gt; replace(&quot;123&quot;, 0, 0, &quot;&quot;) =&gt; 123 replace(&quot;123&quot;, 0, 1, &quot;&quot;) =&gt; 23 replace(&quot;123&quot;, 0, 2, &quot;&quot;) =&gt; 3 replace(&quot;123&quot;, 0, 3, &quot;&quot;) =&gt;</p>


.. code::

 func funReplace(parameters: seq[Value]): FunResult 

.. _funReplaceRe:

funReplaceRe
----------------

<p>Replace multiple parts of a string defined by regular expressions with replacement strings.</p>
<p>The basic case uses one replacement pattern. It takes three parameters, the first parameter is the string to work on, the second is the regular expression pattern, and the fourth is the replacement string.</p>
<p>In general you can have multiple sets of patterns and associated replacements. You add each pair of parameters at the end.</p>
<dl class="docutils"><dt>replaceRe(&quot;abcdefabc&quot;, &quot;abc&quot;, &quot;456&quot;)</dt>
<dd>=&gt; &quot;456def456&quot;</dd>
<dt>replaceRe(&quot;abcdefabc&quot;, &quot;abc&quot;, &quot;456&quot;, &quot;def&quot;, &quot;&quot;)</dt>
<dd>=&gt; &quot;456456&quot;</dd>
</dl>


.. code::

 func funReplaceRe(parameters: seq[Value]): FunResult 

.. _getFunction:

getFunction
---------------

Look up a function by its name.

.. code::

 proc getFunction(functionName: string): Option[FunctionPtr] 



.. class:: align-center

Document produced from nim doc comments and formatted with StaticTea.
