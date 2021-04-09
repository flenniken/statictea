$$ # StaticTea template for generating reStructuredTest from nim doc comments.
$$ #
$$ # Define replacement patterns for the descriptions.
$$ block
$$ : t.maxLines = 20
$$ : g.patterns = list( \
$$ :   "[ ]*@:", h.newline, \
$$ :   "&quot;", '"', \
$$ :   "&gt;", '>', \
$$ :   "&lt;", '<', \
$$ :   "&amp;", '&', \
$$ :   ":linkTextBegin:", '`', \
$$ :   ":linkTextEnd:", '`_', \
$$ :   ":linkTargetBegin:", '.. _`', \
$$ :   ":linkTargetEnd:", '`: https:')

.. raw:: html

  <style>.greenish {color:#5e8f60}</style>
  <style>.code {border: 1px solid #cce0e3;border-radius:6px;margin-left: 0px}</style>

.. role:: greenish

$$ endblock
$$ # Add the title created from the basename
$$ # of the module path in s.orig.
$$ block
$$ : title = substr(s.orig, add(4, find(s.orig, 'src/', -4)));
$$ : titleUnderline = dup("=", add(len(title), len(':greenish:``')))
{titleUnderline}
:greenish:`{title}`
{titleUnderline}
$$ endblock

$$ # Module description.
$$ nextline
$$ : description = replaceRe(s.moduleDescription, g.patterns)
{description}

$$ # Show the index label when there are entries.
$$ block t.output = case(len(s.entries), 0, 'skip', 'result')
:greenish:`Index:`
------------------
$$ endblock
$$ #
$$ #
$$ #
$$ # Index to types and functions.
$$ nextline
$$ : t.repeat = len(s.entries)
$$ : entry = get(s.entries, t.row, dict())
$$ : name = get(entry, "name", "")
$$ : description = get(entry, "description", "")
$$ : skType = get(entry, "type", "")
$$ : type = case(skType, \
$$ :   "skType", "type: ", \
$$ :   "skConst", "const: ", \
$$ :   "skMacro", "macro: ", \
$$ :   "")
$$ : short = substr(description, 0, add(find(description, '.', -1), 1))
* {type}{name}__ -- {short}

$$ # Function and type descriptions.
$$ block
$$ : t.repeat = len(s.entries)
$$ : entry = get(s.entries, t.row)
$$ : name = get(entry, "name", "")
$$ : nameUnderline = dup("-", len(name))
$$ : desc = get(entry, "description", "")
$$ : description = replaceRe(desc, g.patterns)
$$ : code = get(entry, "code", "")
$$ : pos = find(code, "{", len(code))
$$ : signature = substr(code, 0, pos)
$$ : t.maxLines = 100
.. __:

{name}
{nameUnderline}

{description}

.. code::

 {signature}

$$ endblock

$$ # The code block above has code in the json with two space
$$ # indenting on multiple lines.  Indenting the first line two
$$ # spaces makes all the lines line up and it appears there is
$$ # no indentation. If you indent it one space, you can see the
$$ # indentation. You need to indent at least one space. Fix by
$$ # adding spaces to the beginning of lines, except the first.

$$ # Center the bottom lines.

----

.. class:: align-center

:greenish:`StaticTea reStructuredText template for nim doc comments.`

.. class:: align-center

⦿
