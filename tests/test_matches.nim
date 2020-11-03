
import unittest
import matches
import tables
import options
import regexes
import strutils

suite "matches.nim":

  test "prepost table":
    var prepostTable = getPrepostTable()
    check prepostTable.len == 6
    for prefix, postfix in prepostTable.pairs:
      check prefix.len > 0
      # echo "$1 nextline $2" % [prefix, postfix]
    check prepostTable["<--!$"] == "-->"

  test "prefixMatcher tests":
    var prefixMatcher = getPrefixMatcher(getPrepostTable())

    check checkMatcher(prefixMatcher, "<--!$ nextline -->", 0, @["<--!$"], 6)
    check checkMatcher(prefixMatcher, "#$ nextline", 0, @["#$"], 3)
    check checkMatcher(prefixMatcher, ";$ nextline", 0, @[";$"], 3)
    check checkMatcher(prefixMatcher, "//$ nextline", 0, @["//$"], 4)
    check checkMatcher(prefixMatcher, "/*$ nextline */", 0, @["/*$"], 4)
    check checkMatcher(prefixMatcher, "&lt;!--$ nextline --&gt;", 0, @["&lt;!--$"], 9)
    check checkMatcher(prefixMatcher, "<--!$ : -->", 0, @["<--!$"], 6)
    check checkMatcher(prefixMatcher, "<--!$         nextline -->", 0, @["<--!$"], 14)
    check checkMatcher(prefixMatcher, "<--!$\tnextline -->", 0, @["<--!$"], 6)

    check not prefixMatcher.getMatches("<--$ nextline -->", 0).isSome
    check not prefixMatcher.getMatches("<--!$nextline -->", 0).isSome

  test "add prefix":
    var prepostList = @[("abc", "def")]
    var prepostTable = getPrepostTable(prepostList)
    check prepostTable.len == 7
    check prepostTable["abc"] == "def"
    var prefixMatcher = getPrefixMatcher(prepostTable)
    check checkMatcher(prefixMatcher, "abc nextline def", 0, @["abc"], 4)

# todo: prefix with newline in it!

  test "long prefix":
    let prefix = "this is a very long prefix nextline post"
    var prepostList = @[(prefix, "post")]
    var prepostTable = getPrepostTable(prepostList)
    var prefixMatcher = getPrefixMatcher(prepostTable)
    let line = "$1  nextline post" % prefix
    check checkMatcher(prefixMatcher, line, 0, @[prefix], 42)
    check prepostTable[prefix] == "post"

  test "command matcher":
    var commandMatcher = getCommandMatcher()

    check checkMatcher(commandMatcher, "<--!$ nextline -->", 6, @["nextline"], 9)
    check checkMatcher(commandMatcher, "<--!$ block    -->", 6, @["block"], 9)
    check checkMatcher(commandMatcher, "<--!$ replace  -->", 6, @["replace"], 9)
    check checkMatcher(commandMatcher, "<--!$ endblock -->", 6, @["endblock"], 9)
    check checkMatcher(commandMatcher, "<--!$ endreplace  -->", 6, @["endreplace"], 12)
    check checkMatcher(commandMatcher, "<--!$ #  -->", 6, @["#"], 3)
    check checkMatcher(commandMatcher, "<--!$ :  -->", 6, @[":"], 3)
    check checkMatcher(commandMatcher, "  nextline ", 2, @["nextline"], 9)

    check not commandMatcher.getMatches(" nextline", 2).isSome
    check not commandMatcher.getMatches(" comment ", 2).isSome

  test "last part matcher":
    var matcher = getLastPartMatcher("-->")

    check checkMatcher(matcher, "<--!$ nextline -->", 15, @["", ""], 3)
    check checkMatcher(matcher, "<--!$ nextline -->\n", 15, @["", "\n"], 4)
    check checkMatcher(matcher, "<--!$ nextline -->\r\n", 15, @["", "\r\n"], 5)
    check checkMatcher(matcher, r"<--!$ nextline \-->", 15, @[r"\", ""], 4)
    check checkMatcher(matcher, "<--!$ nextline \\-->", 15, @[r"\", ""], 4)
    check checkMatcher(matcher, "<--!$ nextline \\-->\n", 15, @[r"\", "\n"], 5)
    check checkMatcher(matcher, "<--!$ nextline \\-->\r\n", 15, @[r"\", "\r\n"], 6)

  test "getLastPart":
    var matcher = getLastPartMatcher("-->")

    let matchesO = getLastPart(matcher, "<--!$ nextline -->")
    check checkMatches(matchesO, matcher, "<--!$ nextline -->", 0, @["", ""], 3)
