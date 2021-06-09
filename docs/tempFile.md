[StaticTea Modules](/)

# tempFile.nim

Temporary file methods.

# Index

* type: [TempFile](#user-content-a0) &mdash; Temporary filename and file object.
* [openTempFile](#user-content-a1) &mdash; Create and open an empty file in the temp directory open for read write.
* [truncate](#user-content-a2) &mdash; Close the temp file, truncate it, then open it again.
* [closeDelete](#user-content-a3) &mdash; Close and delete the temp file.

# <a id="a0"></a>TempFile

Temporary filename and file object.

```nim
TempFile = object
  filename*: string
  file*: File

```


# <a id="a1"></a>openTempFile

Create and open an empty file in the temp directory open for read write. When no error, return TempFile containing the file and filename.

```nim
proc openTempFile(): Option[TempFile]
```


# <a id="a2"></a>truncate

Close the temp file, truncate it, then open it again.

```nim
proc truncate(tempFile: var TempFile)
```


# <a id="a3"></a>closeDelete

Close and delete the temp file.

```nim
proc closeDelete(tempFile: TempFile)
```



---
⦿ StaticTea markdown template for nim doc comments. ⦿
