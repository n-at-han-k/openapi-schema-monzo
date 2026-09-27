# frozen_string_literal: true
#
# GENERATED from monzo_api.yaml by bin/generate-specs. Do not edit.
#
# One example per operation the document describes. The example says WHICH
# operation; spec_helper.rb says what conforming means -- it reads this same
# document at runtime, so the schema in it is the assertion and nothing here
# restates it.

require 'spec_helper'

RSpec.describe 'FeedItemsApi' do
  describe 'POST /feed' do
    it 'answers a documented status, with a body matching the schema' do
      Monzo.verify(example: self, method: 'POST', path: '/feed',
                   operation_id: 'feed_item_post')
    end
  end

end
