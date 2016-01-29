module DisplayBinary
  class Parse
    def initialize(stream, schema:)
      raise "NOT HANDLED SCHEMA: #{schema.inspect}" unless schema == :png
      self.stream = stream
      self.index  = 0
      self.buffer = []
      self.chunks = []
      self.schema = [
        { type: :byte,
          desc: "Has the high bit set to detect transmission systems that do not support 8 bit data and to reduce the chance that a text file is mistakenly interpreted as a PNG, or vice versa"
        },
        { type: :ascii,
          size: 3,
          desc: "In ASCII, the letters PNG, allowing a person to identify the format easily if it is viewed in a text editor."
        },
        { type: :ascii,
          size: 2,
          desc: "A DOS-style line ending (CRLF) to detect DOS-Unix line ending conversion of the data."
        },
        { type: :byte,
          desc: "A byte that stops display of the file under DOS when the command type has been used—the end-of-file character"
        },
        { type: :ascii,
          desc: "A Unix-style line ending (LF) to detect Unix-DOS line ending conversion."
        }
      ]
    end

    def chunk(index)
      read_through index
      chunks[index]
    end

    private

    attr_accessor :stream, :schema, :buffer, :index, :chunks

    def read_through(index)
      read_chunk if index() <= index
    end

    def read_chunk
      definition = schema[index] || raise("No definition at #{index}!")
      self.index += 1
      case definition[:type]
      when :byte
        chunk = Chunk::Byte.new(definition)
      when :ascii
        chunk = Chunk::Ascii.new(definition)
      else raise "No chunk reader for type #{definition[:type].inspect}"
      end
      chunk.use_bits get_bits(chunk.num_bits)
      chunks << chunk
    end

    def get_bits(num_bits)
      bits_needed  = num_bits - buffer.length
      bits_needed  = 0 if bits_needed < 0
      bits_needed += 1 until bits_needed % 8 == 0
      bytes_needed = bits_needed / 8
      byte_string  = stream.read(bytes_needed)
      bits         = byte_string.unpack("B*")[0].chars.map(&:to_i)
      buffer.concat bits
      buffer.shift bits_needed
    end
  end

  class Chunk
    attr_reader :type, :desc, :bits, :size

    def initialize(definition)
      @type = definition.fetch(:type)
      @size = (definition[:size] || 1)
      @desc = (definition[:desc] || "")
      @bits = []
    end

    def use_bits(bits)
      @bits.concat bits
    end

    class Byte < self
      def num_bits
        8
      end
      def value
        @value ||= bits.inject(0) { |n, b| n*2+b }
      end
    end

    class Ascii < self
      def num_bits
        8 * size
      end
      def value
        @value ||= bits.each_slice(8)
                       .map { |slice| slice.join.to_i(2).chr }
                       .join
      end
    end
  end
end
