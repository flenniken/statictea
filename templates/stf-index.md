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
$$ : a = d.description
$$ : shortLen = add(find(a, ".", sub(len(a), 1)), 1)
$$ : short = slice(a, 0, shortLen)
* [{name}](../testfiles/{path.filename}) &mdash; {short}
$$ endblock

