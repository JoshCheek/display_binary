Display Binary
==============

Playing with the idea of being able to provide a schema for how to make sense of
arbitrary binary data, which could then be diplayed to you to help you understand
the format of the file.

Conclusion
----------

The schema language would have to allow for all the nuances of a context
sensitive parser. Ie it basically becomes its own programming language :/

Hex dump of the png
-------------------

This is what I was trying to parse

```
0000000 89 50 4e 47 0d 0a 1a 0a 00 00 00 0d 49 48 44 52
0000010 00 00 00 80 00 00 00 44 08 02 00 00 00 c6 25 aa
0000020 3e 00 00 00 c2 49 44 41 54 78 5e ed d4 81 06 c3
0000030 30 14 40 d1 b7 34 dd ff ff 6f b3 74 56 ea 89 12
0000040 6c 28 73 e2 aa 34 49 03 87 d6 fe d8 7b 89 bb 52
0000050 8d 3b 87 fe 01 00 80 00 00 10 00 00 02 00 40 00
0000060 00 08 00 00 01 00 20 00 00 04 00 80 00 00 10 00
0000070 00 02 00 40 00 00 08 00 00 01 00 20 00 00 00 d4
0000080 5e 6a 64 4b 94 f5 98 7c d1 f4 92 5c 5c 3e cf 9c
0000090 3f 73 71 58 5f af 8b 79 5b ee 96 b6 47 eb f1 ea
00000a0 d1 ce b6 e3 75 3b e6 b9 95 8d c7 ce 03 39 c9 af
00000b0 c6 33 93 7b 66 37 cf ab bf f9 c9 2f 08 80 00 00
00000c0 10 00 00 02 00 40 00 00 08 00 00 01 00 20 00 00
00000d0 04 00 80 00 00 10 00 00 02 00 40 00 00 08 00 00
00000e0 01 00 20 00 00 8c 37 db 68 03 20 fb ed 96 65 00
00000f0 00 00 00 49 45 4e 44 ae 42 60 82
00000fb
```

Links I was maintaining
-----------------------

* CRC-32
  * https://www.w3.org/TR/PNG/#D-CRCAppendix
* PNG spec
  * http://www.libpng.org/pub/png/spec/1.2/PNG-DataRep.html#DR.Image-layout
  * http://www.libpng.org/pub/png/spec/1.2/PNG-Filters.html
  * http://www.libpng.org/pub/png/spec/1.2/PNG-Chunks.html#C.IHDR
  * https://en.wikipedia.org/wiki/Portable_Network_Graphics
* Compression
  * http://www.libpng.org/pub/png/spec/1.2/PNG-Compression.html


Parsing a PNG
-------------

This was just to understand it. Mostly written after I did the code in the lib,
to see where I needed to go next. I got stuck on the CRC checksum, and wasn't
able to make sense of the pixel data, but I was far enough to see that the problem
was going to be much larger than I had initially anticipated.

```ruby
require 'zlib'

def bytes_to_num(bytes)
  bytes.inject(0) { |n, hex| n*256 + hex }
end

body  = File.read "spec/fixtures/PNG-Gradient.png"
bytes = body.bytes

puts "=====  HEADER  ====="
puts "  First should be 0x80 (#{0x89}): #{bytes.shift}"
puts "  Next should be \"PNG\":       #{bytes.shift(3).map(&:chr).join.inspect}"
puts "  Next should be \"\\r\\n\":      #{bytes.shift(2).map(&:chr).join.inspect}"
puts "  Next should be 0x1A (#{0x1A}):   #{bytes.shift}"
puts "  Next should be \"\\n\":        #{bytes.shift.chr.inspect}"

puts "=====  CHUNKS  ====="
until bytes.empty?
  length       = bytes_to_num bytes.shift(4)
  type         = bytes.shift(4).map(&:chr).join
  data         = bytes.shift(length)
  crc_bytes    = bytes.shift(4)
  actual_crc   = bytes_to_num crc_bytes
  expected_crc = Zlib.crc32 data.map(&:chr).join, 2**32
  puts "  -----  CHUNK  -----"
  puts "    Length:        #{length.inspect}"
  puts "    Type:          #{type.inspect}"
  puts "    Data:          #{data.inspect}"
  puts "    Actual CRC:    #{actual_crc.inspect}"
  puts "    My broken CRC: #{expected_crc.inspect}"
  case type.upcase
  when 'IHDR'
    puts
    puts "    Width:              #{bytes_to_num data.shift(4)}"
    puts "    Height:             #{bytes_to_num data.shift(4)}"
    puts "    Bit depth:          #{data.shift}"

    color_type = data.shift
    explanation = {
      0 => "Each pixel is a grayscale sample.",
      2 => "Each pixel is an R,G,B triple.",
      3 => "Each pixel is a palette index; a PLTE chunk must appear.",
      4 => "Each pixel is a grayscale sample, followed by an alpha sample.",
      6 => "Each pixel is an R,G,B triple, followed by an alpha sample.",
    }[color_type]
    puts "    Color type:         #{color_type} (#{explanation})"
    puts "    Compression method: #{data.shift}"
    puts "    Filter method:      #{data.shift}"
    puts "    Interlace method:   #{data.shift}"
  else
    require "pry"
    binding.pry
    raise "Unknown data type: #{type.inspect}"
  end
end
```
