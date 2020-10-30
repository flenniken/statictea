
## As the regular expressions supported by this module are enormous,
## the reader is referred to http://perldoc.perl.org/perlre.html for
## the full documentation of Perl's regular expressions.


# The notice below is there because this module includes the re module.
#[
Written by Philip Hazel
Copyright (c) 1997-2005 University of Cambridge

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

    Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
    Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
    Neither the name of the University of Cambridge nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]#

import re
import options
when defined(test):
  import strutils

type
  Matches* = object
    groups*: seq[string]
    length*: Natural

  Matcher* = object
    pattern*: string
    numGroups*: Natural
    regex: Regex

proc newMatcher*(pattern: string, numGroups: Natural): Matcher =
  ## Return a new matcher.  The regular expression string is compiled.
  ## The numGroups is the number of groups defined in the string.
  result.pattern = pattern
  result.regex = re(pattern)
  result.numGroups = numGroups

proc getGroup*(matches: Matches): string =
  result = matches.groups[0]

proc get2Groups*(matches: Matches): (string, string) =
  result = (matches.groups[0], matches.groups[1])

proc get3Groups*(matches: Matches): (string, string, string) =
  result = (matches.groups[0], matches.groups[1], matches.groups[2])

proc getMatches*(matcher: Matcher, line: string, start: Natural = 0): Option[Matches] =
  ## Match the line with the pattern.  Start is the starting index in
  ## line to start the match. Return the matched groups and the length
  ## of the match.

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
    result = some(matches)

when defined(test):
  proc startPointer*(start: Natural): string =
    ## Return the number of spaces and symbols to point at the line
    ## start value.
    if start > 100:
      result.add("$1" % $start)
    else:
      for ix in 0..<start:
        result.add(' ')
      result.add("^$1" % $start)

  proc checkMatch*(matcher: Matcher, line: string, start: Natural,
      expectedStrings: seq[string], expectedLength: Natural): bool =
    ## Return true when the matcher matches the line with the
    ## expected outcome, else return false.
    let matchO = getMatches(matcher, line, start)

    if matchO.isSome:
      var match = matchO.get()
      if match.groups != expectedStrings or match.length != expectedLength:
        echo "---Unexpected match---"
        echo "   line: $1" % [line]
        echo "  start: $1" % startPointer(start)
        echo "pattern: $1" % matcher.pattern
        echo "expectedLength: $1, got: $2" % [$expectedLength, $match.length]
        for group in expectedStrings:
          echo "expected: '$1'" % [group]
        for group in match.groups:
          echo "     got: '$1'" % [group]
      else:
        result = true
    else:
      echo "---No match---"
      echo "   line: '$1'" % [line]
      echo "  start: '$1'" % startPointer(start)
      echo "pattern: '$1'" % matcher.pattern
