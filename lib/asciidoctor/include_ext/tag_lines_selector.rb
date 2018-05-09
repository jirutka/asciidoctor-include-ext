# frozen_string_literal: true
require 'logger'
require 'set'

require 'asciidoctor'
require 'asciidoctor/include_ext/version'
require 'asciidoctor/include_ext/logging'

module Asciidoctor::IncludeExt
  # Lines selector that selects lines of the content based on the specified tags.
  #
  # @note Instance of this class can be used only once, as a predicate to
  #   filter a single include directive.
  #
  # @example
  #   include::some-file.adoc[tags=snippets;!snippet-b]
  #   include::some-file.adoc[tag=snippets]
  #
  # @example
  #   selector = TagLinesSelector.new("some-file.adoc", {"tag" => "snippets"})
  #   IO.foreach(filename).select.with_index(1, &selector)
  #
  # @see http://asciidoctor.org/docs/user-manual#by-tagged-regions
  class TagLinesSelector

    # @return [Integer, nil] 1-based line number of the first included line,
    #   or `nil` if none.
    attr_reader :first_included_lineno

    # @param attributes [Hash<String, String>] the attributes parsed from the
    #   `include::[]`s attributes slot.
    # @return [Boolean] `true` if the *attributes* hash contains a key `"tag"`
    #   or `"tags"`.
    def self.handles?(_, attributes)
      attributes.key?('tag') || attributes.key?('tags')
    end

    # @param target [String] name of the source file to include as specified
    #   in the target slot of the `include::[]` directive.
    # @param attributes [Hash<String, String>] the attributes parsed from the
    #   `include::[]`s attributes slot. It must contain a key `"tag"` or `"tags"`.
    # @param logger [Logger]
    def initialize(target, attributes, logger: Logging.default_logger, **)
      tag_flags =
        if attributes.key? 'tag'
          parse_attribute(attributes['tag'], true)
        else
          parse_attribute(attributes['tags'])
        end

      wildcard = tag_flags.delete('*')
      if tag_flags.key? '**'
        default_state = tag_flags.delete('**')
        wildcard = default_state if wildcard.nil?
      else
        default_state = !tag_flags.value?(true)
      end

      # "immutable"
      @target = target
      @logger = logger
      @tag_flags = tag_flags.freeze
      @wildcard = wildcard
      @tag_directive_rx = /\b(?:tag|(end))::(\S+)\[\](?=$| )/.freeze

      # mutable (state variables)
      @stack = [[nil, default_state]]
      @state = default_state
      @used_tags = ::Set.new
    end

    # Returns `true` if the given line should be included, `false` otherwise.
    #
    # @note This method modifies state of this object. It's supposed to be
    #   called successively with each line of the content being included.
    #   See {TagLinesSelector example}.
    #
    # @param line [String]
    # @param line_num [Integer] 1-based *line* number.
    # @return [Boolean] `true` to select the *line*, `false` to reject.
    def include?(line, line_num)
      tag_type, tag_name = parse_tag_directive(line)

      case tag_type
      when :start
        enter_region!(tag_name, line_num)
        false
      when :end
        exit_region!(tag_name, line_num)
        false
      when nil
        if @state && @first_included_lineno.nil?
          @first_included_lineno = line_num
        end
        @state
      end
    end

    # @return [Proc] {#include?} method as a Proc.
    def to_proc
      method(:include?).to_proc
    end

    protected

    attr_reader :logger, :target

    # @return [String, nil] a name of the active tag (region), or `nil` if none.
    def active_tag
      @stack.last.first
    end

    # @param tag_name [String]
    # @param _line_num [Integer]
    def enter_region!(tag_name, _line_num)
      if @tag_flags.key? tag_name
        @used_tags << tag_name
        @state = @tag_flags[tag_name]
        @stack << [tag_name, @state]
      elsif !@wildcard.nil?
        @state = active_tag && !@state ? false : @wildcard
        @stack << [tag_name, @state]
      end
    end

    # @param tag_name [String]
    # @param line_num [Integer]
    def exit_region!(tag_name, line_num)
      # valid end tag
      if tag_name == active_tag
        @stack.pop
        @state = @stack.last[1]

      # mismatched/unexpected end tag
      elsif @tag_flags.key? tag_name
        log_prefix = "#{target}: line #{line_num}"

        if (idx = @stack.rindex { |key, _| key == tag_name })
          @stack.delete_at(idx)
          logger.warn "#{log_prefix}: mismatched end tag include: expected #{active_tag}, found #{tag_name}"  # rubocop:disable LineLength
        else
          logger.warn "#{log_prefix}: unexpected end tag in include: #{tag_name}"
        end
      end
    end

    # Parses `tag::<name>[]` and `end::<name>[]` in the given *line*.
    #
    # @param line [String]
    # @return [Array, nil] a tuple `[Symbol, String]` where the first item is
    #   `:start` or `:end` and the second is a tag name. If no tag is matched,
    #   then `nil` is returned.
    def parse_tag_directive(line)
      @tag_directive_rx.match(line) do |m|
        [m[1].nil? ? :start : :end, m[2]]
      end
    end

    # @param tags_def [String] a comma or semicolon separated names of tags to
    #   be selected, or rejected if prefixed with "!".
    # @param single [Boolean] whether the *tags_def* should be parsed as
    #   a single tag name (i.e. without splitting on comma/semicolon).
    # @return [Hash<String, Boolean>] a Hash with tag names as keys and boolean
    #   flags as values.
    def parse_attribute(tags_def, single = false)
      atoms = single ? [tags_def] : tags_def.split(/[,;]/)

      atoms.each_with_object({}) do |atom, tags|
        if atom.start_with? '!'
          tags[atom[1..-1]] = false if atom != '!'
        elsif !atom.empty?
          tags[atom] = true
        end
      end
    end
  end
end
