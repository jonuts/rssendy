require "spec_helper"

RSpec.describe RSSendy::Feed do
  subject do
    Class.new(RSSendy::Feed) do
      api_key "hellothar"
      url "http://hello.com"
      content %Q[doc.xpath('//content:encoded').map(&:text).map(&:strip)]
      template File.expand_path("../tmpl.html.erb", __FILE__)
      host "http://mysendyapp.com/sendy"
      from_name "root"
      from_email "root@mysendyapp"
      reply_to from_email
      subject "latest news"
    end
  end

  let :rss do
    <<-RSS
<rss xmlns:content="http://purl.org/rss/1.0/modules/content/" version="2.0">
  <channel>
    <title>
      why, hello thar
    </title>
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

  let(:invalid_err) { RSSendy::Feed::InvalidFeedError}

  it "exposes :api_key" do
    expect(subject.api_key).to eql('hellothar')
  end

  it "exposes :api_key to instances" do
    expect(subject.new.api_key).to eql('hellothar')
  end

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
    expect(subject.template).to eql(File.expand_path('../tmpl.html.erb', __FILE__))
  end

  it "exposes :template to instances" do
    expect(subject.new.template).to eql(File.expand_path('../tmpl.html.erb', __FILE__))
  end

  describe 'instance' do
    let(:feed) { subject.new }

    describe "setting subject" do
      context "when rss_subject false" do
        it "has subject set manually" do
          expect(feed.subject).to eql("latest news")
        end
      end

      context "when rss_subject true" do
        before do
          feed.subject = 'doc.at_xpath("//title").text.strip'
          feed.rss_subject = true
        end

        it "pulls subject from feed" do
          expect(feed.subject[doc]).to eql("why, hello thar")
        end
      end
    end
    describe '#build_template' do
      context "when valid" do
        before do
          allow(feed).to receive(:items).and_return(['hello thar'])
          feed.build_template
        end

        it 'builds :html_template' do
          expect(feed.html_template).to match(%r{<table>((.|\n)*)hello thar((.|\n)*)</table>})
        end
      end

      context "when invalid" do
        before do
          feed.template = nil
        end

        it "throws an error" do
          expect { feed.build_template }.to raise_error(invalid_err)
        end
      end
    end

    describe '#pull!' do
      context "when valid" do
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

      context "when invalid" do
        before { feed.url = nil }

        it "throws an error" do
          expect { feed.pull! }.to raise_error(invalid_err)
        end
      end
    end

    describe "#post" do
      context "when valid"

      context "when invalid" do
        before { feed.host = nil }

        it "throws an error" do
          expect { feed.post }.to raise_error(invalid_err)
        end
      end
    end
  end

  context 'validity' do
    let(:opts) {Hash[reqs.map {|r| [r, "foo-#{r}"]}]}
    subject { RSSendy::Feed.new(opts)}

    context 'valid feed' do
      let(:reqs) { RSSendy::Feed::REQUIREMENTS }
      it { is_expected.to be_valid }
    end

    context 'invalid feed' do
      RSSendy::Feed::REQUIREMENTS.each do |req|
        describe "missing #{req}" do
          let(:reqs) { RSSendy::Feed::REQUIREMENTS.reject {|r| r == req}}
          it { is_expected.to_not be_valid}
        end
      end
    end
  end
end

