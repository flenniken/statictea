
import unittest
import prepost
import args
import tables
import options
import regexes
import strutils

proc checkGetPrefix(line: string, expected: string, expectedLength: Natural) =
  let matchesO = getPrefix(line)
  check matchesO.isSome
  let matches = matchesO.get()
  check matches.getGroup() == expected
  check matches.length == expectedLength

suite "prepost.nim":

  test "initPrepost no extra":
    var list: seq[Prepost]
    initPrepost(list)
    let table = getPrepostTable()
    check table.len == 6
    # for k, v in table.pairs:
    #   echo "$1 nextline $2" % [k, v]

  test "getPrefix":
    checkGetPrefix( "<--!$ nextline -->", "<--!$", 6)
    checkGetPrefix( "#$ nextline", "#$", 3)
    checkGetPrefix(";$ nextline", ";$", 3)
    checkGetPrefix("//$ nextline", "//$", 4)
    checkGetPrefix("/*$ nextline */", "/*$", 4)
    checkGetPrefix("&lt;!--$ nextline --&gt;", "&lt;!--$", 9)
    checkGetPrefix("<--!$ : -->", "<--!$", 6)
    checkGetPrefix( "<--!$         nextline -->", "<--!$", 14)
    checkGetPrefix("<--!$\tnextline -->", "<--!$", 6)

  test "getPrefix no match":
    check not getPre("<--$ nextline -->").isSome
    check not getPre("<--!$nextline -->").isSome

  test "getPostfix":
    var postFixO = getPostfix("<--!$")
    var postFix = postFixO.get()
    check postFix == "-->"

  test "initPrepost":
    var table = getPrepostTable()
    check table.len == 6
    check table["<--!$"] == "-->"
    var prepostList = @[("abc", "def")]
    initPrepost(prepostList)
    table = getPrepostTable()
    check table.len == 7
    check table["abc"] == "def"
    checkGetPrefix("abc nextline def", "abc", 4)

  test "initPrepost long":
    let prefix = "this is a very long prefix nextline post"
    var prepostList = @[(prefix, "post")]
    initPrepost(prepostList)
    let line = "$1  nextline post" % prefix
    checkGetPrefix(line, prefix, 42)
    let postFixO = getPostfix(prefix)
    check postFixO.isSome
    check postFixO.get() == "post"
