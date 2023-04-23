# env.nim

Environment holding the input and output streams.


* [env.nim](../../src/env.nim) &mdash; Nim source code.
# Index

* const: [maxWarningsWritten](#maxwarningswritten) &mdash; The maximum number of warning messages to show.
* const: [staticteaLog](#statictealog) &mdash; Name of the default statictea log file.
* type: [Env](#env) &mdash; Env holds the input and output streams.
* [close](#close) &mdash; Close the environment streams.
* [outputWarning](#outputwarning) &mdash; Write a message to the error stream and increment the warning count.
* [warn](#warn) &mdash; Write a formatted warning message to the error stream.
* [warn](#warn-1) &mdash; Write a formatted warning message to the error stream.
* [warnNoFile](#warnnofile) &mdash; Write a formatted warning message to the error stream.
* [warnNoFile](#warnnofile-1) &mdash; Write a formatted warning message to the error stream.
* [writeOut](#writeout) &mdash; Write a message to the output stream.
* [writeErr](#writeerr) &mdash; Write a message to the error stream.
* [openEnvLogFile](#openenvlogfile) &mdash; Open the log file and update the environment.
* [openEnv](#openenv) &mdash; Open and return the environment containing standard error and standard out as streams.
* [setupLogging](#setuplogging) &mdash; Turn on logging for the environment using the specified log file.
* [addExtraStreams](#addextrastreams) &mdash; Add the template and result streams to the environment.
* [addExtraStreamsForUpdate](#addextrastreamsforupdate) &mdash; For the update case, add the template and result streams to the environment.

# maxWarningsWritten

The maximum number of warning messages to show.


~~~nim
maxWarningsWritten = 32
~~~

# staticteaLog

Name of the default statictea log file.  The path on the Mac is
different than the other platforms.


~~~nim
staticteaLog = "/Users/steve/Library/Logs/statictea.log"
~~~

# Env

Env holds the input and output streams.

* errStream — standard error stream; normally stderr but
  might be a normal file for testing.
* outStream — standard output stream; normally stdout but
  might be a normal file for testing.
* logFilename — the log filename
* closeErrStream — whether to close err stream. You don't
  close stderr.
* closeOutStream — whether to close out stream. You don't
  close stdout.
* closeTemplateStream — whether to close the template stream
* closeResultStream — whether to close the result stream
* templateFilename — name of the template file
* templateStream — template stream, may be stdin
* resultFilename — name of the result file
* resultStream — result stream, may be stdout
* warningsWritten — the total number of warnings


~~~nim
Env = object
  errStream*: Stream
  outStream*: Stream
  logFilename*: string
  closeErrStream*: bool
  closeOutStream*: bool
  closeTemplateStream*: bool
  closeResultStream*: bool
  templateFilename*: string
  templateStream*: Stream
  resultFilename*: string
  resultStream*: Stream
  warningsWritten*: Natural
~~~

# close

Close the environment streams.


~~~nim
proc close(env: var Env) {.raises: [Exception, IOError, OSError],
                           tags: [WriteIOEffect].}
~~~

# outputWarning

Write a message to the error stream and increment the warning
count.


~~~nim
proc outputWarning(env: var Env; lineNum: Natural; message: string) {.
    raises: [IOError, OSError, ValueError], tags: [WriteIOEffect].}
~~~

# warn

Write a formatted warning message to the error stream.


~~~nim
proc warn(env: var Env; filename: string; lineNum: Natural; warning: MessageId;
          p1: string = "") {.raises: [ValueError, IOError, OSError],
                             tags: [WriteIOEffect].}
~~~

# warn

Write a formatted warning message to the error stream.


~~~nim
proc warn(env: var Env; filename: string; lineNum: Natural;
          warningData: WarningData) {.raises: [ValueError, IOError, OSError],
                                      tags: [WriteIOEffect].}
~~~

# warnNoFile

Write a formatted warning message to the error stream.


~~~nim
proc warnNoFile(env: var Env; messageId: MessageId; p1: string = "") {.
    raises: [ValueError, IOError, OSError], tags: [WriteIOEffect].}
~~~

# warnNoFile

Write a formatted warning message to the error stream.


~~~nim
proc warnNoFile(env: var Env; warningData: WarningData) {.
    raises: [ValueError, IOError, OSError], tags: [WriteIOEffect].}
~~~

# writeOut

Write a message to the output stream.


~~~nim
proc writeOut(env: var Env; message: string) {.raises: [IOError, OSError],
    tags: [WriteIOEffect].}
~~~

# writeErr

Write a message to the error stream.


~~~nim
proc writeErr(env: var Env; message: string) {.raises: [IOError, OSError],
    tags: [WriteIOEffect].}
~~~

# openEnvLogFile

Open the log file and update the environment. If the log file
cannot be opened, a warning is output and the environment is
unchanged.


~~~nim
proc openEnvLogFile(env: var Env; logFilename: string) {.
    raises: [ValueError, IOError, OSError], tags: [WriteIOEffect].}
~~~

# openEnv

Open and return the environment containing standard error and
standard out as streams.


~~~nim
proc openEnv(logFilename: string = ""): Env
~~~

# setupLogging

Turn on logging for the environment using the specified log file.


~~~nim
proc setupLogging(env: var Env; logFilename: string = "") {.
    raises: [ValueError, IOError, OSError], tags: [WriteIOEffect].}
~~~

# addExtraStreams

Add the template and result streams to the environment.


~~~nim
proc addExtraStreams(env: var Env; templateFilename: string;
                     resultFilename: string): Option[WarningData] {.raises: [],
    tags: [ReadDirEffect].}
~~~

# addExtraStreamsForUpdate

For the update case, add the template and result streams to the
environment. Return true on success.


~~~nim
proc addExtraStreamsForUpdate(env: var Env; resultFilename: string;
                              templateFilename: string): Option[WarningData] {.
    raises: [ValueError], tags: [ReadEnvEffect, ReadIOEffect, ReadDirEffect].}
~~~


---
⦿ Markdown page generated by [StaticTea](https://github.com/flenniken/statictea/) from nim doc comments. ⦿
