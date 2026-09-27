# frozen_string_literal: true
#
# GENERATED from monzo_api.yaml by bin/generate-specs. Do not edit.
#
# One example per operation the document describes. The example says WHICH
# operation; spec_helper.rb says what conforming means -- it reads this same
# document at runtime, so the schema in it is the assertion and nothing here
# restates it.

require 'spec_helper'

RSpec.describe 'ReceiptsApi' do
  describe 'DELETE /transaction-receipts' do
    it 'answers a documented status, with a body matching the schema' do
      Monzo.verify(example: self, method: 'DELETE', path: '/transaction-receipts',
                   operation_id: 'receipt_delete')
    end
  end

  describe 'GET /transaction-receipts' do
    it 'answers a documented status, with a body matching the schema' do
      Monzo.verify(example: self, method: 'GET', path: '/transaction-receipts',
                   operation_id: 'receipt_get')
    end
  end

  describe 'PUT /transaction-receipts' do
    it 'answers a documented status, with a body matching the schema' do
      Monzo.verify(example: self, method: 'PUT', path: '/transaction-receipts',
                   operation_id: 'receipt_put')
    end
  end

end
