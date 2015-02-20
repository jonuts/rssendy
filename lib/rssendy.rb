require "rssendy/version"
require "nokogiri"
require "open-uri"

module RSSendy
  class Feed
    PROPERTIES = %i(
      api_key url template from_name from_email reply_to
      subject plain_text html_text list_ids brand_id send_campaign
    )

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
      return @content if Proc === @content
      _cont = @content.dup
      @content = ->(doc) { doc.instance_eval(_cont.sub(/^doc\./, '')) }
    end

    def pull!
      @response = open(url).read
      @doc = Nokogiri(@response)
      @items = content[@doc]
    end

    def build_template
      tmpl = ERB.new(File.read(template))
      @html_template = tmpl.result(binding)
    end

    def post
      sendy = Cindy.new url, api_key
    end
  end
end

