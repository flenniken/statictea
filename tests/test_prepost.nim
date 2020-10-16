
import unittest
import prepost
import args
import tables
import options

suite "prepost.nim":

  test "initPrepost no extra":
    var list: seq[Prepost]
    initPrepost(list)
    let table = getPrepostTable()
    let pattern = getPrefixPattern()
    check table.len == 6
    # for k, v in table.pairs:
    #   echo "$1 nextline $2" % [k, v]
    check getPrefixPattern() != nil

# todo: test when extra prepost values get passed in.
# todo: test when no prefix match.
# todo: test long very long prefix, postfix.
# todo: test common word prefix like the.
# todo: test one letter prefix.
# todo: test getPostfix

  test "getPrefix":
    check getPrefix("<--!$ nextline -->").get() == "<--!$"
    check getPrefix("#$ nextline").get() == "#$"
    check getPrefix(";$ nextline").get() == ";$"
    check getPrefix("//$ nextline").get() == "//$"
    check getPrefix("/*$ nextline */").get() == "/*$"
    check getPrefix("&lt;!--$ nextline --&gt;").get() == "&lt;!--$"