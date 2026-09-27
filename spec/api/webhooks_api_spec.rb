# frozen_string_literal: true
#
# GENERATED from monzo_api.yaml by bin/generate-specs. Do not edit.
#
# One example per operation the document describes. The example says WHICH
# operation; spec_helper.rb says what conforming means -- it reads this same
# document at runtime, so the schema in it is the assertion and nothing here
# restates it.

require 'spec_helper'

RSpec.describe 'WebhooksApi' do
  describe 'DELETE /webhooks/{webhook_id}' do
    it 'answers a documented status, with a body matching the schema' do
      Monzo.verify(example: self, method: 'DELETE', path: '/webhooks/{webhook_id}',
                   operation_id: 'webhook_delete')
    end
  end

  describe 'POST /webhooks' do
    it 'answers a documented status, with a body matching the schema' do
      Monzo.verify(example: self, method: 'POST', path: '/webhooks',
                   operation_id: 'webhook_post')
    end
  end

  describe 'GET /webhooks' do
    it 'answers a documented status, with a body matching the schema' do
      Monzo.verify(example: self, method: 'GET', path: '/webhooks',
                   operation_id: 'webhooks_get')
    end
  end

end
