[StaticTea Modules](./)

# env.nim

Environment holding the input and output streams.

# Index

* const: [dtFormat](#user-content-a0) &mdash; The date time format in local time written to the log.
* [staticteaLog](#user-content-a1) &mdash; Name of the default statictea log file when logging on the Mac.
* type: [Env](#user-content-a2) &mdash; Env holds the input and output streams.
* [close](#user-content-a3) &mdash; Close the environment streams.
* [warn](#user-content-a4) &mdash; Write a message to the error stream.
* [warn](#user-content-a5) &mdash; Write a formatted warning message to the error stream.
* [warn](#user-content-a6) &mdash; Write a formatted warning message to the error stream.
* [formatDateTime](#user-content-a7) &mdash; Return a formatted time stamp for the log.
* [formatLine](#user-content-a8) &mdash; Return a formatted log line.
* [logLine](#user-content-a9) &mdash; Append a message to the log file.
* [log](#user-content-a10) &mdash; Append the message to the log file.
* [writeOut](#user-content-a11) &mdash; Write a message to the output stream.
* [openEnv](#user-content-a12) &mdash; Open and return the environment containing standard error and standard out as streams.
* [setupLogging](#user-content-a13) &mdash; Turn on logging for the environment using the specified log file.
* [addExtraStreams](#user-content-a14) &mdash; Add the template and result streams to the environment.
* [addExtraStreams](#user-content-a15) &mdash; Add the template and result streams to the environment.
* [addExtraStreamsForUpdate](#user-content-a16) &mdash; For the update case, add the template and result streams to the environment.

# <a id="a0"></a>dtFormat

The date time format in local time written to the log.

```nim
dtFormat = "yyyy-MM-dd HH:mm:ss\'.\'fff"
```


# <a id="a1"></a>staticteaLog

Name of the default statictea log file when logging on the Mac.

```nim
staticteaLog = expandTilde("~/Library/Logs/statictea.log")
```


# <a id="a2"></a>Env

Env holds the input and output streams.

```nim
Env = object
  errStream*: Stream         ## stderr
  outStream*: Stream         ## stdout
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
  warningWritten*: Natural   ## Count of warnings written.
  oneWarnTable*: HashSet[string] ## All unique messages written.

```


# <a id="a3"></a>close

Close the environment streams.

```nim
proc close(env: var Env)
```


# <a id="a4"></a>warn

Write a message to the error stream. Duplicates are suppressed and the environment's warning count is incremented.

```nim
proc warn(env: var Env; message: string)
```


# <a id="a5"></a>warn

Write a formatted warning message to the error stream.

```nim
proc warn(env: var Env; lineNum: Natural; warning: Warning; p1: string = "";
          p2: string = "")
```


# <a id="a6"></a>warn

Write a formatted warning message to the error stream.

```nim
proc warn(env: var Env; lineNum: Natural; warningData: WarningData)
```


# <a id="a7"></a>formatDateTime

Return a formatted time stamp for the log.

```nim
func formatDateTime(dt: DateTime): string
```


# <a id="a8"></a>formatLine

Return a formatted log line.

```nim
func formatLine(filename: string; lineNum: int; message: string; dt = now()): string
```


# <a id="a9"></a>logLine

Append a message to the log file. If there is an error writing, close the log. Do nothing when the log is closed.

```nim
proc logLine(env: var Env; filename: string; lineNum: int; message: string)
```


# <a id="a10"></a>log

Append the message to the log file. The current file and line becomes part of the message.

```nim
template log(env: var Env; message: string)
```


# <a id="a11"></a>writeOut

Write a message to the output stream.

```nim
proc writeOut(env: var Env; message: string)
```


# <a id="a12"></a>openEnv

Open and return the environment containing standard error and standard out as streams.

```nim
proc openEnv(logFilename: string = ""; warnSize: BiggestInt = logWarnSize): Env
```


# <a id="a13"></a>setupLogging

Turn on logging for the environment using the specified log file.

```nim
proc setupLogging(env: var Env; logFilename: string = "";
                  warnSize: BiggestInt = logWarnSize)
```


# <a id="a14"></a>addExtraStreams

Add the template and result streams to the environment. Return true on success.

```nim
proc addExtraStreams(env: var Env; templateFilename: string;
                     resultFilename: string): bool
```


# <a id="a15"></a>addExtraStreams

Add the template and result streams to the environment. Return true on success.

```nim
proc addExtraStreams(env: var Env; args: Args): bool
```


# <a id="a16"></a>addExtraStreamsForUpdate

For the update case, add the template and result streams to the environment. Return true on success.

```nim
proc addExtraStreamsForUpdate(env: var Env; args: Args): bool
```



---
⦿ StaticTea markdown template for nim doc comments. ⦿
