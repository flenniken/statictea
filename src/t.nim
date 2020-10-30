import re
var matches: array[2, string]
let len = matchLen("abcdefg", re"^c(d)ef(g)", matches, 2)
doAssert len == 5
doAssert $matches == """["d", "g"]"""
