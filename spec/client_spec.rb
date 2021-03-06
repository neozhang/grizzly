# encoding: UTF-8

require 'spec_helper'

describe Grizzly::Client do

  let(:access_token) { "2.004aXKtCl9RjUB964bba3949NaaEgC" }
  let(:invalid_access_token) { "icecream" }
  let(:user_id) { 2647476531 }
  let(:random_seed) { "3123213213123" } 
  let(:status_update) { "Hello #{random_seed}" }

  it "should expect to be passed an access token" do
    -> { Grizzly::Client.new }.should raise_error(Grizzly::Errors::NoAccessToken)
  end
  
  it "should raise weibo API error when an API error is returned" do
    -> {
      VCR.use_cassette('error') do
        client = Grizzly::Client.new(invalid_access_token)
        client.friends(user_id).first
      end
    }.should raise_error(Grizzly::Errors::WeiboAPI)
  end

  it "should fetch a list of friends for a given user" do
    VCR.use_cassette('friends') do
      client = Grizzly::Client.new(access_token)
      friends = client.friends(user_id)
    end
  end

  it "should make the user data accessable via methods" do
    VCR.use_cassette('friends') do
      client = Grizzly::Client.new(access_token)
      friends = client.friends(user_id)
      friends.first.id
      -> { friends.first.icecream }.should raise_error
    end
  end

  it "should be able to fetch bilateral friends" do
    VCR.use_cassette('bilateral_friends') do
      client = Grizzly::Client.new(access_token)
      friends = client.bilateral_friends(user_id)
      friends.count.should eql 1
      friends[0].id.should eql 1941795265
      friends.first.id.should eql 1941795265
    end
  end

  it "should get a hash version of the returned user data" do
    VCR.use_cassette('bilateral_friends') do
      client = Grizzly::Client.new(access_token)
      friends = client.bilateral_friends(user_id)
      friends.first.to_h.class.should eql Hash
      friends.first.to_h["id"].should eql 1941795265
    end
  end

  it "should update the current users status" do
    VCR.use_cassette('status_update') do
      client = Grizzly::Client.new(access_token)
      status = client.status_update(status_update)
      status.text.should eql status_update
      status.user.id.should eql user_id
    end
  end

  it "should be able to get the entire collection of bilateral friends" do
    bilateral_friends_collection = []
    total_items = 0

    VCR.use_cassette('bilateral_friends', :record => :new_episodes) do
      client = Grizzly::Client.new(access_token)
      bilateral_friends = client.bilateral_friends(user_id)
      while bilateral_friends.next_page?
        bilateral_friends.each do |friend|
          bilateral_friends_collection << friend 
        end
      end
      bilateral_friends_collection.count.should eql 1
    end
  end

end
