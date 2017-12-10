# frozen_string_literal: true
require 'asciidoctor/reader'

# Monkey-patch Reader to add #document.
class Asciidoctor::Reader
  attr_reader :document
end
