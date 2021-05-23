$$ # StaticTea template for generating markdown from nim doc comments.
$$ #
$$ # Define replacement patterns to remove formatting from the descriptions.
$$ block
$$ : t.maxLines = 20
$$ : g.patterns = list( +
$$ :   "@@", '', +
$$ :   "@\|", '[', +
$$ :   "\|@", ']', +
$$ :   "[ ]*@:", h.newline, +
$$ :   "&quot;", '"', +
$$ :   "&gt;", '>', +
$$ :   "&lt;", '<', +
$$ :   "&amp;", '&')
$$ : path = path(s.orig)
$$ : g.moduleName = path.filename
$$ endblock
$$ #
[Home](https://github.com/flenniken/statictea/)

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
$$ : type = case(entry.type, +
$$ :   "skType", "type: ", +
$$ :   "skConst", "const: ", +
$$ :   "skMacro", "macro: ", +
$$ :   "")
$$ : desc = entry.description
$$ : short = substr(desc, 0, add(find(desc, '.', -1), 1))
* {type}[{entry.name}](#user-content-a{t.row}) &mdash; {short}

$$ # Function and type descriptions.
$$ block
$$ : t.repeat = len(s.entries)
$$ : entry = get(s.entries, t.row)
$$ : name = entry.name
$$ : nameUnderline = dup("-", len(name))
$$ : description = replaceRe(entry.description, g.patterns)
$$ : code = replaceRe(entry.code, "[ ]*$", "")
$$ : pos = find(code, " {", len(code))
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
