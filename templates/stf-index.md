# Stf Test Files

Here are all the Statictea stf tests:

$$ # Sort the index by filename.
$$ block
$$ : g.modules = sort(s.modules, "ascending", "sensitive", "filename")
$$ endblock
$$ block t.repeat = len(g.modules)
$$ : d = g.modules[t.row]
$$ : path = path(d.filename)
$$ : # Use the filename without the ending ".stf.md".
$$ : name = slice(path.filename, 0, sub(len(path.filename), 7))
$$ : # Use the first sentence for the short description.
$$ : ax = d.description
$$ : pos = find(ax, ".", -1)
$$ : text = if((pos == -1), ax, slice(ax, 0, add(pos, 1)))
$$ : short = replaceRe(text, ["\n", " "])
* [{name}](../testfiles/{path.filename}) &mdash; {short}
$$ endblock

