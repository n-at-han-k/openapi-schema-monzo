# frozen_string_literal: true
#
# GENERATED from monzo_api.yaml by bin/generate-specs. Do not edit.
#
# One example per operation the document describes. The example says WHICH
# operation; spec_helper.rb says what conforming means -- it reads this same
# document at runtime, so the schema in it is the assertion and nothing here
# restates it.

require 'spec_helper'

RSpec.describe 'PotsApi' do
  describe 'PUT /pots/{pot_id}/deposit' do
    it 'answers a documented status, with a body matching the schema' do
      Monzo.verify(example: self, method: 'PUT', path: '/pots/{pot_id}/deposit',
                   operation_id: 'pot_deposit_put')
    end
  end

  describe 'PUT /pots/{pot_id}/withdraw' do
    it 'answers a documented status, with a body matching the schema' do
      Monzo.verify(example: self, method: 'PUT', path: '/pots/{pot_id}/withdraw',
                   operation_id: 'pot_withdraw_put')
    end
  end

  describe 'GET /pots' do
    it 'answers a documented status, with a body matching the schema' do
      Monzo.verify(example: self, method: 'GET', path: '/pots',
                   operation_id: 'pots_get')
    end
  end

end
