# frozen_string_literal: true
#
# What "conforming" means. The generated files under spec/api say only WHICH
# operations exist; everything here reads the document at runtime, so the
# schema in monzo_api.yaml is the assertion and no expectation is ever written
# twice.
#
# Point it at Monzo with an access token -- the playground one is enough:
#
#   MONZO_TOKEN=...                              reads only
#   MONZO_TOKEN=... MONZO_MUTATE=1               reads, and writes it can undo
#   MONZO_TOKEN=... MONZO_MUTATE=1 MONZO_MONEY=1 all of it, pots included
#
# READ-ONLY by default, in two steps. Monzo answers 200 to a create just as it
# does to a read, so nothing in the document tells them apart:
#
#   * every method other than GET waits for MONZO_MUTATE=1, and each one this
#     suite makes it undoes -- the receipt it writes it deletes, the attachment
#     it registers it deregisters, the webhook it registers it deletes;
#   * the two pot operations move real money, so they wait for MONZO_MONEY=1 as
#     well. They move one penny, and the pair of them puts it back.
#
# Ids are not hand-written and not guessed: fixtures.yml asks for `$account_id`
# and the rest, and this file discovers them from the account the token belongs
# to. An operation whose discovery comes back empty skips, with the reason.

require 'json'
require 'net/http'
require 'securerandom'
require 'uri'
require 'yaml'

require 'json_schemer'

module Monzo
  ROOT = File.expand_path('..', __dir__)

  DOC = YAML.safe_load_file(File.join(ROOT, 'monzo_api.yaml'),
                            aliases: true, permitted_classes: [Date, Time]).freeze
  # A section of fixtures.yml that is entirely commented out parses as nil, so
  # neither that nor an empty one is a special case anywhere below.
  FIXTURES = (YAML.safe_load_file(File.join(__dir__, 'fixtures.yml')) || {}).freeze
  PARAMS   = (FIXTURES['params'] || {}).freeze
  PATHS    = (FIXTURES['paths'] || {}).freeze

  SCHEMA = JSONSchemer.schema(DOC)

  URL    = ENV.fetch('MONZO_URL', DOC.fetch('servers').first.fetch('url'))
  TOKEN  = ENV.fetch('MONZO_TOKEN', '')
  MUTATE = ENV['MONZO_MUTATE'] == '1'
  MONEY  = ENV['MONZO_MONEY'] == '1'

  BASE = URI.parse(URL)

  # One value per run. A retry within a run is the same deposit, which is the
  # whole point of dedupe_id; a new run is a new one.
  RUN = SecureRandom.hex(8)

  Response = Struct.new(:status, :body, :raw)
  MissingFixture = Class.new(StandardError)

  module_function

  # The one thing every generated example calls.
  def verify(example:, method:, path:, operation_id:)
    return example.skip('MONZO_TOKEN is not set; nothing to talk to') if TOKEN.empty?

    operation = DOC.dig('paths', path, method.downcase)
    return example.skip("#{method} #{path} is not in the document") unless operation

    fixture = PATHS[path] || {}

    if method != 'GET' && !MUTATE
      return example.skip("#{method} changes state; set MONZO_MUTATE=1 to include it")
    end

    if method != 'GET' && fixture['money'] && !MONEY
      return example.skip("#{method} #{path} moves money; set MONZO_MONEY=1 to include it")
    end

    begin
      response = call(method, path, fixture)
    rescue MissingFixture => e
      return example.skip(e.message)
    end

    check(method, path, operation, response)

    # A create this suite made is a create it takes back, and an undo that
    # failed is a failure of its own -- otherwise the suite quietly litters.
    undo(path, method, response)
  end

  def check(method, path, operation, response)
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

  # What each create leaves behind, and how it is taken back. The webhook and
  # the attachment have examples of their own that would delete them, but those
  # run whatever order RSpec chooses, so each create undoes itself here too --
  # deleting twice is harmless, leaving one behind is not.
  def undo(path, method, response)
    return unless MUTATE && response.status == '200'

    case [path, method]
    when ['/webhooks', 'POST']
      id = response.body&.dig('webhook', 'id') or return
      discard(:delete, "/webhooks/#{id}")
    when ['/attachment/register', 'POST']
      id = response.body&.dig('attachment', 'id') or return
      discard(:post, '/attachment/deregister', form: { 'id' => id })
    when ['/transaction-receipts', 'PUT']
      external = expand(PATHS.dig('/transaction-receipts', 'body', 'external_id')) or return
      discard(:delete, '/transaction-receipts', query: { 'external_id' => external })
    end
  end

  def discard(method, target, query: {}, form: nil)
    response = request(method.to_s.upcase, target, query: query, form: form)
    return if %w[200 404].include?(response.status)

    raise "cleaning up after the run: #{method.to_s.upcase} #{target} answered " \
          "#{response.status}. Body: #{response.raw[0, 200]}"
  end

  # Path parameters, query arguments and request bodies all come from
  # fixtures.yml, and every `$name` in it is discovered rather than guessed.
  def call(method, path, fixture)
    target = fill(path, fixture)
    query = expand(fixture['query'] || {})

    required = query_params(path, method).select { |p| p['required'] }.map { |p| p['name'] }
    missing = required - query.keys
    raise(MissingFixture, "no fixture for #{missing.join(', ')} in #{target}") if missing.any?

    form = expand(fixture['form']) if fixture.key?('form') && method != 'GET'
    body = expand(fixture['body']) if fixture.key?('body') && method != 'GET' && form.nil?

    request(method, target, query: query, form: form, body: body)
  end

  def fill(path, fixture)
    params = PARAMS.merge(fixture['params'] || {})

    path.gsub(/\{(\w+)\}/) do
      name = Regexp.last_match(1)
      value = expand(params[name])
      raise(MissingFixture, "no fixture for {#{name}} in #{path}") if value.nil?

      URI.encode_www_form_component(value.to_s)
    end
  end

  # `$account_id` and friends, anywhere in a fixture: a string, a key's value,
  # an element of a list.
  def expand(value)
    case value
    when Hash  then value.to_h { |k, v| [k, expand(v)] }
    when Array then value.map { |v| expand(v) }
    when String
      return value unless value.start_with?('$')

      name = value.delete_prefix('$')
      discovered(name) ||
        raise(MissingFixture, "nothing to use for $#{name}: #{WHY.fetch(name, 'not discovered')}")
    else value
    end
  end

  WHY = {
    'account_id' => 'the token can see no accounts',
    'pot_id' => 'the account has no pot that is not deleted',
    'transaction_id' => 'the account has no transactions',
    'webhook_id' => 'the account has no webhook, and registering one needs MONZO_MUTATE=1',
    'attachment_id' => 'no attachment was registered this run'
  }.freeze

  DISCOVERED = {}

  def discovered(name)
    return DISCOVERED[name] if DISCOVERED.key?(name)

    DISCOVERED[name] = respond_to?("discover_#{name}") ? send("discover_#{name}") : nil
  end

  def discover_account_id
    get('/accounts').dig('accounts', 0, 'id')
  end

  def discover_pot_id
    account = discovered('account_id') or return nil

    pots = get('/pots', 'current_account_id' => account)['pots'] || []
    pots.reject { |pot| pot['deleted'] }.dig(0, 'id')
  end

  # The most recent one: `since`/`before` are the document's own pagination, and
  # the last page is the cheapest place to find an id that still exists.
  def discover_transaction_id
    account = discovered('account_id') or return nil

    transactions = get('/transactions', 'account_id' => account, 'limit' => 100)['transactions']
    (transactions || []).last&.dig('id')
  end

  # An existing webhook if the client has one -- otherwise one of this run's
  # own, because DELETE /webhooks/{id} should delete something this suite made
  # and not something the user depends on.
  def discover_webhook_id
    account = discovered('account_id') or return nil

    existing = get('/webhooks', 'account_id' => account)['webhooks'] || []
    return existing.dig(0, 'id') unless existing.empty?
    return nil unless MUTATE

    request('POST', '/webhooks', form: expand(PATHS.dig('/webhooks', 'form')))
      .body&.dig('webhook', 'id')
  end

  # Registered here rather than in the example, so deregistering has something
  # of its own to remove whichever order RSpec runs them in.
  def discover_attachment_id
    return nil unless MUTATE

    form = expand(PATHS.dig('/attachment/register', 'form'))
    request('POST', '/attachment/register', form: form).body&.dig('attachment', 'id')
  end

  def discover_external_id
    "openapi-schema-monzo-#{RUN}"
  end

  def discover_dedupe_id
    "openapi-schema-monzo-#{RUN}"
  end

  def get(path, query = {})
    request('GET', path, query: query).body || {}
  end

  def request(method, target, query: {}, form: nil, body: nil)
    uri = URI.parse(BASE.to_s + target)
    uri.query = URI.encode_www_form(query) unless query.empty?

    http = Net::HTTP.const_get(method.capitalize).new(uri)
    http['Authorization'] = "Bearer #{TOKEN}"
    http['Accept'] = 'application/json'

    if form
      http.set_form_data(form)
    elsif body
      http['Content-Type'] = 'application/json'
      http.body = JSON.dump(body)
    end

    raw = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') { |session|
      session.request(http)
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
