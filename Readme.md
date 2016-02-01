Playing with the idea of being able to provide a schema for how to make sense of
arbitrary binary data, which could then be diplayed to you to help you understand
the format of the file.

Conclusion: The schema language would have to allow for all the nuances of a context
sensitive parser. Ie it basically becomes its own programming language :/

* CRC-32
  * https://www.w3.org/TR/PNG/#D-CRCAppendix
* PNG spec
  * http://www.libpng.org/pub/png/spec/1.2/PNG-DataRep.html#DR.Image-layout
  * http://www.libpng.org/pub/png/spec/1.2/PNG-Filters.html
  * http://www.libpng.org/pub/png/spec/1.2/PNG-Chunks.html#C.IHDR
  * https://en.wikipedia.org/wiki/Portable_Network_Graphics
* Compression
  * http://www.libpng.org/pub/png/spec/1.2/PNG-Compression.html
