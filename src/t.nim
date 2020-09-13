
proc theLines*(filename: string): seq[string] =
  ## Read all the lines in the file.
  for line in lines(filename):
    result.add line

var testLines = theLines("statictea.log")
echo testLines.len
