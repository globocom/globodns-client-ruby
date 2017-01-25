require 'test_helper'

class GlobodnsClientTest < Test::Unit::TestCase
  def test_that_it_has_a_version_number
    refute_nil ::GlobodnsClient::VERSION
  end

  def test_initialize_without_settings
    assert_raise(ArgumentError) do
      klass.new(settings.delete_if { |k,v| k == :bearer_token || k == :host })
    end
  end

  # Test that correct initialization works
  def test_initialize_with_settings
    assert_nothing_raised do
      klass.new(settings)
    end
  end

  def test_get_zone
    assert_nothing_raised do
      res = mock()
      res1 = mock()
      res2 = mock()
      RestClient::Request.expects(:execute).with(
        method:'get',
        url:"#{settings[:host]}/domains.json",
        timeout: settings[:timeout],
        headers: {
          'Authorization' => "Bearer #{settings[:bearer_token]}",
          'Content-type' => 'application/json',
          :params => {query: settings[:fqdn]},
        },
        payload: nil
      ).returns(res).once
      res.expects(:code).with().returns(200).twice
      res.expects(:body).with().returns('[]').once
      RestClient::Request.expects(:execute).with(
        method:'get',
        url:"#{settings[:host]}/domains.json",
        timeout: settings[:timeout],
        headers: {
          'Authorization' => "Bearer #{settings[:bearer_token]}",
          'Content-type' => 'application/json',
          :params => {query: settings[:fqdn].split('.',2).last},
        },
        payload: nil
      ).returns(res1).once
      res1.expects(:code).with().returns(200).twice
      res1.expects(:body).with().returns('[]').once
      RestClient::Request.expects(:execute).with(
        method:'get',
        url:"#{settings[:host]}/domains.json",
        timeout: settings[:timeout],
        headers: {
          'Authorization' => "Bearer #{settings[:bearer_token]}",
          'Content-type' => 'application/json',
          :params => {query: settings[:zone]},
        },
        payload: nil
      ).returns(res2).once
      res2.expects(:code).with().returns(200).twice
      res2.expects(:body).returns(domain_json).once

      conn = klass.new(settings)
      zone = conn.get_zone(settings[:fqdn],settings[:type])
      assert_equal zone, zone_response
    end
  end

  private

  def klass
    GlobodnsClient::Connection
  end

  def settings
    {
      :bearer_token => 'foo',
      :host => 'globodns.com',
      :fqdn => 'a.test.example.com',
      :zone => 'example.com',
      :ip => '10.1.1.1',
      :type => 'A',
      :timeout => 5
    }
  end

  def domain_json
    '[{"domain":{"id":"123","name":"example.com"}}]'
  end

  def zone_response
    [{"domain"=>{"id"=>"123", "name"=>"example.com"}}]
  end
end
