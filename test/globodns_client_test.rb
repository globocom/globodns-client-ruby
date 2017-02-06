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

  def test_delete_a_record
    # assert_nothing_raised do
      get_zone_assertions
      get_record_assertions
      delete_record_assertion
      conn = klass.new(settings)
      #byebug
      del = conn.delete_record('a.test.example.com','A')
    # end
  end

  def test_get_zone
    assert_nothing_raised do
      get_zone_assertions
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
    [{:domain=>{:id=>"123", :name=>"example.com"}}]
  end

  def delete_record_assertion
    dr_res = mock()
    RestClient::Request.expects(:execute).with(method:'delete',url:'globodns.com/records/3165205.json',
      timeout:5, headers:
        {'Authorization' => "Bearer #{settings[:bearer_token]}",
         'Content-type' => 'application/json'
        }, :payload => nil ).returns(dr_res).once
    dr_res.expects(:code).with().returns(200).twice
  end

  def get_record_assertions
    d_res = mock()
    RestClient::Request.expects(:execute).with(method:'get',url:'globodns.com/domains/123/records.json',
      timeout:5, headers:
        {'Authorization' => "Bearer #{settings[:bearer_token]}",
         'Content-type' => 'application/json',
          :params => {:query => 'a.test'}
        }, :payload => nil ).returns(d_res).once
    d_res.expects(:code).with().returns(200).twice
    d_res.expects(:body).with().returns(record_request).once
  end

  def record_request
    [{"a"=>
      { "id"=>3165205,
        "domain_id"=>96114,
        "name"=>"a.test",
        "content"=>"10.1.1.1",
        "ttl"=>nil,
        "prio"=>nil,
        "created_at"=>"2015-06-10T05:34:01.000-03:00",
        "updated_at"=>"2015-06-10T05:34:01.000-03:00"
    }}].to_json
  end

  def get_zone_assertions
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
  end
end
