import std/unittest
import args

suite "args.nim":

  test "prepost":
    let prepost = newPrepost("abc", "def")
    check $prepost == "\"abc,def\""

  test "empty args":
    var args: Args
    let expected = """
args.help = 0
args.version = 0
args.update = 0
args.log = 0
args.logFilename = ""
args.resultFilename = ""
args.serverList = []
args.sharedList = []
args.codeFileList = []
args.templateFilename = ""
args.prepostList = []"""
    check $args == expected

  test "args string":
    var args: Args
    args.help = true
    args.serverList = @["one.json", "two.json"]
    args.resultFilename = "result.html"
    args.prepostList = @[newPrepost("#", "@"), newPrepost("begin", "end")]
    let expected = """
args.help = 1
args.version = 0
args.update = 0
args.log = 0
args.logFilename = ""
args.resultFilename = "result.html"
args.serverList = ["one.json", "two.json"]
args.sharedList = []
args.codeFileList = []
args.templateFilename = ""
args.prepostList = ["#,@", "begin,end"]"""
    check $args == expected

  test "args string2":
    var args: Args
    args.help = true
    args.serverList = @["server.json", "more.json"]
    args.sharedList = @["shared.json"]
    args.resultFilename = "result.html"
    let expected = """
args.help = 1
args.version = 0
args.update = 0
args.log = 0
args.logFilename = ""
args.resultFilename = "result.html"
args.serverList = ["server.json", "more.json"]
args.sharedList = ["shared.json"]
args.codeFileList = []
args.templateFilename = ""
args.prepostList = []"""
    check($args == expected)

  test "args logging no name":
    var args: Args
    args.help = true
    args.log = true
    args.serverList = @["server.json", "more.json"]
    args.sharedList = @["shared.json"]
    args.resultFilename = "result.html"
    let expected = """
args.help = 1
args.version = 0
args.update = 0
args.log = 1
args.logFilename = ""
args.resultFilename = "result.html"
args.serverList = ["server.json", "more.json"]
args.sharedList = ["shared.json"]
args.codeFileList = []
args.templateFilename = ""
args.prepostList = []"""
    check($args == expected)

  test "args logging with name":
    var args: Args
    args.help = true
    args.log = true
    args.serverList = @["server.json", "more.json"]
    args.sharedList = @["shared.json"]
    args.resultFilename = "result.html"
    args.logFilename = "statictea.log"
    let expected = """
args.help = 1
args.version = 0
args.update = 0
args.log = 1
args.logFilename = "statictea.log"
args.resultFilename = "result.html"
args.serverList = ["server.json", "more.json"]
args.sharedList = ["shared.json"]
args.codeFileList = []
args.templateFilename = ""
args.prepostList = []"""
    check($args == expected)
