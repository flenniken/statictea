# Stf Test Files

Here are all the Statictea stf tests:

$$ # Sort the index by filenames.
$$ block
$$ : g.modules = sort(s.modules, "ascending", "sensitive", "filename")
$$ endblock
$$ block t.repeat = len(g.modules)
$$ : d = get(g.modules, t.row)
$$ : path = path(d.filename)
$$ : # Use the filename without the ending ".stf.md".
$$ : name = slice(path.filename, 0, add(len(path.filename), -7))
$$ : # Use the first sentence for the short description.
$$ : a = d.description
$$ : shortLen = add(find(a, ".", add(len(a), -1)), 1)
$$ : short = slice(a, 0, shortLen)
* [{name}](../testfiles/{path.filename}) &mdash; {short}
$$ endblock

