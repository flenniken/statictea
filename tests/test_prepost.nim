
import unittest
import prepost
import args
import tables
import options
import regexes
import strutils

proc checkPrefixNo(line: string) =
  var matchO = getPrefix(line)
  check not matchO.isSome

proc checkPrefix(line: string, expectedPrefix: string, expectedLength: Natural) =
  var matchO = getPrefix(line)
  check matchO.isSome
  var match = matchO.get()

  if match.getGroup() != expectedPrefix:
    echo "line: $1" % [line]
    echo "expectedPrefix: $1" % [expectedPrefix]
    echo "           got: $1" % [match.getGroup()]

  if match.length != expectedLength:
    echo "line: $1" % [line]
    echo "expectedLength: $1" % [$expectedLength]
    echo "           got: $1" % [$match.length]

suite "prepost.nim":

  test "initPrepost no extra":
    var list: seq[Prepost]
    initPrepost(list)
    let table = getPrepostTable()
    let pattern = getPrefixPattern()
    check table.len == 6
    # for k, v in table.pairs:
    #   echo "$1 nextline $2" % [k, v]
    check getPrefixPattern().regex != nil

  test "getPrefix":
    checkPrefix("<--!$ nextline -->", "<--!$", 6)
    checkPrefix("#$ nextline", "#$", 3)
    checkPrefix(";$ nextline", ";$", 3)
    checkPrefix("//$ nextline", "//$", 4)
    checkPrefix("/*$ nextline */", "/*$", 4)
    checkPrefix("&lt;!--$ nextline --&gt;", "&lt;!--$", 9)
    checkPrefix("<--!$ : -->", "<--!$", 6)
    checkPrefix("<--!$         nextline -->", "<--!$", 14)
    checkPrefix("<--!$\tnextline -->", "<--!$", 6)

  test "getPrefix no match":
    checkPrefixNo("<--$ nextline -->")
    checkPrefixNo("<--!$nextline -->")

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
    checkPrefix("abc nextline def", "abc", 4)

  test "initPrepost long":
    let prefix = "this is a very long prefix nextline post"
    var prepostList = @[(prefix, "post")]
    initPrepost(prepostList)
    let line = "$1  nextline post" % prefix
    checkPrefix(line, prefix, 42)
    let postFixO = getPostfix(prefix)
    check postFixO.isSome
    check postFixO.get() == "post"
