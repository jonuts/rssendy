require "rssendy/version"
require "nokogiri"
require "open-uri"

module RSSendy
  class Feed
    class <<self
      def url(_url=nil)
        return @__url__ unless _url
        @__url__ = _url
      end

      def content(&cont_blk)
        return @__cont_blk__ unless block_given?
        @__cont_blk__ = cont_blk
      end

      def template(&tmpl_blk)
        return @__tmpl_blk__ unless block_given?
        @__tmpl_blk__ = tmpl_blk
      end
    end

    attr_reader :response, :doc, :items

    def pull!
      @response = open(url).read
      @doc = Nokogiri(@response)
      @items = content[@doc]
    end

    def url
      self.class.url
    end

    def content
      self.class.content
    end

    def template
      self.class.template
    end
  end
end

