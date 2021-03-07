
import strutils
import args
import regexes
import tables
import options

const
  predefinedPrepost: array[6, Prepost] = [
    ## Predefined prefixes and postfixes.
    ("<!--$", "-->"),
    ("#$", ""),
    (";$", ""),
    ("//$", ""),
    ("/*$", "*/"),
    ("&lt;!--$", "--&gt;"),
  ]

  commands: array[7, string] = [
    ## Statictea commands.
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
    ## The prefix postfix pairs stored in an ordered dictionary.

  CompiledMatchers* = object
    ## The precompiled regular expressions used for parsing lines.
    prepostTable*: PrepostTable
    prefixMatcher*: Matcher
    commandMatcher*: Matcher
    variableMatcher*: Matcher
    equalSignMatcher*: Matcher
    allSpaceTabMatcher*: Matcher
    numberMatcher*: Matcher
    stringMatcher*: Matcher
    leftParenthesesMatcher*: Matcher
    rightParenthesesMatcher*: Matcher
    commaParenthesesMatcher*: Matcher
    leftBracketMatcher*: Matcher
    tabSpaceMatcher*: Matcher

proc getDefaultPrepostTable*(): PrepostTable =
  ## Return the default ordered table that maps prefixes to postfixes.
  result = initOrderedTable[string, string]()
  for prepost in predefinedPrepost:
    assert prepost.pre != ""
    result[prepost.pre] = prepost.post

proc getUserPrepostTable*(prepostList: seq[Prepost]): PrepostTable =
  ## Return the user's ordered table that maps prefixes to
  ## postfixes. This is used when the user specifies prefixes on the
  ## command line. No defaults in this table.
  assert prepostList.len > 0
  result = initOrderedTable[string, string]()
  for prepost in prepostList:
    # The prefix and postfix values have been validated by the command line
    # processing procedure parsePrepost.
    assert prepost.pre != ""
    result[prepost.pre] = prepost.post

proc getPrefixMatcher*(prepostTable: PrepostTable): Matcher =
  ## Return a matcher for matching the prefixes and optional following
  ## whitespace. The group contains the prefix found.
  var terms = newSeq[string]()
  for prefix, _ in prepostTable:
    terms.add(r"\Q$1\E" % prefix)
  result = newMatcher(r"^($1)\s*" % terms.join("|"), 1)

proc getCommandMatcher*(): Matcher =
  ## Return a matcher for matching a command. The group contains the command matched.
  result = newMatcher(r"($1)" % commands.join("|"), 1)

proc getLastPartMatcher*(postfix: string): Matcher =
  ## Retun a matcher that matches the last part of the line.  It
  ## matches the optional continuation slash, the optional postfix and
  ## the line endings. The postfix used is remembered in the matcher
  ## object returned.
  # Note: nim sets the regex anchor option.
  var pattern: string
  if postfix == "":
    pattern = r"([\\]{0,1})([\r]{0,1}\n){0,1}$"
  else:
    pattern = r"([\\]{0,1})\Q$1\E([\r]{0,1}\n){0,1}$" % postfix
  result = newMatcher(pattern, 2, arg1 = postfix)

proc getLastPart*(matcher: Matcher, line: string): Option[Matches] =
  ## Return the optional slash and line endings from the line.

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

proc getAllSpaceTabMatcher*(): Matcher =
  ## Return a matcher that determines whether a string is all spaces
  ## and tabs.
  result = newMatcher(r"^[ \t]*$", 0)

proc getTabSpaceMatcher*(): Matcher =
  ## Return a matcher that matches one or more tabs and spaces.
  result = newMatcher(r"[ \t]+", 0)

proc notEmptyOrSpaces*(allSpaceTabMatcher: Matcher, text: string): bool =
  ## Return true when a statement is not empty or not all whitespace.
  if text.len != 0:
    let matches = getMatches(allSpaceTabMatcher, text)
    if not matches.isSome:
      result = true

proc getVariableMatcher*(): Matcher =
  ## Return a matcher that matches a variable and surrounding
  ## whitespace. Return the leading whitespace, the namespace and the
  ## variable name.
  ##
  ## A variable starts with an optional prefix followed by a required
  ## variable name. The prefix is a lowercase letter followed by a
  ## period. The variable name starts with a letter followed by
  ## letter, digits and underscores. The variable name length is 1 to
  ## 64 characters. Variables are ascii.
  ##
  ## The match stops on the first non matching character. You need to
  ## check the next character to see whether it makes sense in the
  ## statement, for example, "t." matches and returns "t".
  ## "{ t.repeat #" matches.
  # Note: nim sets the regex anchor option.
  result = newMatcher(r"(\s*)([a-z]\.){0,1}([a-zA-Z][a-zA-Z0-9_]{0,63})\s*", 3)

proc getEqualSignMatcher*(): Matcher =
  ## Return a matcher that matches an equal sign and the optional following white space.
  # Note: nim sets the regex anchor option.
  result = newMatcher(r"(=)\s*", 1)

proc getLeftParenthesesMatcher*(): Matcher =
  ## Return a matcher that matches a left parentheses and the optional following white space.
  # Note: nim sets the regex anchor option.
  result = newMatcher(r"\(\s*", 0)

proc getCommaParenthesesMatcher*(): Matcher =
  ## Return a matcher that matches a comma or right parentheses and the optional following
  ## white space. One group containing either the comma or right paren.
  # Note: nim sets the regex anchor option.
  result = newMatcher(r"([,)])\s*", 1)

proc getRightParenthesesMatcher*(): Matcher =
  ## Return a matcher that matches a right parentheses and the optional following white space.
  # Note: nim sets the regex anchor option.
  result = newMatcher(r"\)\s*", 0)

proc getNumberMatcher*(): Matcher =
  ## Return a matcher that matches a number and the optional trailing whitespace. Return the
  ## optional decimal point that tells whether the number is a float
  ## or integer.
  ##
  ## A number starts with an optional minus sign, followed by a digit,
  ## followed by digits, underscores or a decimal point. Only one
  ## decimal point is allowed and underscores are skipped.  Note: nim
  ## sets the regex anchor option.

  result = newMatcher(r"-{0,1}[0-9][0-9_]*([\.]{0,1})[0-9_]*\s*", 1)

proc getStringMatcher*(): Matcher =
  ## Return a matcher that matches a string.

  # A string is inside quotes, either single or double quotes. The
  # optional white space after the string is matched too. There are
  # two returned groups and only one will contain anything. The first
  # is for single quotes and the second is for double quotes. Note:
  # nim sets the regex anchor option.

  result = newMatcher("""'([^']*)'\s*|"([^"]*)"\s*""", 2)

proc getLeftBracketMatcher*(): Matcher =
  ## Match everything up to a left backet. The match length includes
  ## the bracket.

  # A replacement variable is inside brackets.  Note: nim sets the
  # regex anchor option.

  # text on the line {variable} more text {variable2} asdf
  #                   ^
  result = newMatcher("[^{]*{", 0)

proc getCompiledMatchers*(prepostTable: PrepostTable): CompiledMatchers =
  ## Compile all the matchers and return them in the
  ## CompiledMatchers object.
  result.prepostTable = prepostTable
  result.prefixMatcher = getPrefixMatcher(result.prepostTable)
  result.commandMatcher = getCommandMatcher()
  result.variableMatcher = getVariableMatcher()
  result.allSpaceTabMatcher = getAllSpaceTabMatcher()
  result.numberMatcher = getNumberMatcher()
  result.equalSignMatcher = getEqualSignMatcher()
  result.stringMatcher = getStringMatcher()
  result.leftParenthesesMatcher = getLeftParenthesesMatcher()
  result.rightParenthesesMatcher = getRightParenthesesMatcher()
  result.commaParenthesesMatcher = getCommaParenthesesMatcher()
  result.leftBracketMatcher = getLeftBracketMatcher()
  result.tabSpaceMatcher = getTabSpaceMatcher()

proc getCompiledMatchers*(): CompiledMatchers =
  ## Get the compiled matchers using the default prepost items.
  result = getCompiledMatchers(getDefaultPrepostTable())

when defined(test):
  proc checkGetLastPart*(matcher: Matcher, line: string, expectedStart: Natural,
      expected: seq[string], expectedLength: Natural): bool =
    let matchesO = getLastPart(matcher, line)
    result = checkMatches(matchesO, matcher, line, expectedStart,
      expected, expectedLength)

