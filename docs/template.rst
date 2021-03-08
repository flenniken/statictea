#$ # Statictea template to generate reStructuredTest from nim doc comments.
#$ #
#$ # todo: Make the type names in code sections into links that
#$ # todo: point at their description.
#$ # todo: Replace the types found in the code section with their name
#$ # todo: followed by an underscore to make then into links. The link
#$ # todo: destinations already exist.
#$ # todo: Need way to make a dictionary. Put it in t.global.
#$ # todo: Need way to replace the names. Names without getting part
#$ # todo: of a word.  Names with a space after them or names at the end of
#$ # todo: a line.
#$ # todo: matches.html. Need a way to handle two procedures
#$ # todo:named the same. getCompiledMatchers
#$ # todo: "type": "skConst".  Prefix constants with "const:"
#$ # todo: Make a link to the source file and line.
#$ #
#$ #
#$ # Title
#$ block \
#$ : title = substr(s.orig, add(4, find(s.orig, 'src/', -4))); \
#$ : titleOverline = dup("=", len(title))
{titleOverline}
{title}
{titleOverline}
#$ endblock

#$ # Module description.
#$ nextline
{s.moduleDescription}

#$ # Show the index when there are entries.
#$ block t.output = case(len(s.entries), 0, 'skip', 'result')
Index:
------
#$ endblock
#$ #
#$ #
#$ #
#$ # Index to types and functions.
#$ block \
#$ : t.repeat = len(s.entries); \
#$ : entry = get(s.entries, t.row, t.shared); \
#$ : name = get(entry, "name", ""); \
#$ : description = get(entry, "description", ""); \
#$ : skType = get(entry, "type", ""); \
#$ : type = case(skType, "skType", \
#$ :   "type: ", "skConst", "const: ", \
#$ :   "skMacro", "macro: ", \
#$ :   ""); \
#$ : short = substr(description, 0, add(find(description, '.', -1), 1))

* {type}{name}_ -- {short}
#$ endblock

#$ # Function and type descriptions.
#$ block \
#$ : t.repeat = len(s.entries); \
#$ : entry = get(s.entries, t.row, t.shared); \
#$ : name = get(entry, "name", ""); \
#$ : nameUnderline = dup("-", len(name)); \
#$ : description = get(entry, "description", ""); \
#$ : code = get(entry, "code", ""); \
#$ : pos = find(code, "{", len(code)); \
#$ : signature = substr(code, 0, pos); \
#$ : t.maxLines = 100
.. _{name}:

{name}
{nameUnderline}

.. code::

 {signature}

{description}

#$ endblock
#$ # The code block above has code in the json with two space
#$ # indenting on multiple lines.  Indenting the first line two spaces
#$ # makes all the lines line up. If you indent it one space, you can
#$ # see the indentation. You need to indent at least one space.
#$ # Fix by adding spaces to the beginning of lines, except the first.
#$ #
#$ # Use the class directive when using docutils. Nim rst2html
#$ # doesn't support it.
#$ nextline t.output = if(h.useDocUtils, "result", "skip")
.. class:: align-center

Document produced from nim doc comments and formatted with Statictea.
