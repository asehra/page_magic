describe 'including PageMagic' do
  context 'lets you define pages' do
    let :page_class do
      Class.new{include PageMagic}
    end

    it 'gives a method for defining the url' do
      page_class.url :url
      expect(page_class.url).to eq(:url)
    end

    it 'lets you define elements' do
      expect(page_class).to be_a(PageMagic::Elements)
    end
  end
end
