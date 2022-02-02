# Test Files

This folder contains stf test files for statictea.

$$ # Sort the index by filenames.
$$ block
$$ : g.modules = sort(s.modules, "ascending", "sensitive", "filename")
$$ endblock
$$ block t.repeat = len(g.modules)
$$ : d = get(g.modules, t.row)
$$ : path = path(d.filename)
$$ : name = substr(path.filename, 0, add(len(path.filename), -7))
$$ : desc = d.description
$$ : sentence = substr(desc, 0, add(find(desc, ".", -1), 1))
* [{name}](../testfiles/{path.filename}) &mdash; {sentence}
$$ endblock

