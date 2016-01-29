require 'display_binary'

class Asserter
  include RSpec::Matchers

  attr_accessor :parser, :position
  def initialize(parser)
    self.parser = parser
    self.position = 0
  end

  def byte!(value, assertions)
    assertions! assertions.merge(value: value)
  end

  def ascii!(value, assertions)
    assertions! assertions.merge(value: value)
  end

  def assertions!(assertions)
    chunk = parser.chunk(position)
    self.position += 1

    value = assertions.delete :value
    expect(chunk.value).to eq value

    desc = assertions.delete :desc
    if desc.kind_of? Regexp
      expect(chunk.desc).to match desc
    elsif desc
      expect(chunk.desc).to eq desc
    end

    if assertions.any?
      raise "No assertions for: #{assertions.keys.inspect}"
    end
  end
end

RSpec.describe 'Parsing a PNG' do
  let(:png_path) { File.expand_path "fixtures/PNG-Gradient.png", __dir__ }
  let(:stream)   { File.open png_path, 'rb' }
  after { stream.close }

  it 'parses a png file' do
    parser   = DisplayBinary::Parse.new(stream, schema: :png)
    asserter = Asserter.new(parser)
    asserter.byte!    0x89, desc: /^Has the/
    asserter.ascii!  "PNG", desc: /^In ASCII/
    asserter.ascii! "\r\n", desc: /^A DOS/
    asserter.byte!    0x1A, desc: /^A byte/
    asserter.ascii!   "\n", desc: /^A Unix-style/
  end
end
