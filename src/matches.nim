
import strutils
import args
import regexes
import tables
import options

const
  predefinedPrepost: array[6, Prepost] = [
    ("<--!$", "-->"),
    ("#$", ""),
    (";$", ""),
    ("//$", ""),
    ("/*$", "*/"),
    ("&lt;!--$", "--&gt;"),
  ]

  commands: array[7, string] = [
    "nextline",
    "block",
    "replace",
    "#",
    ":",
    "endblock",
    "endreplace",
  ]

type
  PrepostTable* = OrderedTable[string, string]

iterator combine(list1: openArray[Prepost], list2: openArray[Prepost]): Prepost =
  ## Iterate through list1 then list2.
  for prepost in list1:
    yield(prepost)
  for prepost in list2:
    yield(prepost)

proc getPrepostTable*(prepostList: seq[Prepost] = @[]): PrepostTable =
  ## Return an ordered table that maps prefixes to postfixes.  The
  ## returned table contains the given prepost items together with
  ## the predefined items.
  result = initOrderedTable[string, string]()
  for prepost in combine(prepostList, predefinedPrepost):
    assert prepost.pre != ""
    result[prepost.pre] = prepost.post

proc getPrefixMatcher*(prepostTable: PrepostTable): Matcher =
  ## Return a matcher for matching the prefixes.
  var terms = newSeq[string]()
  for prefix, _ in prepostTable:
    terms.add(r"\Q$1\E" % prefix)
  result = newMatcher(r"^($1)\s+" % terms.join("|"), 1)

proc getCommandMatcher*(): Matcher =
  result = newMatcher(r"($1)\s+" % commands.join("|"), 1)

proc getLastPartMatcher*(postfix: string): Matcher =
  ## Get the matcher to use with
  var pattern: string
  if postfix == "":
    pattern = r"([\\]{0,1})([\r]{0,1}\n){0,1}$"
  else:
    pattern = r"([\\]{0,1})\Q$1\E([\r]{0,1}\n){0,1}$" % postfix

  result = newMatcher(pattern, 2, postfix)

proc getLastPart*(matcher: Matcher, line: string): Option[Matches] =
  ## Return the optional slash and line endings.

  # Start checking 3 characters before the end to account for the
  # optional slash, cr and linefeed. If the line is too short, return
  # no match.
  var startPos = line.len - matcher.arg1.len - 3
  if startPos < 0:
    return

  for start in startPos..startPos+3:
    let matchesO = getMatches(matcher, line, start)
    if matchesO.isSome:
      return matchesO

# 123456
# 0123456
# \-->rn
#  \-->n
#   -->n
#    -->
