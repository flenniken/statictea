
## As the regular expressions supported by this module are enormous,
## the reader is referred to http://perldoc.perl.org/perlre.html for
## the full documentation of Perl's regular expressions.


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
when defined(test):
  import strutils
  import env

const
  ## The maximum number of groups allowed in the matchRegex procedure.
  maxGroups = 10

type
  Matches* = object
    ## Holds the result of a match.
    groups*: seq[string]
    length*: Natural
    start*: Natural
  # todo: remove start from Matches?

  # Matcher* = object
  #   ## A compiled regular expression.
  #   pattern*: string    ## The regular expression pattern.
  #   numGroups*: Natural ## The number of groups in the pattern.
  #   regex: Regex        ## The compiled regex.
  #   arg1*: string       ## The arg1 parameter of newMatcher.

# proc newMatcher*(pattern: string, numGroups: Natural,
#     arg1: string = ""): Matcher =
#   ## Return a new matcher.  The regular expression pattern is
#   ## compiled.  The numGroups is the number of groups defined in the
#   ## pattern.  Note: all patterns are anchored. This makes a
#   ## difference when matching and the start point is not 0.
#   result.pattern = pattern
#   result.regex = re(pattern)
#   result.numGroups = numGroups
#   result.arg1 = arg1

proc getGroup*(matches: Matches): string =
  ## Get the group when there is only one in matches.
  if matches.groups.len > 0:
    result = matches.groups[0]

proc get2Groups*(matches: Matches): (string, string) =
  ## Get the two groups when there are two groups in matches.
  var one: string
  var two: string
  if matches.groups.len > 0:
    one = matches.groups[0]
  if matches.groups.len > 1:
    two = matches.groups[1]
  result = (one, two)

proc get3Groups*(matches: Matches): (string, string, string) =
  ## Get the three groups when there are three groups in matches.
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

# todo: is there a good way to replace the get groups method with one?


# todo: cache regex and pattern.

proc matchRegex*(str: string, pattern: string, start: Natural = 0): Option[Matches] =
  ## Match a pattern in a string.

  var groups = newSeq[string](maxGroups)
  let regex = re(pattern)
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

when defined(test):
  proc testMatchRegex*(str: string, pattern: string, start: Natural = 0,
      eMatchesO: Option[Matches] = none(Matches)): bool =
    ## Test matchRegex
    let matchesO = matchRegex(str, pattern, start)
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
