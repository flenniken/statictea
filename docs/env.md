# env.nim

Environment holding the input and output streams.

* [env.nim](../src/env.nim) &mdash; Nim source code.
# Index

* const: [logWarnSize](#logwarnsize) &mdash; Warn the user when the log file gets over 1 GB.
* const: [dtFormat](#dtformat) &mdash; The date time format in local time written to the log.
* const: [maxWarningsWritten](#maxwarningswritten) &mdash; The maximum of warning messages to show.
* [staticteaLog](#statictealog) &mdash; Name of the default statictea log file when logging on the Mac.
* type: [Env](#env) &mdash; Env holds the input and output streams.
* [close](#close) &mdash; Close the environment streams.
* [outputWarning](#outputwarning) &mdash; Write a message to the error stream and increment the warning count.
* [warn](#warn) &mdash; Write a formatted warning message to the error stream.
* [warn](#warn-1) &mdash; Write a formatted warning message to the error stream.
* [formatDateTime](#formatdatetime) &mdash; Return a formatted time stamp for the log.
* [formatLine](#formatline) &mdash; Return a formatted log line.
* [logLine](#logline) &mdash; Append a message to the log file.
* [log](#log) &mdash; Append the message to the log file.
* [writeOut](#writeout) &mdash; Write a message to the output stream.
* [openEnv](#openenv) &mdash; Open and return the environment containing standard error and standard out as streams.
* [setupLogging](#setuplogging) &mdash; Turn on logging for the environment using the specified log file.
* [addExtraStreams](#addextrastreams) &mdash; Add the template and result streams to the environment.
* [addExtraStreams](#addextrastreams-1) &mdash; Add the template and result streams to the environment.
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

The maximum of warning messages to show.

```nim
maxWarningsWritten = 10
```

# staticteaLog

Name of the default statictea log file when logging on the Mac.

```nim
staticteaLog = expandTilde("~/Library/Logs/statictea.log")
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
* warningWritten -- the total number of warnings

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
  warningWritten*: Natural

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
proc warn(env: var Env; lineNum: Natural; warning: MessageId; p1: string = "")
```

# warn

Write a formatted warning message to the error stream.

```nim
proc warn(env: var Env; lineNum: Natural; warningData: WarningData)
```

# formatDateTime

Return a formatted time stamp for the log.

```nim
func formatDateTime(dt: DateTime): string
```

# formatLine

Return a formatted log line.

```nim
func formatLine(filename: string; lineNum: int; message: string; dt = now()): string
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

Add the template and result streams to the environment. Return true on success.

```nim
proc addExtraStreams(env: var Env; templateFilename: string;
                     resultFilename: string): bool
```

# addExtraStreams

Add the template and result streams to the environment. Return true on success.

```nim
proc addExtraStreams(env: var Env; args: Args): bool
```

# addExtraStreamsForUpdate

For the update case, add the template and result streams to the environment. Return true on success.

```nim
proc addExtraStreamsForUpdate(env: var Env; args: Args): bool
```


---
⦿ Markdown page generated by [StaticTea](https://github.com/flenniken/statictea/) from nim doc comments. ⦿
