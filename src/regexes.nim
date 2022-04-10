## Perl regular expression matching.

# The notice below is there because this module includes the re module.
#[
Written by Philip Hazel
Copyright (c) 1997-2005 University of Cambridge

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

  Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.
  Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in the
  documentation and/or other materials provided with the distribution.
  Neither the name of the University of Cambridge nor the names of its
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]#

import std/re
import std/options
import std/tables

# todo: add optional parameter to specify regex flags.

const
  ## The maximum number of groups supported in the matchPattern procedure.
  maxGroups = 3

var compliledPatterns = initTable[string, Regex]()
  ## A cache of compiled regex patterns, mapping a pattern to Regex.

type
  Matches* = object
    ## Holds the result of a match.
    groups*: seq[string]
    length*: Natural
    start*: Natural
    numGroups*: Natural

  Replacement* = object
    ## Holds the regular expression and replacement for the replaceMany
    ## function.
    pattern*: string
    sub*: string

proc newMatches*(length: Natural, start: Natural, numGroups: Natural): Matches =
  result = Matches(length: length, start: start, numGroups: numGroups)

func getGroup*(matches: Matches): string =
  ## Get the first group in matches if it exists, else return "".
  if matches.groups.len > 0:
    result = matches.groups[0]

func get2Groups*(matches: Matches): (string, string) =
  ## Get the first two groups in matches. If one of the groups doesn't
  ## exist, "" is returned for it.
  var one: string
  var two: string
  if matches.groups.len > 0:
    one = matches.groups[0]
  if matches.groups.len > 1:
    two = matches.groups[1]
  result = (one, two)

func get3Groups*(matches: Matches): (string, string, string) =
  ## Get the first three groups in matches. If one of the groups doesn't
  ## exist, "" is returned for it.
  var one: string
  var two: string
  var three: string
  if matches.groups.len > 0:
    one = matches.groups[0]
  if matches.groups.len > 1:
    two = matches.groups[1]
  if matches.groups.len > 2:
    three = matches.groups[2]
  result = (one, two, three)

# template unpack*(matchesO: Option[Matches]): untyped =
#   ## Return the length of the match and its associated groups as a
#   ## tuple.
#   ## @:
#   ## @:Example:
#   ## @:~~~
#   ## @:let pattern = r"(abc).*(def)$"
#   ## @:let matchesO = matchPattern("  abc asdfasdfdef def", pattern, 2)
#   ## @:assert(matchesO.isSome)
#   ## @:let (length, one, two) = matchesO.unpack()
#   ## @:
#   ## @:echo "length = " & $length
#   ## @:echo "one = " & one
#   ## @:echo "two = " & two
#   ## @:~~~~

#   assert(matchesO.isSome, "Not a match.")

#   var tup: untyped
#   case matches.numGroups
#   of 1:
#     tup = matches.getGroup()
#   of 2:
#     tup = matches.get2Groups()
#   of 3:
#     tup = matches.get3Groups()
#   else:
#     assert(false == true, "wrong number of groups")
#   tup

func matchRegex*(str: string, regex: Regex, start: Natural = 0,
    numGroups: Natural = 0): Option[Matches] =
  ## Match a regular expression pattern in a string.

  assert(numGroups <= maxGroups, "Too many groups.")

  var groups = newSeq[string](maxGroups)
  let length = matchLen(str, regex, groups, start)
  if length != -1:
    var matches = newMatches(length, start, numGroups)

    for ix in 0 .. numGroups-1:
      matches.groups.add(groups[ix])

    result = some(matches)

func compilePattern(pattern: string): Option[Regex] =
  try:
    let regex = re(pattern)
    result = some(regex)
  except:
    result = none(Regex)

proc matchPatternCached*(str: string, pattern: string,
    start: Natural, numGroups: Natural): Option[Matches] =
  ## Match a pattern in a string and cache the compiled regular
  ## expression pattern.

  # Get the cached regex for the pattern or compile it and add it to
  # the cache.
  var regex: Regex
  if pattern in compliledPatterns:
    regex = compliledPatterns[pattern]
  else:
    let regexO = compilePattern(pattern)
    if not regexO.isSome:
      return
    regex = regexO.get()
    compliledPatterns[pattern] = regex
  result = matchRegex(str, regex, start, numGroups)

func matchPattern*(str: string, pattern: string,
    start: Natural, numGroups: Natural): Option[Matches] =
  ## Match a regular expression pattern in a string.
  let regexO = compilePattern(pattern)
  if not regexO.isSome:
    return
  result = matchRegex(str, regexO.get(), start, numGroups)

func newReplacement*(pattern: string, sub: string): Replacement =
  ## Create a new Replacement object.
  result = Replacement(pattern: pattern, sub: sub)

proc replaceMany*(str: string, replacements: seq[Replacement]): Option[string] =
  ## Replace the patterns in the string with their replacements.

  var subs: seq[tuple[pattern: Regex, repl: string]]
  for r in replacements:
    let regexO = compilePattern(r.pattern)
    if not regexO.isSome:
      return
    let regex = regexO.get()
    subs.add((regex, r.sub))
  result = some(multiReplace(str, subs))

proc newMatches*(length: Natural, start: Natural): Matches =
  result = Matches(length: length, start: start)

proc newMatches*(length: Natural, start: Natural, group: string): Matches =
  var groups = @[group]
  result = Matches(groups: groups, length: length, start: start, numGroups: 1)

proc newMatches*(length: Natural, start: Natural, group1: string,
    group2: string): Matches =
  var groups = @[group1, group2]
  result = Matches(groups: groups, length: length, start: start, numGroups: 2)

proc newMatches*(length: Natural, start: Natural, group1: string,
    group2: string, group3: string): Matches =
  var groups = @[group1, group2, group3]
  result = Matches(groups: groups, length: length, start: start, numGroups: 3)
