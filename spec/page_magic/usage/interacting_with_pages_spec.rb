describe 'interacting with pages' do
  include_context :webapp

  let :page do
    Class.new do
      include PageMagic
      link(:next_page, text: 'next page')
      url '/page1'
    end.new
  end

  before(:each) { page.visit }

  describe 'visit' do
    it 'goes to the class define url' do
      page.visit
      expect(page.session.current_path).to eq('/page1')
    end
  end

  describe 'session' do
    it 'gives access to the page magic object wrapping the user session' do
      expect(page.session.raw_session).to eq(Capybara.current_session)
    end
  end

  describe 'text_on_page?' do
    it 'returns true if the text is present' do
      expect(page.text_on_page?('next page')).to be true
    end

    it 'returns false if the text is not present' do
      expect(page.text_on_page?('not on page')).to be false
    end
  end

  describe 'title' do
    it 'returns the title' do
      expect(page.title).to eq('page1')
    end
  end

  describe 'text' do
    it 'returns the text on the page' do
      expect(page.text).to eq('next page')
    end
  end

  describe 'method_missing' do
    it 'gives access to the elements defined on your page classes' do
      expect(page.next_page.tag_name).to eq('a')
    end
  end

end

