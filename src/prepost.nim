
import strutils
import args
import regex
import tables

const
  predefined: array[6, Prepost] = [
    ("<--!$", "-->"),
    ("#$", ""),
    (";$", ""),
    ("//$", ""),
    ("/*$", "*/"),
    ("&lt;!--$", "--&gt;"),
  ]

var prepostTable = initOrderedTable[string, string]()
var prefixPattern: Pattern

when defined(test):
  proc getPrepostTable*(): OrderedTable[string, string] =
    result = prepostTable

  proc getPrefixPattern*(): Pattern =
    result = prefixPattern

iterator combine(list1: openArray[Prepost], list2: openArray[Prepost]): Prepost =
  ## Iterate through list1 then list2.
  for prepost in list1:
    yield(prepost)
  for prepost in list2:
    yield(prepost)

proc initPrepost*(prepostList: seq[Prepost]) =
  ## Initialize the prefix, postfix matching system.
  var terms = newSeq[string]()
  for prepost in combine(prepostList, predefined):
    assert prepost.pre != ""
    terms.add(r"^\Q$1\E" % prepost.pre)
    prepostTable[prepost.pre] = prepost.post
  prefixPattern = getPattern("($1)" % terms.join("|"))

proc isPrefixLine*(line: string): string =
  ## Determine whether the line starts with a prefix. Return the
  ## prefix matched. Return "" when not a prefix line.
  assert prefixPattern != nil, "Call initPrepost first."
  var groups: array[1, string]
  if matches(line, prefixPattern, groups):
    result = groups[0]

proc getPostfix*(prefix: string): string =
  ## Return the postfix associated with the given prefix.
  assert prepostTable.len != 0, "Call initPrepost first."
  assert prefix in prepostTable, "The string is not a prefix."
  result = prepostTable.getOrDefault(prefix, "")
