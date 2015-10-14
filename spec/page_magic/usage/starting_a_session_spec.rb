describe 'PageMagic.session' do

  let(:app_class) do
    Class.new do
      def call env
        [200, {}, ["hello world!!"]]
      end
    end
  end

  def registered_driver browser
    Capybara.drivers[browser].call(nil)
  end

  context 'specificying a browser' do
    it 'loads the driver for the specified browser' do
      session = PageMagic.session(browser: :firefox)
      expect(session.raw_session.driver).to be_a(Capybara::Selenium::Driver)
    end
  end

  context 'testing against rack applications' do

    it 'requires the app to be supplied' do
      session = PageMagic.session(application: app_class.new)
      session.raw_session.visit('/')
      expect(session.raw_session.text).to eq('hello world!!')
    end

    it 'can run against an rack application using a particular browser' do
      session = PageMagic.session(browser: :rack_test, application: app_class.new)
      expect(session.raw_session.mode).to eq(:rack_test)
      session.raw_session.visit('/')
      expect(session.raw_session.text).to eq('hello world!!')
    end
  end

end
