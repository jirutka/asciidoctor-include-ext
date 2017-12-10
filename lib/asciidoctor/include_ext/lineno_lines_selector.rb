# frozen_string_literal: true
require 'asciidoctor/include_ext/version'

module Asciidoctor::IncludeExt
  # Lines selector that selects lines of the content to be included based on
  # the specified ranges of line numbers.
  #
  # @note Instance of this class can be used only once, as a predicate to
  #   filter a single include directive.
  #
  # @example
  #   include::some-file.adoc[lines=1;3..4;6..-1]
  #
  # @example
  #   selector = LinenoLinesSelector.new("some-file.adoc", {"lines" => "1;3..4;6..-1"})
  #   IO.foreach(filename).select.with_index(1, &selector)
  #
  # @see http://asciidoctor.org/docs/user-manual#by-line-ranges
  class LinenoLinesSelector

    # @return [Integer, nil] 1-based line number of the first included line,
    #   or `nil` if none.
    attr_reader :first_included_lineno

    # @param attributes [Hash<String, String>] the attributes parsed from the
    #   `include::[]`s attributes slot.
    # @return [Boolean] `true` if the *attributes* hash contains a key `"lines"`.
    def self.handles?(_, attributes)
      attributes.key? 'lines'
    end

    # @param attributes [Hash<String, String>] the attributes parsed from the
    #   `include::[]`s attributes slot. It must contain a key `"lines"`.
    def initialize(_, attributes, **)
      @ranges = parse_attribute(attributes['lines'])
      @first_included_lineno = @ranges.last.first unless @ranges.empty?
    end

    # Returns `true` if the given line should be included, `false` otherwise.
    #
    # @note This method modifies state of this object. It's supposed to be
    #   called successively with each line of the content being included.
    #   See {LinenoLinesSelector example}.
    #
    # @param line_num [Integer] 1-based *line* number.
    # @return [Boolean] `true` to select the *line*, or `false` to reject.
    def include?(_, line_num)
      return false if @ranges.empty?

      ranges = @ranges
      ranges.pop while !ranges.empty? && ranges.last.last < line_num
      ranges.last.cover?(line_num) if !ranges.empty?
    end

    # @return [Proc] {#include?} method as a Proc.
    def to_proc
      method(:include?).to_proc
    end

    protected

    # @param lines_def [String] a comma or semicolon separated numbers and
    #   and ranges (e.g. `1..2`) specifying lines to be selected, or rejected
    #   if prefixed with "!".
    # @return [Array<Range>] an array of ranges sorted by the range begin in
    #   _descending_ order.
    def parse_attribute(lines_def)
      lines_def
        .split(/[,;]/)
        .map! { |line_def|
          from, to = line_def.split('..', 2).map(&:to_i)
          to ||= from
          to = ::Float::INFINITY if to == -1
          (from..to)
        }.sort! do |a, b|
          b.first <=> a.first
        end
    end
  end
end
