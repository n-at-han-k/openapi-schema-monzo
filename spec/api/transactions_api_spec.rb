# frozen_string_literal: true
#
# GENERATED from monzo_api.yaml by bin/generate-specs. Do not edit.
#
# One example per operation the document describes. The example says WHICH
# operation; spec_helper.rb says what conforming means -- it reads this same
# document at runtime, so the schema in it is the assertion and nothing here
# restates it.

require 'spec_helper'

RSpec.describe 'TransactionsApi' do
  describe 'GET /transactions/{transaction_id}' do
    it 'answers a documented status, with a body matching the schema' do
      Monzo.verify(example: self, method: 'GET', path: '/transactions/{transaction_id}',
                   operation_id: 'transaction_get')
    end
  end

  describe 'PATCH /transactions/{transaction_id}' do
    it 'answers a documented status, with a body matching the schema' do
      Monzo.verify(example: self, method: 'PATCH', path: '/transactions/{transaction_id}',
                   operation_id: 'transaction_patch')
    end
  end

  describe 'GET /transactions' do
    it 'answers a documented status, with a body matching the schema' do
      Monzo.verify(example: self, method: 'GET', path: '/transactions',
                   operation_id: 'transactions_get')
    end
  end

end
