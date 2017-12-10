# frozen_string_literal: true
require 'asciidoctor/extensions'
require 'asciidoctor/include_ext/include_processor'

Asciidoctor::Extensions.register do
  include_processor Asciidoctor::IncludeExt::IncludeProcessor
end
