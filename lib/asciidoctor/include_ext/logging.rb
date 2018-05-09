# frozen_string_literal: true
require 'logger'
require 'asciidoctor'
require 'asciidoctor/include_ext/version'

module Asciidoctor::IncludeExt
  # Helper module for getting default Logger based on the Asciidoctor version.
  module Logging
    module_function

    # @return [Logger] the default `Asciidoctor::Logger` if using Asciidoctor
    #   1.5.7 or later, or Ruby's `Logger` that outputs to `STDERR`.
    def default_logger
      if defined? ::Asciidoctor::LoggerManager
        ::Asciidoctor::LoggerManager.logger
      else
        ::Logger.new(STDERR)
      end
    end
  end
end
