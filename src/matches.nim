## Regular expression matching methods.

import std/strutils
import std/tables
import std/options
import args
import regexes

const
  predefinedPrepost: array[8, Prepost] = [
    ## The predefined prefixes and postfixes.
    newPrepost("<!--$", "-->"),
    newPrepost("#$", ""),
    newPrepost(";$", ""),
    newPrepost("//$", ""),
    newPrepost("/*$", "*/"),
    newPrepost("&lt;!--$", "--&gt;"),
    newPrepost("$$", ""),
    newPrepost("# $", ""),
  ]

  ## The StaticTea commands.
  commands: array[6, string] = [
    "nextline",
    "block",
    "replace",
    "#",
    ":",
    "endblock",
  ]

  numberPattern = r"-{0,1}[0-9][0-9_]*([\.]{0,1})[0-9_]*\s*"
    ## A number regular expression pattern. A number starts with an
    ## optional minus sign, followed by a digit, followed by digits,
    ## underscores or a decimal point. Only one decimal point is
    ## allowed and underscores are skipped.

  versionPattern = r"^([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})$"
    ## StaticTea version regular expression pattern.  It has
    ## three components each with one to three digits: i.e. 1.2.3,
    ## 123.456.789, 0.1.0,... .

type
  PrepostTable* = OrderedTable[string, string]
    ## The prefix postfix pairs stored in an ordered dictionary.

proc makeDefaultPrepostTable*(): PrepostTable =
  ## Return the default ordered table that maps prefixes to postfixes.
  result = initOrderedTable[string, string]()
  for prepost in predefinedPrepost:
    assert prepost.prefix != ""
    result[prepost.prefix] = prepost.postfix

proc makeUserPrepostTable*(prepostList: seq[Prepost]): PrepostTable =
  ## Return the user's ordered table that maps prefixes to
  ## postfixes. This is used when the user specifies prefixes on the
  ## command line and it does not contain any defaults.
  assert prepostList.len > 0
  result = initOrderedTable[string, string]()
  for prepost in prepostList:
    # The prefix and postfix values have been validated by the command line
    # processing procedure parsePrepost.
    assert prepost.prefix != ""
    result[prepost.prefix] = prepost.postfix

proc matchPrefix*(line: string, prepostTable: PrepostTable, start: Natural = 0): Option[Matches] =
  ## Match lines that start with one of the prefixes in the given
  ## table plus optional following whitespace.
  var terms = newSeq[string]()
  for prefix, _ in prepostTable:
    terms.add(r"\Q$1\E" % prefix)
  let pattern = r"^($1)\s*" % terms.join("|")
  result = matchPatternCached(line, pattern, start, 1)

proc matchCommand*(line: string, start: Natural = 0): Option[Matches] =
  ## Match statictea commands.
  let pattern = r"($1)" % commands.join("|")
  result = matchPatternCached(line, pattern, start, 1)

proc matchLastPart*(line: string, postfix: string,
    start: Natural = 0): Option[Matches] =
  ## Match the last part of a command line.  It matches the optional
  ## continuation plus character, the optional postfix and the
  ## optional line endings.
  var pattern: string
  if postfix == "":
    pattern = r"([+]{0,1})([\r]{0,1}\n){0,1}$"
  else:
    pattern = r"([+]{0,1})\Q$1\E([\r]{0,1}\n){0,1}$" % postfix
  result = matchPatternCached(line, pattern, start, 2)

proc getLastPart*(line: string, postfix: string): Option[Matches] =
  ## Return the optional plus and line endings from the line.

  # Start checking 3 characters before the end to account for the
  # optional slash, cr and linefeed. If the line is too short, return
  # no match.  Note the nim regex uses the anchored option. Using ^ to
  # anchor in the pattern does not do what I expect when the start
  # position is not 1.
  #
  # 123456
  # 0123456
  # +-->rn
  #  +-->n
  #   -->n
  #    -->

  var startPos = line.len - postfix.len - 3
  if startPos < 0:
    return

  for start in startPos..startPos+3:
    let matchesO = matchLastPart(line, postfix, start)
    if matchesO.isSome:
      return matchesO

proc matchAllSpaceTab*(line: string, start: Natural = 0): Option[Matches] =
  ## Match a line of all spaces or tabs.
  let pattern = r"^[ \t]*$"
  result = matchPatternCached(line, pattern, start, 0)

proc matchTabSpace*(line: string, start: Natural = 0): Option[Matches] =
  ## Match one or more spaces or tabs.
  let pattern = r"[ \t]+"
  result = matchPatternCached(line, pattern, start, 0)

proc notEmptyOrSpaces*(text: string): bool =
  ## Return true when a statement is not empty or not all whitespace.
  if text.len != 0:
    let matchesO = matchAllSpaceTab(text, 0)
    if not matchesO.isSome:
      result = true

proc matchEqualSign*(line: string, start: Natural = 0): Option[Matches] =
  ## Match an equal sign or "&=" and the optional trailing
  ## whitespace. Return the operator in the group, "=" or "&=".
  let pattern = r"(&{0,1}=)\s*"
  result = matchPatternCached(line, pattern, start, 1)

proc matchLeftParentheses*(line: string, start: Natural = 0): Option[Matches] =
  ## Match a left parenthese and the optional trailing whitespace.
  let pattern = r"\(\s*"
  result = matchPatternCached(line, pattern, start, 0)

proc matchCommaParentheses*(line: string, start: Natural = 0): Option[Matches] =
  ## Match a comma or right parentheses and the optional trailing whitespace.
  let pattern = r"([,)])\s*"
  result = matchPatternCached(line, pattern, start, 1)

proc matchRightParentheses*(line: string, start: Natural = 0): Option[Matches] =
  ## Match a right parentheses and the optional trailing whitespace.
  let pattern = r"\)\s*"
  result = matchPatternCached(line, pattern, start, 0)

proc matchNumber*(line: string, start: Natural = 0): Option[Matches] =
  ## Match a number and the optional trailing whitespace. Return the
  ## optional decimal point that tells whether the number is a float
  ## or integer.
  result = matchPatternCached(line, numberPattern, start, 1)

func matchNumberNotCached*(line: string, start: Natural = 0): Option[Matches] =
  ## Match a number and the optional trailing whitespace. Return the
  ## optional decimal point that tells whether the number is a float
  ## or integer.
  result = matchPattern(line, numberPattern, start, 1)

proc matchLeftBracket*(line: string, start: Natural = 0): Option[Matches] =
  ## Match everything up to a left backet. The match length includes
  ## @:the bracket.
  ## @:
  ## @:A replacement variable is inside brackets.
  ## @:
  ## @:~~~
  ## @:text on the line {variable} more text {variable2} asdf
  ## @:                  ^
  ## @:~~~~

  let pattern = "[^{]*{"
  result = matchPatternCached(line, pattern, start, 0)

proc matchFileLine*(line: string, start: Natural = 0): Option[Matches] =
  ## Match a file and line number like: filename(234).
  let pattern = r"^(.*)\(([0-9]+)\)$"
  result = matchPatternCached(line, pattern, start, 2)

proc matchVersion*(line: string, start: Natural = 0): Option[Matches] =
  ## Match a StaticTea version number.
  result = matchPatternCached(line, versionPattern, start, 3)

func matchVersionNotCached*(line: string, start: Natural = 0,
    numGroups: Natural = 0): Option[Matches] =
  ## Match a StaticTea version number.
  result = matchPattern(line, versionPattern, start, 3)

proc matchDotNames*(line: string, start: Natural = 0): Option[Matches] =
  ## Matches variable dot names and surrounding whitespace. Return the
  ## @:leading whitespace and dot names as one string like "a.b.c.d".
  ## @:This is used to match functions too. They look like a variable
  ## @:followed by an open parentheses.
  ## @:
  ## @:A dot name is a list of variable names separated by dots.
  ## @:You can have 1 to 5 variable names in a dot name.
  ## @:
  ## @:A variable name starts with a letter followed by letters, digits
  ## @:and underscores limited to a total of 64 characters.
  ## @:
  ## @:No space is allowed between the function name and the left
  ## @:parentheses.
  ## @:
  ## @:Return three groups, the leading whitespace and the dotNames
  ## @:and the optional left parentheses. The length returned includes
  ## @:the optional trailing whitespace.

  let name = r"[a-zA-Z][a-zA-Z0-9_]{0,63}"
  let pattern = r"(\s*)((?:$1)(?:\.$1){0,4})(\(){0,1}\s*" % [name]
  result = matchPatternCached(line, pattern, start, 3)

type
  GroupSymbol* = enum
    gLeftParentheses # (
    gRightParentheses # )
    gLeftBracket # [
    gRightBracket # ]

proc matchCommaOrSymbol*(line: string, symbol: GroupSymbol,
    start: Natural = 0): Option[Matches] =
  ## Match a comma or the symbol and the optional trailing whitespace.
  var pattern: string
  case symbol:
  of gLeftParentheses:
    pattern = r"([,(])\s*"
  of gRightParentheses:
    pattern = r"([,\)])\s*"
  of gLeftBracket:
    pattern = r"([,[])\s*"
  of gRightBracket:
    pattern = r"([,\]])\s*"
  result = matchPatternCached(line, pattern, start, 1)

proc matchSymbol*(line: string, symbol: GroupSymbol, start: Natural = 0): Option[Matches] =
  ## Match the symbol and the optional trailing whitespace.
  var pattern: string
  case symbol:
  of gLeftParentheses:
    pattern = r"\(\s*"
  of gRightParentheses:
    pattern = r"\)\s*"
  of gLeftBracket:
    pattern = r"\[\s*"
  of gRightBracket:
    pattern = r"\]\s*"
  result = matchPatternCached(line, pattern, start, 0)
