import unittest
import args

suite "test_args.nim":

  test "empty args":
    var args: Args
    let expected = """
Args:
help=false, version=false, update=false, log=false
serverList: []
sharedList: []
templateList: []
prepostList: []
resultFilename: ""
"""
    check $args == expected

  test "args string":
    var args: Args
    args.help = true
    args.serverList = @["one.json", "two.json"]
    args.resultFilename = "result.html"
    args.prepostList = @[("#", "@"), ("begin", "end")]
    let expected = """
Args:
help=true, version=false, update=false, log=false
serverList: [one.json, two.json]
sharedList: []
templateList: []
prepostList: [(pre: "#", post: "@"), (pre: "begin", post: "end")]
resultFilename: "result.html"
"""
    check $args == expected

  test "args string2":
    var args: Args
    args.help = true
    args.serverList = @["server.json", "more.json"]
    args.sharedList = @["shared.json"]
    args.resultFilename = "result.html"
    let expected = """
Args:
help=true, version=false, update=false, log=false
serverList: [server.json, more.json]
sharedList: [shared.json]
templateList: []
prepostList: []
resultFilename: "result.html"
"""
    check($args == expected)
