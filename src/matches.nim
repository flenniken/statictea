## Regular expression matching methods.

import strutils
import args
import regexes
import tables
import options

const
  predefinedPrepost: array[7, Prepost] = [
    ## The predefined prefixes and postfixes.
    newPrepost("<!--$", "-->"),
    newPrepost("#$", ""),
    newPrepost(";$", ""),
    newPrepost("//$", ""),
    newPrepost("/*$", "*/"),
    newPrepost("&lt;!--$", "--&gt;"),
    newPrepost("$$", ""),
  ]

  commands: array[7, string] = [
    ## The StaticTea commands.
    "nextline",
    "block",
    "replace",
    "#",
    ":",
    "endblock",
    "endreplace",
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
  ## table.
  var terms = newSeq[string]()
  for prefix, _ in prepostTable:
    terms.add(r"\Q$1\E" % prefix)
  let pattern = r"^($1)\s*" % terms.join("|")
  result = matchPatternCached(line, pattern, start)

proc matchCommand*(line: string, start: Natural = 0): Option[Matches] =
  ## Match statictea commands.
  let pattern = r"($1)" % commands.join("|")
  result = matchPatternCached(line, pattern, start)

proc matchLastPart*(line: string, postfix: string, start: Natural = 0): Option[Matches] =
  ## Match the last part of a command line.  It matches the optional
  ## continuation plus character, the optional postfix and the
  ## optional line endings.
  var pattern: string
  if postfix == "":
    pattern = r"([+]{0,1})([\r]{0,1}\n){0,1}$"
  else:
    pattern = r"([+]{0,1})\Q$1\E([\r]{0,1}\n){0,1}$" % postfix
  result = matchPatternCached(line, pattern, start)

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
  result = matchPatternCached(line, pattern, start)

proc matchTabSpace*(line: string, start: Natural = 0): Option[Matches] =
  ## Match one or more spaces or tabs.
  let pattern = r"[ \t]+"
  result = matchPatternCached(line, pattern, start)

proc notEmptyOrSpaces*(text: string): bool =
  ## Return true when a statement is not empty or not all whitespace.
  if text.len != 0:
    let matchesO = matchAllSpaceTab(text, 0)
    if not matchesO.isSome:
      result = true

proc matchEqualSign*(line: string, start: Natural = 0): Option[Matches] =
  ## Match an equal sign and the optional trailing whitespace.
  let pattern = r"(=)\s*"
  result = matchPatternCached(line, pattern, start)

proc matchLeftParentheses*(line: string, start: Natural = 0): Option[Matches] =
  ## Match a left parenthese and the optional trailing whitespace.
  let pattern = r"\(\s*"
  result = matchPatternCached(line, pattern, start)

proc matchCommaParentheses*(line: string, start: Natural = 0): Option[Matches] =
  ## Match a comma or right parentheses and the optional trailing whitespace.
  let pattern = r"([,)])\s*"
  result = matchPatternCached(line, pattern, start)

proc matchRightParentheses*(line: string, start: Natural = 0): Option[Matches] =
  ## Match a right parentheses and the optional trailing whitespace.
  let pattern = r"\)\s*"
  result = matchPatternCached(line, pattern, start)

proc matchNumber*(line: string, start: Natural = 0): Option[Matches] =
  ## Match a number and the optional trailing whitespace. Return the
  ## optional decimal point that tells whether the number is a float
  ## or integer.
  result = matchPatternCached(line, numberPattern, start)

func matchNumberNotCached*(line: string, start: Natural = 0): Option[Matches] =
  ## Match a number and the optional trailing whitespace. Return the
  ## optional decimal point that tells whether the number is a float
  ## or integer.
  result = matchPattern(line, numberPattern, start)

proc matchString*(line: string, start: Natural = 0): Option[Matches] =
  ## Match a string inside either single or double quotes.  The
  ## optional white space after the string is matched too. There are
  ## two returned groups and only one will contain anything. The first
  ## is for single quotes and the second is for double quotes.
  let pattern = """'([^']*)'\s*|"([^"]*)"\s*"""
  result = matchPatternCached(line, pattern, start)

proc matchLeftBracket*(line: string, start: Natural = 0): Option[Matches] =
  ## Match everything up to a left backet. The match length includes
  ## the bracket.

  # A replacement variable is inside brackets.
  # text on the line {variable} more text {variable2} asdf
  #                   ^
  let pattern = "[^{]*{"
  result = matchPatternCached(line, pattern, start)

proc matchFileLine*(line: string, start: Natural = 0): Option[Matches] =
  ## Match a file and line number like: filename(234).
  let pattern = r"^(.*)\(([0-9]+)\)$"
  result = matchPatternCached(line, pattern, start)

proc matchVersion*(line: string, start: Natural = 0): Option[Matches] =
  ## Match a StaticTea version number.
  result = matchPatternCached(line, versionPattern, start)

func matchVersionNotCached*(line: string, start: Natural = 0): Option[Matches] =
  ## Match a StaticTea version number.
  result = matchPattern(line, versionPattern, start)

proc matchDotNames*(line: string, start: Natural = 0): Option[Matches] =
  ## Matches variable dot names and surrounding whitespace. Return the
  ## leading whitespace and dot names as one string like:: "a.b.c.d".
  ## This is used to match functions too. They look like a variable
  ## followed by an open parentheses.
  ## @ 
  ## A dot name is a list of variable names separated by dots.
  ## You can have 1 to 5 variable names in a dot name.
  ## @
  ## A variable name starts with a letter followed by letters, digits
  ## and underscores limited to a total of 64 characters.
  ## @
  ## The match stops on the first non matching character. You need to
  ## check the next character to see whether it makes sense in the
  ## statement, for example, "t." matches and returns "t" but it is a
  ## syntax error.
  ## 
  ## Return two groups, the leading whitespace and the dotNames. The
  ## length returned includes the optional trailing whitespace.
  ##
  ## let dotNamesO = matchDotNames(line, start)
  ## if dotNamesO.isSome:
  ##   let (leadingSpaces, dotNameStr) = dotNamesO.get()

  let name = r"[a-zA-Z][a-zA-Z0-9_]{0,63}"
  let pattern = r"(\s*)((?:$1)(?:\.$1){0,4})\s*" % [name]
  result = matchPatternCached(line, pattern, start)
