require "spec_helper"

RSpec.describe RSSendy::Feed do
  subject do
    Class.new(RSSendy::Feed) do

      url "http://hello.com"
      content {|doc| doc.xpath('//content:encoded').map(&:text).map(&:strip)}
      template do |items|
        "<table>".tap do |html|
          items.each {|item| html << item}
          html << "</table>"
        end
      end
    end
  end

  let :rss do
    <<-RSS
<rss xmlns:content="http://purl.org/rss/1.0/modules/content/" version="2.0">
  <channel>
    <item>
      <content:encoded>
        <![CDATA[
          <tr><td>hello</td></tr>
        ]]>
      </content:encoded>
    </item>
  </channel>
</rss>
    RSS
  end

  let(:doc) { Nokogiri(rss) }

  let(:content) { "<tr><td>hello</td></tr>"}

  it "exposes :url" do
    expect(subject.url).to eql('http://hello.com')
  end

  it "exposes :url to instances" do
    expect(subject.new.url).to eql('http://hello.com')
  end

  it "exposes :content" do
    expect(subject.content[doc]).to eql([content])
  end

  it "exposes :content to instances" do
    expect(subject.new.content[doc]).to eql([content])
  end

  it "exposes :template" do
    expect(subject.template[subject.content[doc]]).to eql("<table>#{content}</table>")
  end

  it "exposes :template to instances" do
    expect(subject.new.template[subject.content[doc]]).to eql("<table>#{content}</table>")
  end

  describe 'instance' do
    describe '#pull!' do
      let(:feed) { subject.new }

      before do
        allow(feed).to receive_message_chain(:open, :read).and_return(rss)
        feed.pull!
      end

      it "sets :response" do
        expect(feed.response).to eql(rss)
      end

      it "sets :doc" do
        expect(feed.doc.to_html).to eql(doc.to_html)
      end

      it "sets :items" do
        expect(feed.items).to eql([content])
      end
    end
  end
end

