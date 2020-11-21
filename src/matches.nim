
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

  CompiledMatchers* = object
    prepostTable*: PrepostTable
    prefixMatcher*: Matcher
    commandMatcher*: Matcher
    variableMatcher*: Matcher
    spaceTabMatcher*: Matcher
    numberMatcher*: Matcher

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
  result = newMatcher(r"($1)\s" % commands.join("|"), 1)

proc getLastPartMatcher*(postfix: string): Matcher =
  ## Get the matcher that matches the optional continuation slash, the
  ## optional postfix and the line endings. The postfix used is
  ## remembered in the matcher object.
  var pattern: string
  if postfix == "":
    pattern = r"([\\]{0,1})([\r]{0,1}\n){0,1}$"
  else:
    pattern = r"([\\]{0,1})\Q$1\E([\r]{0,1}\n){0,1}$" % postfix
  result = newMatcher(pattern, 2, arg1 = postfix)

proc getLastPart*(matcher: Matcher, line: string): Option[Matches] =
  ## Return the optional slash and line endings.

  # Start checking 3 characters before the end to account for the
  # optional slash, cr and linefeed. If the line is too short, return
  # no match.  Note the nim regex uses the anchored option. Using ^ to
  # anchor in the pattern does not do what I expect when the start
  # position is not 1.

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

proc getSpaceTabMatcher*(): Matcher =
  ## Return a matcher that determines whether a string is all spaces
  ## and tabs.
  result = newMatcher(r"^[ \t]*$", 0)

proc notEmptyOrSpaces*(spaceTabMatcher: Matcher, statement: string): bool =
  ## Return true when a statement is not empty or not all whitespace.
  if statement.len != 0:
    let matches = getMatches(spaceTabMatcher, statement)
    if not matches.isSome:
      result = true

proc getVariableMatcher*(): Matcher =
  ## Match a variable, equal sign and surrounding whitespace.
  ## Return the optional namespace and the required name.
  result = newMatcher(r"^\s*([a-z]\.){0,1}([a-zA-Z][a-zA-Z0-9_]*)\s*=\s*", 2)

proc getNumberMatcher*(): Matcher =
  ## Match a number. Return the optional decimal point that tells
  ## whether the number is a float or integer.

  # A number starts with an optional minus sign, followed by a
  # digit, followed by digits, underscores or a decimal point. Only
  # one decimal point is allowed and underscores are skipped.
  # note: nim sets the regex anchor option.
  result = newMatcher(r"[-]{0,1}[0-9][0-9_]*([\.]{0,1})[0-9_]*", 1)

proc getCompiledMatchers*(prepostList: seq[Prepost] = @[]): CompiledMatchers =
  ## Compile all the matchers and return them in the
  ## CompiledMatchers object.
  result.prepostTable = getPrepostTable(prepostList)
  result.prefixMatcher = getPrefixMatcher(result.prepostTable)
  result.commandMatcher = getCommandMatcher()
  result.variableMatcher = getVariableMatcher()
  result.spaceTabMatcher = getSpaceTabMatcher()
  result.numberMatcher = getNumberMatcher()
