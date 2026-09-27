# frozen_string_literal: true
#
# What "conforming" means. The generated files under spec/api say only WHICH
# operations exist; everything here reads the document at runtime, so the
# schema in monzo_api.yaml is the assertion and no expectation is ever written
# twice.
#
# Point it at Monzo with an access token -- the playground one is enough:
#
#   MONZO_TOKEN=... bundle exec rspec
#
# READ-ONLY by default. Every method other than GET is skipped unless
# MONZO_MUTATE=1: Monzo answers 200 to a create just as it does to a read, so
# nothing in the document distinguishes them, and the obvious way to test
# "deposit into a pot" is to move someone's money on every run.

require 'json'
require 'net/http'
require 'uri'
require 'yaml'

require 'json_schemer'

module Monzo
  ROOT = File.expand_path('..', __dir__)

  DOC = YAML.safe_load_file(File.join(ROOT, 'monzo_api.yaml'),
                            aliases: true, permitted_classes: [Date, Time]).freeze
  # A section of fixtures.yml that is entirely commented out parses as nil, and
  # an empty one is the normal state of this file, so neither is a special case
  # anywhere below.
  FIXTURES = (YAML.safe_load_file(File.join(__dir__, 'fixtures.yml')) || {}).freeze
  PARAMS   = (FIXTURES['params'] || {}).freeze
  PATHS    = (FIXTURES['paths'] || {}).freeze

  SCHEMA = JSONSchemer.schema(DOC)

  URL    = ENV.fetch('MONZO_URL', DOC.fetch('servers').first.fetch('url'))
  TOKEN  = ENV.fetch('MONZO_TOKEN', '')
  MUTATE = ENV['MONZO_MUTATE'] == '1'

  BASE = URI.parse(URL)

  Response = Struct.new(:status, :body, :raw)

  module_function

  # The one thing every generated example calls.
  def verify(example:, method:, path:, operation_id:)
    return example.skip('MONZO_TOKEN is not set; nothing to talk to') if TOKEN.empty?

    operation = DOC.dig('paths', path, method.downcase)
    return example.skip("#{method} #{path} is not in the document") unless operation

    if method != 'GET' && !MUTATE
      return example.skip("#{method} changes state; set MONZO_MUTATE=1 to include it")
    end

    fixture = PATHS[path] || {}

    begin
      response = call(method, path, fill(path, fixture), fixture)
    rescue MissingFixture => e
      return example.skip(e.message)
    end

    declared = operation.fetch('responses').keys.map(&:to_s)
    unless declared.include?(response.status) || declared.include?('default')
      raise "#{method} #{path} answered #{response.status}, which the document does not " \
            "describe (it describes #{declared.join(', ')}). Body: #{response.raw[0, 300]}"
    end

    schema = operation.dig('responses', response.status, 'content', 'application/json', 'schema')
    # A response the document describes by $ref to a shared one -- every error,
    # and every empty body -- is checked for its status and nothing more.
    return if schema.nil? || response.body.nil?

    pointer = "#/paths/#{escape(path)}/#{method.downcase}/responses/#{response.status}" \
              '/content/application~1json/schema'
    errors = SCHEMA.ref(pointer).validate(response.body).to_a

    return if errors.empty?

    raise "#{method} #{path} answered #{response.status} with a body the document does not " \
          "describe:\n" + errors.first(8).map { |e| report(e) }.join("\n")
  end

  MissingFixture = Class.new(StandardError)

  # Path parameters come from spec/fixtures.yml: this suite talks to a real
  # account, and only the person running it knows which pot is safe to touch.
  def fill(path, fixture)
    params = PARAMS.merge(fixture['params'] || {})

    path.gsub(/\{(\w+)\}/) do
      name = Regexp.last_match(1)
      value = params[name]
      raise(MissingFixture, "no fixture for {#{name}} in #{path}") if value.nil?

      URI.encode_www_form_component(value.to_s)
    end
  end

  # Most of Monzo's reads take a required query argument -- an account id, an
  # external id -- so a fixture that omits one is a skip rather than a 400 that
  # passes because 400 is documented.
  def call(method, path, target, fixture)
    required = query_params(path, method).select { |p| p['required'] }.map { |p| p['name'] }
    query = fixture['query'] || {}
    missing = required - query.keys
    raise(MissingFixture, "no fixture for #{missing.join(', ')} in #{target}") if missing.any?

    uri = URI.parse(BASE.to_s + target)
    uri.query = URI.encode_www_form(query) unless query.empty?

    request = Net::HTTP.const_get(method.capitalize).new(uri)
    request['Authorization'] = "Bearer #{TOKEN}"
    request['Accept'] = 'application/json'

    if fixture.key?('form')
      request.set_form_data(fixture.fetch('form'))
    elsif fixture.key?('body')
      request['Content-Type'] = 'application/json'
      request.body = JSON.dump(fixture['body'])
    end

    raw = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') { |http|
      http.request(request)
    }

    Response.new(raw.code, parse(raw.body), raw.body.to_s)
  end

  # A parameter may sit on the operation or on the path item, and either may be
  # a $ref into components.
  def query_params(path, method)
    item = DOC.dig('paths', path) || {}
    shared = item.fetch('parameters', [])
    operation = item.dig(method.downcase, 'parameters') || []

    (shared + operation)
      .map { |p| p.key?('$ref') ? resolve(p.fetch('$ref')) : p }
      .select { |p| p['in'] == 'query' }
  end

  def resolve(ref)
    DOC.dig(*ref.delete_prefix('#/').split('/'))
  end

  def parse(body)
    return nil if body.nil? || body.strip.empty?

    JSON.parse(body)
  rescue JSON::ParserError
    nil
  end

  def report(error)
    "  #{error['data_pointer'].empty? ? '(root)' : error['data_pointer']}: " \
      "#{error['type']} -- got #{error['data'].inspect[0, 60]}"
  end

  # A JSON pointer inside a URI fragment: `/` is ~1, and these paths carry
  # braces, which URI.join will not have.
  def escape(path)
    path.gsub('~', '~0').gsub('/', '~1').gsub('{', '%7B').gsub('}', '%7D')
  end
end

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.formatter = :documentation if ENV['MONZO_TOKEN']
end
