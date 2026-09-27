# frozen_string_literal: true
#
# GENERATED from monzo_api.yaml by bin/generate-specs. Do not edit.
#
# One example per operation the document describes. The example says WHICH
# operation; spec_helper.rb says what conforming means -- it reads this same
# document at runtime, so the schema in it is the assertion and nothing here
# restates it.

require 'spec_helper'

RSpec.describe 'AuthenticationApi' do
  describe 'POST /oauth2/logout' do
    it 'answers a documented status, with a body matching the schema' do
      Monzo.verify(example: self, method: 'POST', path: '/oauth2/logout',
                   operation_id: 'logout_post')
    end
  end

  describe 'POST /oauth2/token' do
    it 'answers a documented status, with a body matching the schema' do
      Monzo.verify(example: self, method: 'POST', path: '/oauth2/token',
                   operation_id: 'token_post')
    end
  end

  describe 'GET /ping/whoami' do
    it 'answers a documented status, with a body matching the schema' do
      Monzo.verify(example: self, method: 'GET', path: '/ping/whoami',
                   operation_id: 'whoami_get')
    end
  end

end
