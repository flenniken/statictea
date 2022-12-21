## Perl regular expression matching.
## @:
## @:Examples:
## @:
## @:Match a string with "abc" in it:
## @:
## @:~~~
## @:let line = "123abc456"
## @:let pattern = ".@.abc"
## @:let matchesO = matchPattern(line, pattern, start=0, numGroups=0)
## @:
## @:check matchesO.isSome == true
## @:check matchesO.get().length == 6
## @:~~~~
## @:
## @:Match a file and line number like: filename(234):
## @:
## @:~~~
## @:let line = "template.html(87)"
## @:let pattern = r"^(.@.)\(([0-9]+)\)$"
## @:let matchesO = matchPatternCached(line, pattern, 0, 2)
## @:
## @:check matchesO.isSome == true
## @:let (filename, lineNum) = matchesO.get2Groups()
## @:check filename == "template.html"
## @:check lineNum == "87"
## @:~~~~
## @:
## @:Replace the patterns in the string with their replacements:
## @:
## @:~~~
## @:var replacements: seq[Replacement]
## @:replacements.add(newReplacement("abc", "456"))
## @:replacements.add(newReplacement("def", ""))
## @:
## @:let resultStringO = replaceMany("abcdefabc", replacements)
## @:
## @:check resultStringO.isSome
## @:check resultStringO.get() == "456456"
## @:~~~~

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

const
  maxGroups = 10
    ## The maximum number of groups supported in the matchPattern
    ## procedure.

var compliledPatterns = initTable[string, Regex]()
  ## A cache of compiled regex patterns, mapping a pattern to Regex.

type
  Matches* = object
    ## Holds the result of a match.
    ## @:* groups -- list of matching groups
    ## @:* length -- length of the match
    ## @:* start -- where the match started
    ## @:* numGroups -- number of groups
    groups*: seq[string]
    length*: Natural
    start*: Natural
    numGroups*: Natural

  Replacement* = object
    ## Holds the regular expression pattern and its replacement for
    ## the replaceMany function.
    pattern*: string
    sub*: string

func newMatches*(length: Natural, start: Natural): Matches =
  ## Create a new Matches object with no groups.
  result = Matches(length: length, start: start)

func newMatches*(length: Natural, start: Natural, group: string): Matches =
  var groups = @[group]
  ## Create a new Matches object with one group.
  result = Matches(groups: groups, length: length, start: start, numGroups: 1)

func newMatches*(length: Natural, start: Natural, group1: string,
    group2: string): Matches =
  ## Create a new Matches object with two groups.
  var groups = @[group1, group2]
  result = Matches(groups: groups, length: length, start: start, numGroups: 2)

func newMatches*(length: Natural, start: Natural, group1: string,
    group2: string, group3: string): Matches =
  ## Create a new Matches object with three groups.
  var groups = @[group1, group2, group3]
  result = Matches(groups: groups, length: length, start: start, numGroups: 3)

proc newMatches*(length: Natural, start: Natural, groups: seq[string]): Matches =
  ## Create a Matches object with the given number of groups.
  result = Matches(length: length, start: start, groups: groups,
                   numGroups: groups.len)

proc newMatches*(length: Natural, start: Natural, numGroups: Natural): Matches =
  ## Create a Matches object with the given number of groups.
  result = Matches(length: length, start: start, numGroups: numGroups)

func newReplacement*(pattern: string, sub: string): Replacement =
  ## Create a new Replacement object.
  result = Replacement(pattern: pattern, sub: sub)

func getGroup*(matches: Matches): string =
  ## Get the group in matches.
  if matches.groups.len > 0:
    result = matches.groups[0]

func getGroupLen*(matches: Matches): (string, Natural) =
  ## Get the group in matches.
  if matches.groups.len > 0:
    result = (matches.groups[0], matches.length)

func getGroup*(matchesO: Option[Matches]): string =
  ## Get the group in matches.
  assert(matchesO.isSome, "Not a match")
  result = matchesO.get().getGroup()

func getGroupLen*(matchesO: Option[Matches]): (string, Natural) =
  ## Get the group in matches and the match length.
  assert(matchesO.isSome, "Not a match")
  result = matchesO.get().getGroupLen()

func get2Groups*(matches: Matches): (string, string) =
  ## Get two groups in matches.
  var one: string
  var two: string
  if matches.groups.len > 0:
    one = matches.groups[0]
  if matches.groups.len > 1:
    two = matches.groups[1]
  result = (one, two)

func get2GroupsLen*(matches: Matches): (string, string, Natural) =
  ## Get two groups and length in matches.
  var one: string
  var two: string
  if matches.groups.len > 0:
    one = matches.groups[0]
  if matches.groups.len > 1:
    two = matches.groups[1]
  result = (one, two, matches.length)

func get2Groups*(matchesO: Option[Matches]): (string, string) =
  ## Get two groups in matches.
  assert(matchesO.isSome, "Not a match")
  result = matchesO.get().get2Groups()

func get2GroupsLen*(matchesO: Option[Matches]): (string, string, Natural) =
  ## Get two groups and length in matchesO.
  assert(matchesO.isSome, "Not a match")
  result = matchesO.get().get2GroupsLen()

func get3Groups*(matches: Matches): (string, string, string) =
  ## Get three groups in matches.
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

func get3Groups*(matchesO: Option[Matches]): (string, string, string) =
  ## Get three groups in matches.
  assert(matchesO.isSome, "Not a match")
  result = matchesO.get().get3Groups()

func get3GroupsLen*(matchesO: Option[Matches]):
    (string, string, string, Natural) =
  ## Return the three groups and the length of the match.
  let matches = matchesO.get()
  let (one, two, three) = matches.get3Groups()
  result = (one, two, three, matches.length)

func getGroups*(matches: Matches, numGroups: Natural): seq[string] =
  ## Return the number of groups specified. If one of the groups doesn't
  ## exist, "" is returned for it.

  assert(numGroups <= maxGroups, "Too many groups")
  if numGroups > maxGroups:
    return

  var groups = newSeqOfCap[string](numGroups)
  for ix in countUp(0, numGroups-1):
    if ix < matches.groups.len:
      groups.add(matches.groups[ix])
    else:
      groups.add("")
  result = groups

func getGroups*(matchesO: Option[Matches], numGroups: Natural): seq[string] =
  ## Return the number of groups specified. If one of the groups doesn't
  ## exist, "" is returned for it.
  assert(matchesO.isSome, "Not a match")
  result = matchesO.get().getGroups(numGroups)
  
func matchRegex(str: string, regex: Regex, start: Natural,
    numGroups: Natural): Option[Matches] =
  ## Match a regular expression pattern in a string. Start is the
  ## index in the string to start the search. NumGroups is the number
  ## of groups in the pattern.

  if start >= str.len:
    return

  assert(numGroups <= maxGroups, "Too many groups.")
  if numGroups > maxGroups:
    return

  var groups = newSeq[string](maxGroups)
  let length = matchLen(str, regex, groups, start)
  if length != -1:
    var matches = newMatches(length, start, numGroups)

    for ix in 0 .. numGroups-1:
      matches.groups.add(groups[ix])

    result = some(matches)

func compilePattern(pattern: string): Option[Regex] =
  ## Compile the pattern and return a regex object.
  try:
    let regex = re(pattern)
    result = some(regex)
  except:
    result = none(Regex)

func matchPattern*(str: string, pattern: string,
    start: Natural, numGroups: Natural): Option[Matches] =
  ## Match a regular expression pattern in a string. Start is the
  ## @:index in the string to start the search. NumGroups is the number
  ## @:of groups in the pattern.
  ## @:
  ## @:Note: the pattern uses the anchored option.
  let regexO = compilePattern(pattern)
  if not regexO.isSome:
    return
  result = matchRegex(str, regexO.get(), start, numGroups)

proc matchPatternCached*(str: string, pattern: string,
    start: Natural, numGroups: Natural): Option[Matches] =
  ## Match a pattern in a string and cache the compiled regular
  ## @:expression pattern for next time. Start is the index in the
  ## @:string to start the search. NumGroups is the number of groups in
  ## @:the pattern.

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
