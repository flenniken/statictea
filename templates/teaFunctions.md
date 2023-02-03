$$ # Create the functions documentation from the f dictionary.
# Statictea Functions

[![teapot](teapotlogo.svg)](#)

The built-in Statictea functions.

Functions allow you to format variables for presentation in a
replacement block.  They return a value that you assign to a
variable or pass to another function.

# Index

$$ block
$$ : t.repeat = len(o.entries)
$$ : entry = o.entries[t.row]
* [{entry.name}](#{entry.anchorName}) &mdash; {entry.sentence}
$$ endblock

$$ block
$$ : t.repeat = len(o.entries)
$$ : entry = o.entries[t.row]
# {entry.name}

{entry.docComment}

$$ endblock

---

⦿ Markdown page generated by StaticTea from the function dictionary.