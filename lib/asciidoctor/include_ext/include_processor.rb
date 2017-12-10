# frozen_string_literal: true
require 'logger'
require 'open-uri'

require 'asciidoctor/include_ext/version'
require 'asciidoctor/include_ext/reader_ext'
require 'asciidoctor/extensions'

module Asciidoctor::IncludeExt
  # Asciidoctor preprocessor for processing `include::<target>[]` directives
  # in the source document.
  #
  # @see http://asciidoctor.org/docs/user-manual/#include-directive
  class IncludeProcessor < ::Asciidoctor::Extensions::IncludeProcessor

    # @param logger [Logger] the logger to use for logging warning and errors
    #   from this object.
    def initialize(logger: Logger.new(STDERR), **)
      super
      @logger = logger
    end

    # @param reader [Asciidoctor::Reader]
    # @param target [String] name of the source file to include as specified
    #   in the target slot of the `include::[]` directive.
    # @param attributes [Hash<String, String>] parsed attributes of the
    #   `include::[]` directive.
    def process(_, reader, target, attributes)
      unless include_allowed? target, reader
        reader.replace_next_line("link:#{target}[]")
        return
      end

      if (max_depth = reader.exceeded_max_depth?)
        logger.error "#{reader.line_info}: maximum include depth of #{max_depth} exceeded"
        return
      end

      unless (path = resolve_target_path(target, reader))
        if attributes.key? 'optional-option'
          reader.shift
        else
          logger.error "#{reader.line_info}: include target not found: #{target}"
          unresolved_include!(target, reader)
        end
        return
      end

      begin
        lines = read_lines(path)
      rescue => e  # rubocop:disable RescueWithoutErrorClass
        logger.error "#{reader.line_info}: failed to read include file: #{path}: #{e}"
        unresolved_include!(target, reader)
        return
      end

      unless lines.empty?
        reader.push_include(lines, path, target, 1, attributes)
      end
    end

    protected

    attr_reader :logger

    # @param target (see #process)
    # @param reader (see #process)
    # @return [Boolean] `true` if it's allowed to include the *target*,
    #   `false` otherwise.
    def include_allowed?(target, reader)
      doc = reader.document

      return false if doc.safe >= ::Asciidoctor::SafeMode::SECURE
      return false if doc.attributes.fetch('max-include-depth', 64).to_i < 1
      return false if target_uri?(target) && !doc.attributes.key?('allow-uri-read')
      true
    end

    # @param target (see #process)
    # @param reader (see #process)
    # @return [String, nil] file path or URI of the *target*, or `nil` if not found.
    def resolve_target_path(target, reader)
      return target if target_uri? target

      # Include file is resolved relative to dir of the current include,
      # or base_dir if within original docfile.
      path = reader.document.normalize_system_path(target, reader.dir, nil,
                                                   target_name: 'include file')
      path if ::File.file?(path)
    end

    # Reads the specified file as individual lines and returns those lines
    # in an array.
    #
    # @param filename [String] path of the file to be read.
    # @return [Array<String>] an array of read lines.
    def read_lines(filename)
      open(filename, &:read)
    end

    # Replaces the include directive in ouput with a notice that it has not
    # been resolved.
    #
    # @param target (see #process)
    # @param reader (see #process)
    def unresolved_include!(target, reader)
      reader.replace_next_line("Unresolved directive in #{reader.path} - include::#{target}[]")
    end

    private

    # @param target (see #process)
    # @return [Boolean] `true` if the *target* is an URI, `false` otherwise.
    def target_uri?(target)
      ::Asciidoctor::Helpers.uriish?(target)
    end
  end
end
