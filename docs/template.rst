$$ # StaticTea template to generate reStructuredTest from nim doc comments.
$$ #
$$ # Add the title. Create the title from the basename
$$ # of the module path in s.orig.
$$ block
$$ : title = substr(s.orig, add(4, find(s.orig, 'src/', -4)));
$$ : titleLine = dup("=", len(title))
{titleLine}
{title}
{titleLine}
$$ endblock

$$ # Module description.
$$ nextline
{s.moduleDescription}

$$ # Show the index when there are entries.
$$ block t.output = case(len(s.entries), 0, 'skip', 'result')
Index:
------
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
* {type}{name}_ -- {short}

$$ # Function and type descriptions.
$$ block \
$$ : t.repeat = len(s.entries)
$$ : entry = get(s.entries, t.row)
$$ : name = get(entry, "name", "")
$$ : nameUnderline = dup("-", add(len(name), 4))
$$ : desc = get(entry, "description", "")
$$ : description = replaceRe(desc, \
$$ :   "[ ]*@:", h.newline, \
$$ :   "&quot;", '"', \
$$ :   "&gt;", '>', \
$$ :   "&lt;", '<', \
$$ :   "&amp;", '&', \
$$ :   ":linkTextBegin:", '`', \
$$ :   ":linkTextEnd:", '`_', \
$$ :   ":linkTargetBegin:", '.. _`', \
$$ :   ":linkTargetEnd:", '`: https:')
$$ : code = get(entry, "code", "")
$$ : pos = find(code, "{", len(code))
$$ : signature = substr(code, 0, pos)
$$ : t.maxLines = 100
.. _{name}:

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

$$ # Center the bottom line.
.. class:: align-center

Document produced from nim doc comments and formatted with StaticTea.
