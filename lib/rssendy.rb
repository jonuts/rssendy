require 'bundler/setup'
require "rssendy/version"
require "nokogiri"
require "open-uri"
require "cindy"
require "erb"

module RSSendy
  class Feed
    PROPERTIES = %i{
      api_key url template host from_name from_email reply_to
      subject plain_text html_text list_ids brand_id send_campaign
    }
    REQUIREMENTS = %i(api_key content url template host from_name from_email reply_to subject)

    InvalidFeedError = Class.new(RuntimeError)

    class <<self
      PROPERTIES.each do |property|
        class_eval <<-ENDEVAL
        def #{property}(val=nil)
          return @__#{property}__ unless val
          @__#{property}__ = val
        end
        ENDEVAL
      end

      def content(cont=nil)
        return @__cont_blk__ unless cont
        @__cont_blk__ = ->(doc) {doc.instance_eval(cont.sub(/^doc\./, ''))}
      end
    end

    def initialize(opts={})
      PROPERTIES.each do |property|
        send("#{property}=", opts[property] || self.class.send(property))
      end
      @content = opts.fetch(:content, self.class.content)
    end

    attr_accessor(*PROPERTIES)
    attr_reader :response, :doc, :items, :html_template

    def content
      return @content if Proc === @content || @content.nil?
      _cont = @content.dup
      @content = ->(doc) { doc.instance_eval(_cont.sub(/^doc\./, '')) }
    end

    def pull!
      raise InvalidFeedError, "Feed invalid. Missing keys: #{missing_keys.inspect}" unless valid?

      @response = open(url).read
      @doc = Nokogiri(@response)
      @items = content[@doc]
    end

    def build_template
      raise InvalidFeedError, "No template set" unless template

      tmpl = ERB.new(File.read(template))
      @html_template = tmpl.result(binding)
    end

    def post
      raise InvalidFeedError, "Feed invalid. Missing keys: #{missing_keys.inspect}" unless valid?

      sendy = ::Cindy.new host, api_key
      sendy.create_campaign(build_opts)
    end

    def valid?
      REQUIREMENTS.all? {|prop| send(prop)}
    end

    private

    def build_opts
      {
        from_name: from_name,
        from_email: from_email,
        reply_to: reply_to,
        subject: subject,
        html_text: build_template
      }.tap {|opts|
        %i(plain_text list_ids brand_id send_campaign).each do |property|
          val = send(property)
          opts[property] = val if val
        end
      }
    end

    def missing_keys
      REQUIREMENTS.reject {|prop| send(prop)}
    end
  end
end

