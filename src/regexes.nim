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

import re
import options
import tables
when defined(test):
  import strutils
  import env

const
  ## The maximum number of groups supported in the matchPattern procedure.
  maxGroups = 10

var compliledPatterns = initTable[string, Regex]()
  ## A cache of compiled regex patterns, mapping a pattern to Regex.

type
  Matches* = object
    ## Holds the result of a match.
    groups*: seq[string]
    length*: Natural
    start*: Natural

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

# todo: is there a good way to replace the get groups method with one?

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

func matchRegex*(str: string, regex: Regex, start: Natural = 0): Option[Matches] =
  ## Match a regular expression pattern in a string.

  var groups = newSeq[string](maxGroups)
  let length = matchLen(str, regex, groups, start)
  if length != -1:
    var matches = Matches(length: length, groups: newSeq[string]())
    matches.length = length
    matches.start = start

    # Find the last non-empty group.
    var ixList = -1
    for ix, group in groups:
      if group != "":
        ixList = ix

    # Return the matches up to the last non-empty one.
    if ixList != -1:
      for ix in countUp(0, ixList):
        matches.groups.add(groups[ix])
    result = some(matches)

proc matchPatternCached*(str: string, pattern: string, start: Natural = 0): Option[Matches] =
  ## Match a pattern in a string. Cache the compiled regular
  ## expression pattern.

  # Get the cached regex for the pattern or compile it and add it to
  # the cache.
  var regex: Regex
  if pattern in compliledPatterns:
    regex = compliledPatterns[pattern]
  else:
    regex = re(pattern)
    compliledPatterns[pattern] = regex
  result = matchRegex(str, regex, start)

func matchPattern*(str: string, pattern: string, start: Natural = 0): Option[Matches] =
  ## Match a regular expression pattern in a string.
  result = matchRegex(str, re(pattern), start)

when defined(test):
  proc testMatchPattern*(str: string, pattern: string, start: Natural = 0,
      eMatchesO: Option[Matches] = none(Matches)): bool =
    ## Test matchPattern
    let matchesO = matchPattern(str, pattern, start)
    var header = """
line: "$1"
start: $2
pattern: $3""" % [str, $start, pattern]
    if not expectedItem(header, matchesO, eMatchesO):
      result = false
      echo ""
    else:
      result = true

  proc newMatches*(length: Natural, start: Natural, groups: varargs[string]): Matches =
    ## Return a Matches object.
    result.length = length
    result.start = start
    for group in groups:
      result.groups.add(group)

  proc newMatches*(length: Natural, start: Natural, groups: seq[string]): Matches =
    ## Return a Matches object.
    result.length = length
    result.start = start
    for group in groups:
      result.groups.add(group)
