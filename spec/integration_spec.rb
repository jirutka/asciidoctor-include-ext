require_relative 'spec_helper'
require 'corefines'
require 'webrick'

FIXTURES_DIR = File.expand_path('../fixtures', __FILE__)

using Corefines::String::unindent

describe 'Integration tests' do

  subject(:output) { ::Asciidoctor.convert(@input, @options) }

  before do
    @input = nil
    @options = { safe: :safe, header_footer: false, base_dir: FIXTURES_DIR }
  end

  describe 'include::[] directive' do

    it 'is replaced by a link when safe mode is default' do
      given 'include::include-file.adoc[]', safe: nil

      should match /<a[^>]+href="include-file.adoc"/
      should_not match /included content/
    end

    it 'is resolved when safe mode is less than SECURE' do
      given 'include::include-file.adoc[]'

      should match /included content/
      should_not match /<a[^>]+href="include-file\.adoc"/
    end

    it 'nested includes are resolved with relative paths' do
      given 'include::a/include-1.adoc[]'

      expect( output.scan(/[^>]*include \w+/) ).to eq [
        'begin of include 1', 'include 2a', 'begin of include 2b', 'include 3',
        'end of include 2b', 'end of include 1'
      ]
    end

    it 'is replaced by a warning when target is not found' do
      given <<-ADOC.unindent
        include::no-such-file.adoc[]

        trailing content
      ADOC

      should match /unresolved/i
      should match /trailing content/
    end

    it 'is skipped when target is not found and optional option is set' do
      given <<-ADOC.unindent
        include::no-such-file.adoc[opts=optional]

        trailing content
      ADOC

      should match /trailing content/
      should_not match /unresolved/i
    end

    it 'is replaced by a link when target is an URI and attribute allow-uri-read is not set' do
      using_test_webserver do |host, port|
        target = "http://#{host}:#{port}/hello.json"
        given "include::#{target}[]"

        should match /<a[^>]*href="#{target}"/
        should_not match /\{"message": "Hello, world!"\}/
      end
    end

    it 'retrieves content from URI target when allow-uri-read is set' do
      using_test_webserver do |host, port|
        given "include::http://#{host}:#{port}/hello.json[]",
              attributes: { 'allow-uri-read' => '' }

        should match /\{"message": "Hello, world!"\}/
        should_not match /unresolved/i
      end
    end
  end


  #----------  Helpers  ----------

  def given(input, options = {})
    @input = input
    @options.merge!(options)
  end

  def using_test_webserver
    started = false
    server = WEBrick::HTTPServer.new(
      BindAddress: '127.0.0.1',
      Port: 0,
      StartCallback: -> { started = true },
      AccessLog: [],
    )

    server.mount_proc '/hello.json' do |_, res|
      res.body = '{"message": "Hello, world!"}'
    end

    Thread.new { server.start }
    Timeout.timeout(1) { :wait until started }

    begin
      yield server.config[:BindAddress], server.config[:Port]
    ensure
      server.shutdown
    end
  end
end