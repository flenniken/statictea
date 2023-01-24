## Methods for matching sub-strings.

import std/strutils
import std/options
import regexes

const
  commands*: array[6, string] = [
    "nextline",
    "block",
    "replace",
    "#",
    ":",
    "endblock",
  ]
    ## The StaticTea commands.
    ## @:* nextline -- make substitutions in the next line
    ## @:* block —- make substitutions in the next block of lines
    ## @:* replace -— replace the block with a variable
    ## @:* "#" -- code comment
    ## @:* ":" -- continue a command
    ## @:* endblock -- end the block and replace commands

  numberPattern = r"-{0,1}[0-9][0-9_]*([\.]{0,1})[0-9_]*\s*"
    ## A number regular expression pattern. A number starts with an
    ## optional minus sign, followed by a digit, followed by digits,
    ## underscores or a decimal point. Only one decimal point is
    ## allowed and underscores are skipped.

  versionPattern = r"^([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})$"
    ## StaticTea version regular expression pattern.  It has
    ## three components each with one to three digits: i.e. 1.2.3,
    ## 123.456.789, 0.1.0,... .

proc parsePrepost*(str: string): Option[tuple[prefix: string, postfix:string]] =
  ## Parse the prepost item on the terminal command line.  A prefix is
  ## followed by an optional postfix, prefix[,postfix].  Each part
  ## contains 1 to 20 ascii characters including spaces but without
  ## control characters or commas.
  let pattern = "([\x20-\x2b\x2d-\x7F]{1,20})(?:,([\x20-\x2b\x2d-\x7F]{1,20})){0,1}$"
  let matchesO = matchPattern(str, pattern, 0, 2)
  if matchesO.isSome:
    let (prefix, postfix) = matchesO.get2Groups()
    result = some((prefix, postfix))

proc matchPrefix*(line: string, prefixes: seq[string],
    start: Natural = 0): Option[Matches] =
  ## Match lines that start with one of the prefixes in the given
  ## table plus optional following whitespace.
  var terms = newSeq[string]()
  for prefix in prefixes:
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
  ## optional line endings. A match has two groups, the plus sign and
  ## the line ending. When nothing at the end, return groups: "", "".
  if start >= line.len:
    return some(newMatches(0, start, "", ""))
  var pattern: string
  if postfix == "":
    pattern = r"([+]{0,1})([\r]{0,1}\n){0,1}$"
  else:
    pattern = r"([+]{0,1})\Q$1\E([\r]{0,1}\n){0,1}$" % postfix
  result = matchPatternCached(line, pattern, start, 2)

proc getLastPart*(line: string, postfix: string): Option[Matches] =
  ## Return the optional plus sign and line endings from the line.

  # Start checking 3 characters before the end to account for the
  # optional plus sign, cr and linefeed. If the line is too short,
  # return no match.  Note that a nim regex uses the anchored
  # option.
  #
  # 123456
  # 0123456
  # +-->rn
  #  +-->n
  #   -->n
  #    -->

  let startPos = line.len - postfix.len - 3
  for start in countUp(startPos, startPos+3):
    if start < 0:
      continue
    let matchesO = matchLastPart(line, postfix, start)
    if matchesO.isSome:
      return matchesO

proc matchTabSpace*(line: string, start: Natural = 0): Option[Matches] =
  ## Match one or more spaces or tabs starting at the given position.
  let pattern = r"[ \t]+"
  result = matchPatternCached(line, pattern, start, 0)

proc emptyOrSpaces*(text: string, start: Natural = 0): bool =
  ## Return true when the text is empty or all whitespace from start to the end.
  if start >= text.len:
    return true
  let pattern = r"[ \t]*$"
  let matchesO = matchPatternCached(text, pattern, start, 0)
  if matchesO.isSome:
    result = true

proc matchEqualSign*(line: string, start: Natural = 0): Option[Matches] =
  ## Match an equal sign or "&=" and the optional trailing
  ## whitespace. Return the operator in the group, "=" or "&=".
  let pattern = r"(&{0,1}=)\s*"
  result = matchPatternCached(line, pattern, start, 1)

proc matchCommaParentheses*(line: string, start: Natural = 0): Option[Matches] =
  ## Match a comma or right parentheses and the optional trailing whitespace.
  let pattern = r"([,)])\s*"
  result = matchPatternCached(line, pattern, start, 1)

proc matchNumber*(line: string, start: Natural = 0): Option[Matches] =
  ## Match a number and the optional trailing whitespace. Return the
  ## optional decimal point that tells whether the number is a float
  ## or integer.
  result = matchPatternCached(line, numberPattern, start, 1)

func matchNumberNotCached*(line: string, start: Natural = 0): Option[Matches] =
  ## Match a number and the optional trailing whitespace. Return the
  ## optional decimal point that tells whether the number is a float
  ## or integer. "Not cached" allows it to be called by a function
  ## because it has no side effects.
  result = matchPattern(line, numberPattern, start, 1)

proc matchUpToLeftBracket*(line: string, start: Natural = 0): Option[Matches] =
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
  ## Match a StaticTea version number. "Not cached" allows it to be
  ## called by a function because it has no side effects.
  result = matchPattern(line, versionPattern, start, 3)

proc matchDotNames*(line: string, start: Natural = 0): Option[Matches] =
  ## Matches variable dot names and surrounding whitespace. Return the
  ## dot names as one string like "a.b.c.d".
  ## @:
  ## @:A dot name is a list of variable names separated y dots.
  ## @:You can have 1 to 5 variable names in a dot name.
  ## @:
  ## @:A variable name starts with a letter followed by letters, digits
  ## @:minuses and underscores limited to a total of 64 characters.
  ## @:No space is allowed between the function name and the left
  ## @:parentheses or bracket.
  ## @:Return three groups, the leading whitespace, the dotNames and the
  ## @:optional left parentheses or bracket following the dot name. The
  ## @:length returned includes the optional trailing whitespace.
  ## @:
  ## @:Example call:
  ## @:
  ## @:~~~
  ## @:let (_, dotNameStr, leftParenBrack, dotNameLen) = matchesO.get3GroupsLen()
  ## @:~~~~

  let name = r"[a-zA-Z][a-zA-Z0-9_-]{0,63}"
  let pattern = r"(\s*)((?:$1)(?:\.$1){0,4})([\(\[]){0,1}\s*" % [name]
  result = matchPatternCached(line, pattern, start, 3)

type
  GroupSymbol* = enum
    ## Grouping symbols we search for in the statements.
    gLeftParentheses # (
    gRightParentheses # )
    gLeftBracket # [
    gRightBracket # ]
    gComma # ,
    gColon # :

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
  of gColon:
    pattern = r"([,:])\s*"
  of gComma:
    # No match.
    return
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
  of gColon:
    pattern = r":\s*"
  of gComma:
    pattern = r",\s*"
  result = matchPatternCached(line, pattern, start, 0)

proc matchNotOrParen*(line: string, start: Natural = 0): Option[Matches] =
  ## Match "not " or "(" and the trailing whitespace.
  let pattern = r"(not |\()\s*"
  result = matchPatternCached(line, pattern, start, 1)

proc matchBoolExprOperator*(line: string, start: Natural): Option[Matches] =
  ## Match boolean expression operators (bool operators plus compareh
  ## operators) and the trailing whitespace.  The bool operators
  ## require a trailing space but it isn't part of the operator name
  ## returned but still in the length.
  let pattern = r"(==|!=|<=|>=|<|>)\s*|(and|or)\s+"
  result = matchPatternCached(line, pattern, start, 2)
  if result.isSome:
    # Return one group.
    var (a, b) = result.get2Groups()
    var operator: string
    if a != "":
      operator = a
    else:
      operator = b
    result = some(newMatches(result.get().length, start, operator))

proc matchCompareOperator*(line: string, start: Natural): Option[Matches] =
  ## Match the compare operators and the trailing whitespace.
  let pattern = r"(==|!=|<=|>=|<|>)\s*"
  result = matchPatternCached(line, pattern, start, 1)

proc matchReplCmd*(line: string, start: Natural): Option[Matches] =
  ## Match the REPL commands and the trailing optional whitespace.
  let pattern = r"(pr|pj|ph|h|v|q|p)\s*"
  result = matchPatternCached(line, pattern, start, 1)

proc matchParameterType*(line: string, start: Natural): Option[Matches] =
  ## Match a parameter type and the trailing whitespace.
  let pattern = r"(optional\s*){0,1}(bool|int|float|string|dict|list|func|any)\s*"
  result = matchPatternCached(line, pattern, start, 2)

proc matchDocComment*(line: string, start: Natural): Option[Matches] =
  ## Match a doc comment.
  let pattern = r"\s*##"
  result = matchPatternCached(line, pattern, start, 0)

proc matchReturnStatement*(line: string, start: Natural): Option[Matches] =
  ## Match a return statement. a = return(...
  let pattern = r"\s*[a-z-A-Z_]*\s*[=&]\s*return("
  result = matchPatternCached(line, pattern, start, 0)
