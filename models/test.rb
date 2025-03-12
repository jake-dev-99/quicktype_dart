# This code may look unusually verbose for Ruby (and it is), but
# it performs some subtle and complex validation of JSON data.
#
# To parse this JSON, add 'dry-struct' and 'dry-types' gems, then do:
#
#   test = Test.from_json! "{…}"
#   puts test.asdf
#
#   convert = Convert.from_json! "{…}"
#   puts convert
#
# If from_json! succeeds, the value returned matches the schema.

require 'json'
require 'dry-types'
require 'dry-struct'

module Types
  include Dry.Types(default: :nominal)

  Hash   = Strict::Hash
  String = Strict::String
end

class Test < Dry::Struct
  attribute :asdf,  Types::String
  attribute :asdf2, Types::String

  def self.from_dynamic!(d)
    d = Types::Hash[d]
    new(
      asdf:  d.fetch("asdf"),
      asdf2: d.fetch("asdf2"),
    )
  end

  def self.from_json!(json)
    from_dynamic!(JSON.parse(json))
  end

  def to_dynamic
    {
      "asdf"  => asdf,
      "asdf2" => asdf2,
    }
  end

  def to_json(options = nil)
    JSON.generate(to_dynamic, options)
  end
end

class Convert < Dry::Struct

  def self.from_dynamic!(d)
    d = Types::Hash[d]
    new(
    )
  end

  def self.from_json!(json)
    from_dynamic!(JSON.parse(json))
  end

  def to_dynamic
    {
    }
  end

  def to_json(options = nil)
    JSON.generate(to_dynamic, options)
  end
end
