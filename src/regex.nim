
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

type
  Pattern* = Regex

proc getPattern*(reString: string): Pattern =
  ## Compile the regular expression string and return a pattern used
  ## with match and matches.
  result = re(reString)

proc match*(str: string, pattern: Pattern): bool =
  ## Return true when the string matches the pattern.
  result = str =~ pattern

proc matches*(str: string, pattern: Pattern, groups: var openArray[string]): bool =
  ## Return true when the string matches the pattern and fill in the
  ## groups array with the groups found. Usage:
  ##
  ## let pattern = getPattern(r"^([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})$")
  ## var groups: array[3, string]
  ## check matches("5.67.8", pattern, groups)
  ## check groups[0] == "5"
  ## check groups[1] == "67"
  ## check groups[2] == "8"
  result = match(str, pattern, groups)
