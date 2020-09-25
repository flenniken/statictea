import unittest
import args
import strutils

suite "test_args.nim":

  test "fields":
    var args: Args
    for name, value in args.fieldPairs:
      echo "$1 = $2" % [name, $value]

  test "show":
    var args: Args
    args.help = true
    args.serverList = @["one.json", "two.json"]
    args.resultFilename = "result.html"
    args.prepostList = @[("#", "@"), ("begin", "end")]
    echo $args

  test "args to string":
    var args: Args
    let expected = """
Args:
false: help, version, update, log
empty: serverList, sharedList, templateList, resultFilename, prepostList
"""
    check($args == expected)

  test "args to string2":
    var args: Args
    args.help = true
    args.serverList = @["server.json", "more.json"]
    args.sharedList = @["shared.json"]
    args.resultFilename = "result.html"
    let expected = """
Args:
true: help
false: version, update, log
empty: templateList, prepostList
serverList=server.json, more.json
sharedList=shared.json
resultFilename=result.html
"""
    check($args == expected)
