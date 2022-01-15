# Test Files

This folder contains stf test files for statictea.

$$ # Sort the index by filenames.
$$ block
$$ : g.modules = sort(s.modules, "ascending", "sensitive", "filename")
$$ endblock
$$ nextline t.repeat = len(g.modules)
$$ : d = get(g.modules, t.row)
$$ : path = path(d.filename)
$$ : description = d.description
* [{path.basename}](../testfiles/{path.filename}) &mdash; {description}
