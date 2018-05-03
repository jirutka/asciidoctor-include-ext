# frozen_string_literal: true
require 'asciidoctor'

# Monkey-patch Reader to add #document.
class Asciidoctor::Reader
  attr_reader :document
end
