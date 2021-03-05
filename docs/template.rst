.. Statictea template to generate reStructuredTest from nim doc comments.

.. Title

#$ block \
#$ : equals = '=================================================================================='; \
#$ : title = substr(s.orig, add(4, find(s.orig, 'src/'))); \
#$ : titleOverline = substr(equals, 0, len(title))
{titleOverline}
{title}
{titleOverline}
#$ endblock

.. Description

#$ nextline
{s.moduleDescription}

.. Index

Index:
------

#$ nextline \
#$ : t.repeat = len(s.entries); \
#$ : entry = get(s.entries, t.row, t.shared); \
#$ : name = get(entry, "name", ""); \
#$ : description = get(entry, "description", ""); \
#$ : short = substr(description, 0, add(find(description, '.'), 1))
* {name}_ -- {short}

#$ block \
#$ : t.repeat = len(s.entries); \
#$ : dashes = '----------------------------------------------------------------------------------'; \
#$ : entry = get(s.entries, t.row, t.shared); \
#$ : name = get(entry, "name", ""); \
#$ : nameUnderline = substr(dashes, 0, add(1, len(name))); \
#$ : description = get(entry, "description", ""); \
#$ : code = get(entry, "code", ""); \
#$ : pos = find(code, "{"); pos = case(pos, pos, -1, len(code)); \
#$ : signature = substr(code, 0, pos); \
#$ : t.maxLines = 100
.. _{name}:

{name}
{nameUnderline}

{description}

.. code::

  {signature}

#$ endblock
