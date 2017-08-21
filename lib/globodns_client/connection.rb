require 'rest-client'
require 'json'

module GlobodnsClient
  class Connection
    def initialize(options)
      @bearer_token = options[:bearer_token]
      @host = options[:host]
      @timeout = options[:timeout] || 30
      raise ArgumentError, "You must inform the bearer token and host for GloboDNS" unless @bearer_token && @host
    end

    def set_token token
      @bearer_token = token
    end

    def get_domain(key)
      domain = key.dup
      domain.chomp!('.')
      res = {}
      while domain.count('.') >= 1
        res = request('get','domain', domain)
        if !res.empty?
          domain = ""
        else
          domain.gsub!(/^([a-zA-Z0-9\-_]*.)/,'')
        end
      end
      res unless res.empty?
    end

    def get_zone(key, kind = 'A')
      res = request('get','domain', key, nil, kind)
      if kind.eql?('A') && !res.empty?
        res
      else
        get_zone_recursive(key, kind)
      end
    end

    def get_zone_recursive(key, kind = 'A')
      if kind.eql?('A') or kind.eql?('CNAME')
        domain = key.split('.', 2).last
      elsif kind.eql?('PTR')
        if key.include?('in-addr.arpa')
          domain = key.split('.', 2).last
        else
          match = key.match(/(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})/)
          domain = (match[1..3]+["0"]).reverse.join('.')+'.in-addr.arpa'
        end
      else
        raise "Not implemented"
      end
      res = request('get','domain', domain, nil, kind)
      if res.empty?
        if domain.count('.') > 1 && (kind == 'A' or kind == 'CNAME') || domain.count('.') > 2 && kind == 'PTR'
          res = get_zone_recursive(domain, kind)
        else
          raise GlobodnsClient::NotFound, "Couldn't find a proper zone for '#{key}'"
        end
      end
      res
    end

    def get_record(key, kind, zone)
      zone.flatten!
      res = []
      zone = get_zone(key, kind) if zone.nil?
      host = get_host(key, zone, kind)
      response = request('get', 'record', host, zone[0][:domain][:id], kind)
      response.each do |r|
        res << r[kind.downcase.to_sym] unless r[kind.downcase.to_sym].nil?
      end
      res.empty? ? false : res
    end

    def new_record(key, kind, value)
      zone = get_zone(key, kind)
      if record = get_record(key, kind, zone)
        raise GlobodnsClient::AlreadyExists, "Item (#{key}) already exists with reference (#{record['content']})"
      else
        host = get_host(key, zone, kind)
        response = request('post', 'record', host, zone[0][:id], kind, value)
      end
      begin
        schedule_export
      rescue Exception
      end
      response['record']
    end

    def delete_record(key, kind)
      zone = get_zone(key, kind)
      unless records = get_record(key, kind, zone)
        raise GlobodnsClient::NotFound, "Record not found for (#{key})"
      end
      response=[]
      records.each do |record|
        response << request('delete', 'record', nil, record[:id])
      end
      begin
        schedule_export
      rescue Exception
      ensure
        response
      end
    end

    private

    def get_host(key, zone, kind)
      if kind.eql?('A') or kind.eql?('CNAME')
        host = key.split('.'+zone[0][:domain][:name])[0]
      elsif kind.eql?('PTR')
        case zone[0][:domain][:name].count('.')
        when 4, 5
          host = key.split('.').last
        when 3
          host = key.split('.')[2..3].reverse.join('.')
        when 2
          host = key.split('.')[1..3].reverse.join('.')
        else
          raise "Error"
        end
      else
        raise "Not implemented"
      end
    end

    def request(method,kind,value,id = nil, type = nil, addr = nil)

      raise ArgumentError, "Invalid request. id shouldn't be nil" if kind.eql?('record') && id.nil?
      headers = {'Authorization' => "Bearer #{@bearer_token}", 'Content-type' => 'application/json'}

      case kind
      when 'domain'
        uri = 'domains.json'
      when 'record'
        uri = "domains/#{id}/records.json"
      when 'export'
        uri = 'bind9/schedule_export.json'
      end

      case method
        when 'get'
          if type.eql?('A') or type.eql?('CNAME')
            headers[:params] = {query: value}
          elsif type.eql?('PTR')
            headers[:params] = {query: value, reverse: true}
          elsif kind.eql?('domain')
            headers[:params] = {query: value}
          else
            raise "Not implemented"
          end
        when 'post'
          if kind.eql?('record')
            payload = {kind => {'name'=> value, 'type' => type, 'content' => addr}}
            payload = payload.to_json
          end
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
        raise "Couldn't get a response from GloboDNS - code (#{response.code} / message #{response.body})"
      end
      method.eql?('delete') ? "" : JSON.parse(response.body, {:symbolize_names => true, :object_class => Hash})
    end
  end

  def schedule_export
    response = request('post', 'export', nil)
  end
end
