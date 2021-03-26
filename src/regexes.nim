
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

  Matcher* = object
    ## A compiled regular expression.
    pattern*: string    ## The regular expression pattern.
    numGroups*: Natural ## The number of groups in the pattern.
    regex: Regex        ## The compiled regex.
    arg1*: string       ## The arg1 parameter of newMatcher.

proc newMatcher*(pattern: string, numGroups: Natural,
    arg1: string = ""): Matcher =
  ## Return a new matcher.  The regular expression pattern is
  ## compiled.  The numGroups is the number of groups defined in the
  ## pattern.  Note: all patterns are anchored. This makes a
  ## difference when matching and the start point is not 0.
  result.pattern = pattern
  result.regex = re(pattern)
  result.numGroups = numGroups
  result.arg1 = arg1

proc getGroup*(matches: Matches): string =
  ## Get the group when there is only one in matches.
  result = matches.groups[0]

proc get2Groups*(matches: Matches): (string, string) =
  ## Get the two groups when there are two groups in matches.
  result = (matches.groups[0], matches.groups[1])

proc get3Groups*(matches: Matches): (string, string, string) =
  ## Get the three groups when there are three groups in matches.
  result = (matches.groups[0], matches.groups[1], matches.groups[2])

proc getMatches*(matcher: Matcher, line: string, start: Natural = 0):
               Option[Matches] =
  ## Match the line with the matcher pattern starting at the "start"
  ## index in the line.  Return the matches object containing the
  ## matching groups and the length of the match.

  var matches: Matches
  var groups = newSeq[string](matcher.numGroups)
  var length: int
  if matcher.numGroups == 0:
    length = matchLen(line, matcher.regex, start)
  else:
    length = matchLen(line, matcher.regex, groups, start)
  if length != -1:
    matches.groups = groups
    matches.length = length
    matches.start = start
    result = some(matches)

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
  proc startPointer*(start: Natural): string =
    ## Return a string containing the number of spaces and symbols to
    ## point at the line start value. Display it under the line.
    if start > 100:
      result.add("$1" % $start)
    else:
      for ix in 0..<start:
        result.add(' ')
      result.add("^$1" % $start)

  proc checkMatches*(matchesO: Option[Matches], matcher: Matcher, line: string,
      expectedStart: Natural, expectedStrings: seq[string],
      expectedLength: Natural): bool =
    ## Return true when the matchesO object has the expected content,
    ## else return false. When false, show the expected text and the
    ## the actual text.

    if matchesO.isSome:
      var matches = matchesO.get()
      if matches.groups != expectedStrings or matches.length !=
          expectedLength or
         matches.start != expectedStart:
        echo "---Unexpected match---"
        echo "   line: $1" % [line]
        echo "  start: $1" % startPointer(matches.start)
        echo "pattern: $1" % matcher.pattern
        echo "expectedLength: $1, got: $2" % [$expectedLength, $matches.length]
        echo "expectedStart: $1, got: $2" % [$expectedStart, $matches.start]
        for group in expectedStrings:
          echo "expected: '$1'" % [group]
        for group in matches.groups:
          echo "     got: '$1'" % [group]
      else:
        result = true
    else:
      echo "---No match---"
      echo "   line: '$1'" % [line]
      echo "  start:  $1" % startPointer(expectedStart)
      echo "pattern: '$1'" % matcher.pattern

  # proc testMatchRegex*(str: string, pattern: string, start: Natural = 0,
  #     eMatchesO: Option[Matches] = none(Matches)): bool =
  proc checkMatcher*(matcher: Matcher, line: string, start: Natural,
      expectedStrings: seq[string], expectedLength: Natural): bool =
    ## Return true when the matcher matches the line with the
    ## expected outcome, else return false.
    let matchesO = getMatches(matcher, line, start)
    result = checkMatches(matchesO, matcher, line, start,
                          expectedStrings, expectedLength)

  proc checkMatcherNot*(matcher: Matcher, line: string,
      start: Natural = 0): bool =
    ## Return true when the matcher does not match.

    var matchesO = matcher.getMatches(line, start)
    if not matchesO.isSome:
      return true
    var matches = matchesO.get()

    echo "---Found unexpected match---"
    echo "   line: $1" % [line]
    echo "  start: $1" % startPointer(matches.start)
    echo "pattern: $1" % matcher.pattern
    for group in matches.groups:
      echo "got: '$1'" % [group]

  proc testMatchRegex*(str: string, pattern: string, start: Natural = 0,
      eMatchesO: Option[Matches] = none(Matches)): bool =
    ## Test matchRegex
    let matchesO = matchRegex(str, pattern, start)
    if not expectedItem("matchesO", matchesO, eMatchesO):
      result = false
    else:
      result = true

  proc newMatches*(length: Natural, start: Natural, groups: varargs[string]): Matches =
    result.length = length
    result.start = start
    for group in groups:
      result.groups.add(group)
