# Test Files

This folder contains stf test files for statictea.

$$ # Sort the index by filenames.
$$ block
$$ : g.modules = sort(s.modules, "ascending", "sensitive", "filename")
$$ endblock
$$ block t.repeat = len(g.modules)
$$ : d = get(g.modules, t.row)
$$ : path = path(d.filename)
$$ : name = slice(path.filename, 0, add(len(path.filename), -7))
* [{name}](../testfiles/{path.filename}) &mdash; {d.description}
$$ endblock

