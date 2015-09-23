module GlobodnsClient
  class AlreadyExists < StandardError
    attr_reader :message

    def initialize(message)
      @message = message
    end

    def to_s #:nodoc:
      "#{@message}"
    end

    def inspect #:nodoc:
      "#<#{self.class}: message: #{@message.inspect}>"
    end
  end

  class NotFound < StandardError
    attr_reader :message

    def initialize(message)
      @message = message
    end

    def to_s #:nodoc:
      "#{@message}"
    end

    def inspect #:nodoc:
      "#<#{self.class}: message: #{@message.inspect}>"
    end
  end
end
