require 'page_magic'

describe PageMagic do
  describe '::drivers' do
    it 'returns loaded drivers' do
      expected_drivers = described_class::Drivers.new.tap do |drivers|
        drivers.load
      end

      expect(described_class.drivers).to eq(expected_drivers)
    end
  end

  describe '::session' do
    context 'specifying the browser' do
      it 'loads the correct driver' do
        session = described_class.session(browser: :firefox)
        expect(session.raw_session.driver).to be_a(Capybara::Selenium::Driver)
      end
    end

    context 'specifying a rack application' do
      it 'configures capybara to run against the app' do
        session = described_class.session(application: :rack_application)
        expect(session.raw_session.app).to be(:rack_application)
      end
    end

    context 'specifying options' do
      it 'passes the options to the browser driver' do
        options = {option: :config}
        session = described_class.session(options: options, browser: :chrome)

        expect(session.raw_session.driver.options).to include(options)
      end
    end

    context 'driver for browser not found' do
      it 'raises an error' do
        expect{described_class.session(browser: :invalid)}.to raise_exception described_class::UnspportedBrowserException
      end
    end
  end
end
