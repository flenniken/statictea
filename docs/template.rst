$$ # StaticTea template to generate reStructuredTest from nim doc comments.
$$ #
$$ # Title
$$ block \
$$ : title = substr(s.orig, add(4, find(s.orig, 'src/', -4))); \
$$ : titleOverline = dup("=", len(title))
{titleOverline}
{title}
{titleOverline}
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
$$ block \
$$ : t.repeat = len(s.entries); \
$$ : entry = get(s.entries, t.row, t.shared); \
$$ : name = get(entry, "name", ""); \
$$ : description = get(entry, "description", ""); \
$$ : skType = get(entry, "type", ""); \
$$ : type = case(skType, "skType", \
$$ :   "type: ", "skConst", "const: ", \
$$ :   "skMacro", "macro: ", \
$$ :   ""); \
$$ : short = substr(description, 0, add(find(description, '.', -1), 1))

* {type}{name}__ -- {short}
$$ endblock

$$ # Function and type descriptions.
$$ block \
$$ : t.repeat = len(s.entries); \
$$ : entry = get(s.entries, t.row, t.shared); \
$$ : name = get(entry, "name", ""); \
$$ : nameUnderline = dup("-", len(name)); \
$$ : description = get(entry, "description", ""); \
$$ : code = get(entry, "code", ""); \
$$ : pos = find(code, "{", len(code)); \
$$ : signature = substr(code, 0, pos); \
$$ : t.maxLines = 100
.. __:

{name}
{nameUnderline}

.. code::

 {signature}

{description}

$$ endblock
$$ # The code block above has code in the json with two space
$$ # indenting on multiple lines.  Indenting the first line two spaces
$$ # makes all the lines line up. If you indent it one space, you can
$$ # see the indentation. You need to indent at least one space.
$$ # Fix by adding spaces to the beginning of lines, except the first.
$$ #
$$ # Use the class directive when using docutils. Nim rst2html
$$ # doesn't support it.
$$ nextline t.output = if(h.useDocUtils, "result", "skip")
.. class:: align-center

Document produced from nim doc comments and formatted with StaticTea.
