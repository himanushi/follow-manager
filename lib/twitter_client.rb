# frozen_string_literal: true

class TwitterClient
  attr_accessor :me_id, :_not_followers
  attr_reader :connection

  def initialize
    @connection = Faraday.new('https://api.twitter.com/2') do |builder|
      builder.request :url_encoded
      builder.adapter Faraday.default_adapter
      builder.response :json, content_type: 'application/json'
      builder.headers = { 'Authorization' => "Bearer #{ENV['TWITTER_API_BEARER_TOKEN']}" }
      builder
    end
  end

  def followers(id)
    query_params = {
      'max_results' => 1000
    }
    connection.get("users/#{id}/followers", query_params)
  end

  def following(id)
    query_params = {
      'max_results' => 1000
    }
    connection.get("users/#{id}/following", query_params)
  end

  def not_followers(id)
    @_not_followers ||= ((following(id).body['data'] || []) - (followers(id).body['data'] || []))
  end

  def not_follow_me?(id)
    raise Error if me_id.nil?

    follower_users = (followers(id).body['data'] || [])
    index = follower_users.find_index { |user| user['id'] == me_id }
    if index
      after_follower_ids = follower_users[..index].map { |user| user['id'] }
      following_ids = (following(id).body['data'] || []).map { |user| user['id'] }
      return !(after_follower_ids & following_ids).size.zero?
    end
    false
  end

  def not_follow_me_all
    raise Error if me_id.nil?

    not_follow_users = not_followers(me_id)[..5]
    not_follow_users.select do |user|
      not_follow_me?(user['id'])
    end
  end
end
