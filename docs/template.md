$$ # StaticTea template for generating markdown from nim doc comments.
$$ #
$$ # Define replacement patterns to remove formatting from the descriptions.
$$ block
$$ : t.maxLines = 20
$$ : g.patterns = list( \
$$ :   "@@", '', \
$$ :   "@\|", '[', \
$$ :   "\|@", ']', \
$$ :   "[ ]*@:", h.newline, \
$$ :   "&quot;", '"', \
$$ :   "&gt;", '>', \
$$ :   "&lt;", '<', \
$$ :   "&amp;", '&', \
$$ :   "httpss", 'https')
$$ : g.moduleName = substr(s.orig, add(4, find(s.orig, 'src/', -4)));
$$ endblock
$$ #
$$ # Add the title created from the basename
$$ # of the module path in s.orig.
$$ nextline
# {g.moduleName}

$$ # Module description.
$$ nextline
$$ : description = replaceRe(s.moduleDescription, g.patterns)
{description}

$$ # Show the index label when there are entries.
$$ nextline t.output = case(len(s.entries), 0, 'skip', 'result')
# Index

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
* {type}[{name}](#user-content-a{t.row}) &mdash; {short}

$$ # Function and type descriptions.
$$ block
$$ : t.repeat = len(s.entries)
$$ : entry = get(s.entries, t.row)
$$ : name = get(entry, "name", "")
$$ : nameUnderline = dup("-", len(name))
$$ : desc = get(entry, "description", "")
$$ : description = replaceRe(desc, g.patterns)
$$ : co = get(entry, "code", "")
$$ : code = replaceRe(co, "[ ]*$", "")
$$ : pos = find(code, "{", len(code))
$$ : signature = substr(code, 0, pos)
$$ : line = get(entry, "line", "0")
$$ : t.maxLines = 100
# <a id="a{t.row}"></a>{name}

{description}

```nim
{signature}
```

[source](../src/{g.moduleName}#L{line})

$$ endblock

---
⦿ StaticTea markdown template for nim doc comments. ⦿
