require 'bundler/setup'
require "rssendy/version"
require "nokogiri"
require "open-uri"
require "cindy"
require "erb"

Cindy::Client.class_eval do
  def create_campaign(opts={})
    post_opts     = {}
    req_opts      = %i(from_name from_email reply_to subject html_text)
    optional_opts = %i(plain_text list_ids brand_id send_campaign)

    req_opts.each do |opt|
      post_opts[opt] = opts.delete(opt) || raise(ArgumentError, "opt :#{opt} required")
    end
    post_opts.merge!(Hash[optional_opts.zip(opts.values_at(*optional_opts))])
    post_opts[:api_key] = @key

    response = connection.post "api/campaigns/create.php" do |req|
      req.body = post_opts
    end

    response.body
  end
end

module RSSendy
  class Feed
    PROPERTIES = %i{
      api_key url template host from_name from_email reply_to
      plain_text html_text list_ids brand_id send_campaign rss_subject
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

      def subject(subj=nil)
        return @__subject__ unless subj
        @__subject__ = subj
      end
    end

    def initialize(opts={})
      PROPERTIES.each do |property|
        send("#{property}=", opts[property] || self.class.send(property))
      end
      @subject = opts.fetch(:subject, self.class.subject)
      @content = opts.fetch(:content, self.class.content)
      @rss_subject = !!rss_subject
    end

    attr_accessor(*PROPERTIES)
    attr_reader :response, :doc, :items, :html_template
    attr_writer :subject

    def content
      return @content if Proc === @content || @content.nil?
      _cont = @content.dup
      @content = ->(doc) { doc.instance_eval(_cont.sub(/^doc\./, '')) }
    end

    def subject
      return @subject unless rss_subject? && !(Proc === @subject)
      return unless @subject

      _subj = @subject.dup
      @subject = ->(doc) { doc.instance_eval(_subj.sub(/^doc\./, '')) }
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

    def missing_keys
      REQUIREMENTS.reject {|prop| send(prop)}
    end

    private

    def rss_subject?
      rss_subject
    end

    def build_opts
      {
        from_name: from_name,
        from_email: from_email,
        reply_to: reply_to,
        subject: rss_subject? ? parse_subject : subject,
        html_text: build_template
      }.tap {|opts|
        %i(plain_text list_ids brand_id send_campaign).each do |property|
          val = send(property)
          opts[property] = val if val
        end
      }
    end

    def parse_subject
      doc.instance_eval(subject)
    end
  end
end

