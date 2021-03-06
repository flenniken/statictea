#$ # Statictea template to generate reStructuredTest from nim doc comments.

#$ # Title
#$ block \
#$ : equals = '=================================================================================='; \
#$ : title = substr(s.orig, add(4, find(s.orig, 'src/', -4))); \
#$ : titleOverline = substr(equals, 0, len(title))
{titleOverline}
{title}
{titleOverline}
#$ endblock

#$ # Module description.
#$ nextline
{s.moduleDescription}

Index:
------

#$ # Index to types and functions.
#$ nextline \
#$ : t.repeat = len(s.entries); \
#$ : entry = get(s.entries, t.row, t.shared); \
#$ : name = get(entry, "name", ""); \
#$ : description = get(entry, "description", ""); \
#$ : skType = get(entry, "type", ""); \
#$ : type = case(skType, "", "skType", "type: "); \
#$ : short = substr(description, 0, add(find(description, '.', -1), 1))
* {type}{name}_ -- {short}

#$ # Function and type descriptions.
#$ block \
#$ : t.repeat = len(s.entries); \
#$ : dashes = '----------------------------------------------------------------------------------'; \
#$ : entry = get(s.entries, t.row, t.shared); \
#$ : name = get(entry, "name", ""); \
#$ : nameUnderline = substr(dashes, 0, add(1, len(name))); \
#$ : description = get(entry, "description", ""); \
#$ : code = get(entry, "code", ""); \
#$ : pos = find(code, "{", len(code)); \
#$ : signature = substr(code, 0, pos); \
#$ : t.maxLines = 100
.. _{name}:

{name}
{nameUnderline}

{description}

.. code::

 {signature}

#$ endblock
#$ # The code block above has code in the json with two space
#$ # indenting on multiple lines.  Indenting the first line two spaces
#$ # makes all the lines line up. If you indent it one space, you can
#$ # see the indentation. You need to indent at least one space.

#$ # Use the class directive when using docutils. Nim rst2html
#$ # doesn't support it.
#$ nextline t.output = if(h.useDocUtils, "result", "skip")
.. class:: align-center

Document produced from nim doc comments and formatted with Statictea.
