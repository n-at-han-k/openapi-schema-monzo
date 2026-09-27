# frozen_string_literal: true
#
# GENERATED from monzo_api.yaml by bin/generate-specs. Do not edit.
#
# One example per operation the document describes. The example says WHICH
# operation; spec_helper.rb says what conforming means -- it reads this same
# document at runtime, so the schema in it is the assertion and nothing here
# restates it.

require 'spec_helper'

RSpec.describe 'AttachmentsApi' do
  describe 'POST /attachment/deregister' do
    it 'answers a documented status, with a body matching the schema' do
      Monzo.verify(example: self, method: 'POST', path: '/attachment/deregister',
                   operation_id: 'attachment_deregister_post')
    end
  end

  describe 'POST /attachment/register' do
    it 'answers a documented status, with a body matching the schema' do
      Monzo.verify(example: self, method: 'POST', path: '/attachment/register',
                   operation_id: 'attachment_register_post')
    end
  end

  describe 'POST /attachment/upload' do
    it 'answers a documented status, with a body matching the schema' do
      Monzo.verify(example: self, method: 'POST', path: '/attachment/upload',
                   operation_id: 'attachment_upload_post')
    end
  end

end
