
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

type
  Pattern* = object
    regex*: Regex
    numGroups*: Natural

  Matches* = object
    groups*: seq[string]
    length*: Natural
# todo: make groups and length private?

proc getGroup*(matches: Matches): string =
  result = matches.groups[0]

proc get2Groups*(matches: Matches): (string, string) =
  result = (matches.groups[0], matches.groups[1])

proc get3Groups*(matches: Matches): (string, string, string) =
  result = (matches.groups[0], matches.groups[1], matches.groups[2])


proc getPattern*(reString: string, numGroups: Natural): Pattern =
  ## Compile the regular expression string. Pass the number of groups
  ## defined in the string.
  result.regex = re(reString)
  result.numGroups = numGroups

proc getMatches*(str: string, pattern: Pattern, start: Natural = 0): Option[Matches] =
  ## Match the str with the pattern.  Start is the starting index in
  ## str to start the match. Return the groups and the length of the
  ## match.

  var matches: Matches
  var groups = newSeq[string](pattern.numGroups)
  var length: int
  if pattern.numGroups == 0:
    length = matchLen(str, pattern.regex, start)
  else:
    length = matchLen(str, pattern.regex, groups, start)
  if length != -1:
    matches.groups = groups
    matches.length = length
    result = some(matches)
