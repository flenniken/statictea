
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

    check checkMatch(prefixMatcher, "<--!$ nextline -->", 0, @["<--!$"], 6)
    check checkMatch(prefixMatcher, "#$ nextline", 0, @["#$"], 3)
    check checkMatch(prefixMatcher, ";$ nextline", 0, @[";$"], 3)
    check checkMatch(prefixMatcher, "//$ nextline", 0, @["//$"], 4)
    check checkMatch(prefixMatcher, "/*$ nextline */", 0, @["/*$"], 4)
    check checkMatch(prefixMatcher, "&lt;!--$ nextline --&gt;", 0, @["&lt;!--$"], 9)
    check checkMatch(prefixMatcher, "<--!$ : -->", 0, @["<--!$"], 6)
    check checkMatch(prefixMatcher, "<--!$         nextline -->", 0, @["<--!$"], 14)
    check checkMatch(prefixMatcher, "<--!$\tnextline -->", 0, @["<--!$"], 6)

    check not prefixMatcher.getMatches("<--$ nextline -->", 0).isSome
    check not prefixMatcher.getMatches("<--!$nextline -->", 0).isSome

  test "add prefix":
    var prepostList = @[("abc", "def")]
    var prepostTable = getPrepostTable(prepostList)
    check prepostTable.len == 7
    check prepostTable["abc"] == "def"
    var prefixMatcher = getPrefixMatcher(prepostTable)
    check checkMatch(prefixMatcher, "abc nextline def", 0, @["abc"], 4)

# todo: prefix with newline in it!

  test "long prefix":
    let prefix = "this is a very long prefix nextline post"
    var prepostList = @[(prefix, "post")]
    var prepostTable = getPrepostTable(prepostList)
    var prefixMatcher = getPrefixMatcher(prepostTable)
    let line = "$1  nextline post" % prefix
    check checkMatch(prefixMatcher, line, 0, @[prefix], 42)
    check prepostTable[prefix] == "post"

  test "command matcher":
    var commandMatcher = getCommandMatcher()

    check checkMatch(commandMatcher, "<--!$ nextline -->", 6, @["nextline"], 9)
    check checkMatch(commandMatcher, "<--!$ block    -->", 6, @["block"], 9)
    check checkMatch(commandMatcher, "<--!$ replace  -->", 6, @["replace"], 9)
    check checkMatch(commandMatcher, "<--!$ endblock -->", 6, @["endblock"], 9)
    check checkMatch(commandMatcher, "<--!$ endreplace  -->", 6, @["endreplace"], 12)
    check checkMatch(commandMatcher, "<--!$ #  -->", 6, @["#"], 3)
    check checkMatch(commandMatcher, "<--!$ :  -->", 6, @[":"], 3)
    check checkMatch(commandMatcher, "  nextline ", 2, @["nextline"], 9)

    check not commandMatcher.getMatches(" nextline", 2).isSome
    check not commandMatcher.getMatches(" comment ", 2).isSome

  test "last part matcher":
    var matcher = getLastPartMatcher("-->")

    check checkMatch(matcher, "<--!$ nextline -->", 15, @["", ""], 3)
    check checkMatch(matcher, "<--!$ nextline -->\n", 15, @["", "\n"], 4)
    check checkMatch(matcher, "<--!$ nextline -->\r\n", 15, @["", "\r\n"], 5)
    check checkMatch(matcher, r"<--!$ nextline \-->", 15, @[r"\", ""], 4)
    check checkMatch(matcher, "<--!$ nextline \\-->", 15, @[r"\", ""], 4)
    check checkMatch(matcher, "<--!$ nextline \\-->\n", 15, @[r"\", "\n"], 5)
    check checkMatch(matcher, "<--!$ nextline \\-->\r\n", 15, @[r"\", "\r\n"], 6)

