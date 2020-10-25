
var list = @["1", "2", "3"]

proc get1Group(list: seq[string]): string =
  result = list[0]
proc get2Groups(list: seq[string]): (string, string) =
  result = (list[0], list[1])
proc get3Groups(list: seq[string]): (string, string, string) =
  result = (list[0], list[1], list[2])
proc get4Groups(list: seq[string]): (string, string, string, string) =
  result = (list[0], list[1], list[2], list[3])

let (a, b, c) = getGroups(list)

assert a == 1
assert b == 2
assert c == 3
