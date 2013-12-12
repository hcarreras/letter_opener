require "spec_helper"

describe LetterOpener::DeliveryMethod do
  before(:each) do
    Launchy.stub(:open)
    location = File.expand_path('../../../tmp/letter_opener', __FILE__)
    FileUtils.rm_rf(location)
    Mail.defaults do
      delivery_method LetterOpener::DeliveryMethod, :location => location
    end
    @location = location
  end

  it "saves text into html document" do
    Launchy.should_receive(:open)
    mail = Mail.deliver do
      from    'foo@example.com'
      to      'bar@example.com'
      subject 'Hello'
      body    'World!'
    end
    text = File.read(Dir["#{@location}/*/plain.html"].first)
    text.should include("foo@example.com")
    text.should include("bar@example.com")
    text.should include("Hello")
    text.should include("World!")
  end

  it "saves multipart email into html document" do
    mail = Mail.deliver do
      from    'foo@example.com'
      to      'bar@example.com'
      subject 'Many parts'
      text_part do
        body 'This is <plain> text'
      end
      html_part do
        content_type 'text/html; charset=UTF-8'
        body '<h1>This is HTML</h1>'
      end
    end
    text = File.read(Dir["#{@location}/*/plain.html"].first)
    text.should include("View HTML version")
    text.should include("This is &lt;plain&gt; text")
    html = File.read(Dir["#{@location}/*/rich.html"].first)
    html.should include("View plain text version")
    html.should include("<h1>This is HTML</h1>")
  end

  describe 'still works when we cannot write to the file system (i.e. heroku)' do
    before do
      LetterOpener.cannot_write_to_file_system!
      Launchy.should_not_receive(:open)
      mail = Mail.deliver do
        from    'foo@example.com'
        to      'bar@example.com'
        subject 'Hello'
        body    'World!'
      end
    end
    subject { LetterOpener::Letter.all.first }
    it 'should not have saved on our real file system' do
      File.exists?(subject.filepath).should be_false
    end
    its(:contents) { should include("foo@example.com") }
    its(:contents) { should include("bar@example.com") }
    its(:contents) { should include("Hello") }
    its(:contents) { should include("World!") }
  end


  it "saves text into html document when deliver! is called" do
    Launchy.should_receive(:open)
    mail = Mail.new do
      from    'foo@example.com'
      to      'bar@example.com'
      subject 'Hello'
      body    'World!'
    end

    mail.deliver!

    text = File.read(Dir["#{@location}/*/plain.html"].first)
    text.should include("foo@example.com")
    text.should include("bar@example.com")
    text.should include("Hello")
    text.should include("World!")
  end
end
