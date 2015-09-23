require 'rest-client'
require 'json'

module GlobodnsClient
  class Connection
    def initialize(options)
      @auth_token = options[:auth_token]
      @host = options[:host]
      @timeout = options[:timeout] || 30
      raise "You must inform the auth_token and host for GloboDNS" unless @auth_token && @host
    end

    def get_zone(fqdn, kind = 'A')
      if kind.eql?('A')
        domain = fqdn.split('.', 2).last
      elsif kind.eql?('PTR')
        if fqdn.include?('in-addr.arpa')
          domain = fqdn.split('.', 2).last
        else
          match = fqdn.match(/(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})/)
          domain = (match[1..3]+["0"]).reverse.join('.')+'.in-addr.arpa'
        end
      else
        raise "Not implemented"
      end
      res = request('get','domain', domain, nil, kind)
      if res.empty?
        if domain.count('.') > 1 && kind == 'A' || domain.count('.') > 2 && kind == 'PTR'
          res = get_zone(domain, kind)
        else
          raise "Couldn't find a proper zone for '#{@fqdn}'"
        end
      end
      res.is_a?(Array) ? res[0]['domain'] : res
    end

    def get_record(fqdn, kind, zone = nil)
      zone = get_zone(fqdn, kind) if zone.nil?
      host = get_host(fqdn, zone, kind)
      response = request('get', 'record', host, zone['id'], kind)
      response.each do |r|
        return r[kind.downcase] unless r[kind.downcase].nil?
      end
      false
    end

    def new_record(fqdn, kind, value)
      zone = get_zone(fqdn, kind)
      if record = get_record(fqdn, kind, zone)
        raise "Address already (#{fqdn}) exists with ip (#{record['content']})"
      else
        host = get_host(fqdn, zone, kind)
        response = request('post', 'record', host, zone['id'], kind, value)
      end
      response['record']
    end

    def delete_record(fqdn, kind)
      zone = get_zone(fqdn, kind)
      unless record = get_record(fqdn, kind, zone)
        raise "Record not found for (#{fqdn})"
      end
      response = request('delete', 'record', nil, record['id'])
    end

    private

    def get_host(fqdn, zone, kind)
      if kind.eql?('A')
        host = fqdn.split('.'+zone['name'])[0]
      elsif kind.eql?('PTR')
        case zone['name'].count('.')
        when 4, 5
          host = fqdn.split('.').last
        when 3
          host = fqdn.split('.')[2..3].reverse.join('.')
        when 2
          host = fqdn.split('.')[1..3].reverse.join('.')
        else
          raise "Error"
        end
      else
        raise "Not implemented 1"
      end
    end

    def request(method,kind,value,id = nil, type = nil, addr = nil)

      raise "Invalid request. id shouldn't be nil" if kind.eql?('record') && id.nil?
      headers = {'X-Auth-Token' => @auth_token, 'Content-type' => 'application/json'}
      if kind.eql?('domain')
        uri = 'domains.json'
      else
        uri = "domains/#{id}/records.json"
      end

      case method
        when 'get'
          if type.eql?('A')
            headers[:params] = {query: value}
          elsif type.eql?('PTR')
            headers[:params] = {query: value, reverse: true}
          else
            raise "Not implemented"
          end
        when 'post'
          payload = {kind => {'name'=> value, 'type' => type, 'content' => addr}}
          payload = payload.to_json
        when  'delete'
          uri = "records/#{id}.json"
      end

      response = RestClient::Request.execute(
        method: method,
        url: "#{@host}/#{uri}",
        timeout: @timeout,
        headers: headers,
        payload: payload,
      )

      if response.code < 200 || response.code > 399
        raise "Couldn't get a response - code (#{response.code} / message #{response.body})"
      end
      method.eql?('delete') ? "" : JSON.parse(response.body)
    end
  end
end
