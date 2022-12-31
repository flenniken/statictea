# env.nim

Environment holding the input and output streams.

* [env.nim](../src/env.nim) &mdash; Nim source code.
# Index

* const: [logWarnSize](#logwarnsize) &mdash; Warn the user when the log file gets over 1 GB.
* const: [dtFormat](#dtformat) &mdash; The date time format in local time written to the log.
* const: [maxWarningsWritten](#maxwarningswritten) &mdash; The maximum number of warning messages to show.
* const: [staticteaLog](#statictealog) &mdash; Name of the default statictea log file.
* type: [Env](#env) &mdash; Env holds the input and output streams.
* [close](#close) &mdash; Close the environment streams.
* [outputWarning](#outputwarning) &mdash; Write a message to the error stream and increment the warning count.
* [warn](#warn) &mdash; Write a formatted warning message to the error stream.
* [warn](#warn-1) &mdash; Write a formatted warning message to the error stream.
* [warnNoFile](#warnnofile) &mdash; Write a formatted warning message to the error stream.
* [warnNoFile](#warnnofile-1) &mdash; Write a formatted warning message to the error stream.
* [formatLogDateTime](#formatlogdatetime) &mdash; Return a formatted time stamp for the log.
* [formatLogLine](#formatlogline) &mdash; Return a formatted log line.
* [logLine](#logline) &mdash; Append a message to the log file.
* [log](#log) &mdash; Append the message to the log file.
* [writeOut](#writeout) &mdash; Write a message to the output stream.
* [writeErr](#writeerr) &mdash; Write a message to the error stream.
* [checkLogSize](#checklogsize) &mdash; Check the log file size and write a warning message when the file is big.
* [openLogFile](#openlogfile) &mdash; Open the log file and update the environment.
* [openEnv](#openenv) &mdash; Open and return the environment containing standard error and standard out as streams.
* [setupLogging](#setuplogging) &mdash; Turn on logging for the environment using the specified log file.
* [addExtraStreams](#addextrastreams) &mdash; Add the template and result streams to the environment.
* [addExtraStreamsForUpdate](#addextrastreamsforupdate) &mdash; For the update case, add the template and result streams to the environment.

# logWarnSize

Warn the user when the log file gets over 1 GB.

```nim
logWarnSize: int64 = 1073741824
```

# dtFormat

The date time format in local time written to the log.

```nim
dtFormat = "yyyy-MM-dd HH:mm:ss\'.\'fff"
```

# maxWarningsWritten

The maximum number of warning messages to show.

```nim
maxWarningsWritten = 32
```

# staticteaLog

Name of the default statictea log file.  The path on the Mac is different than the other platforms.

```nim
staticteaLog = "/Users/steve/Library/Logs/statictea.log"
```

# Env

Env holds the input and output streams.

* errStream -- standard error stream; normally stderr but
might be a normal file for testing.
* outStream -- standard output stream; normally stdout but
might be a normal file for testing.
* logFile -- the open log file
* logFilename -- the log filename
* closeErrStream -- whether to close err stream. You don't
close stderr.
* closeOutStream -- whether to close out stream. You don't
close stdout.
* closeTemplateStream -- whether to close the template stream
* closeResultStream -- whether to close the result stream
* templateFilename -- name of the template file
* templateStream -- template stream, may be stdin
* resultFilename -- name of the result file
* resultStream -- result stream, may be stdout
* warningsWritten -- the total number of warnings

```nim
Env = object
  errStream*: Stream
  outStream*: Stream
  logFile*: File
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

```

# close

Close the environment streams.

```nim
proc close(env: var Env)
```

# outputWarning

Write a message to the error stream and increment the warning count.

```nim
proc outputWarning(env: var Env; lineNum: Natural; message: string)
```

# warn

Write a formatted warning message to the error stream.

```nim
proc warn(env: var Env; filename: string; lineNum: Natural; warning: MessageId;
          p1: string = "")
```

# warn

Write a formatted warning message to the error stream.

```nim
proc warn(env: var Env; filename: string; lineNum: Natural;
          warningData: WarningData)
```

# warnNoFile

Write a formatted warning message to the error stream.

```nim
proc warnNoFile(env: var Env; messageId: MessageId; p1: string = "")
```

# warnNoFile

Write a formatted warning message to the error stream.

```nim
proc warnNoFile(env: var Env; warningData: WarningData)
```

# formatLogDateTime

Return a formatted time stamp for the log.

```nim
func formatLogDateTime(dt: DateTime): string
```

# formatLogLine

Return a formatted log line.

```nim
func formatLogLine(filename: string; lineNum: int; message: string; dt = now()): string
```

# logLine

Append a message to the log file. If there is an error writing, close the log. Do nothing when the log is closed. A newline is not added to the line.

```nim
proc logLine(env: var Env; filename: string; lineNum: int; message: string)
```

# log

Append the message to the log file. The current file and line becomes part of the message.

```nim
template log(env: var Env; message: string)
```

# writeOut

Write a message to the output stream.

```nim
proc writeOut(env: var Env; message: string)
```

# writeErr

Write a message to the error stream.

```nim
proc writeErr(env: var Env; message: string)
```

# checkLogSize

Check the log file size and write a warning message when the file is big.

```nim
proc checkLogSize(env: var Env)
```

# openLogFile

Open the log file and update the environment. If the log file cannot be opened, a warning is output and the environment is unchanged.

```nim
proc openLogFile(env: var Env; logFilename: string)
```

# openEnv

Open and return the environment containing standard error and standard out as streams.

```nim
proc openEnv(logFilename: string = ""; warnSize: int64 = logWarnSize): Env
```

# setupLogging

Turn on logging for the environment using the specified log file.

```nim
proc setupLogging(env: var Env; logFilename: string = "";
                  warnSize: int64 = logWarnSize)
```

# addExtraStreams

Add the template and result streams to the environment.

```nim
proc addExtraStreams(env: var Env; templateFilename: string;
                     resultFilename: string): Option[WarningData]
```

# addExtraStreamsForUpdate

For the update case, add the template and result streams to the environment. Return true on success.

```nim
proc addExtraStreamsForUpdate(env: var Env; resultFilename: string;
                              templateFilename: string): Option[WarningData]
```


---
⦿ Markdown page generated by [StaticTea](https://github.com/flenniken/statictea/) from nim doc comments. ⦿
