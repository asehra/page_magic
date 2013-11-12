require 'spec_helper'
require 'capybara/rspec'
require 'sinatra/base'

describe 'page magic' do
  include Capybara::DSL

  describe 'class level' do
    let(:app_class) do
      Class.new do
        def call env
          [200, {}, ["hello world!!"]]
        end
      end
    end
    context 'session' do

      it 'should setup a session using the specified browser' do
        Capybara::Session.should_receive(:new).with(:chrome, nil).and_return(:chrome_session)

        session = PageMagic.session(:chrome)
        Capybara.drivers[:chrome].call(nil).should == Capybara::Selenium::Driver.new(nil, browser: :chrome)

        session.browser.should == :chrome_session
      end

      it 'should use the Capybara default browser if non is specified' do
        Capybara.default_driver = :rack_test
        session = PageMagic.session
        session.browser.mode.should == :rack_test
      end

      it 'should use the supplied Rack application' do
        session = PageMagic.session(application: app_class.new)
        session.browser.visit('/')
        session.browser.text.should == 'hello world!!'
      end

      it 'should use the rack app with a given browser' do
        session = PageMagic.session(:rack_test, application: app_class.new)
        session.browser.mode.should == :rack_test
        session.browser.visit('/')
        session.browser.text.should == 'hello world!!'
      end

      context 'supported browsers' do
        it 'should support the poltergeist browser' do
          session = PageMagic.session(:poltergeist, application: app_class.new)
          session.browser.driver.is_a?(Capybara::Poltergeist::Driver).should be_true
        end

        it 'should support the selenium browser' do
          session = PageMagic.session(:selenium, application: app_class.new)
          session.browser.driver.is_a?(Capybara::Selenium::Driver).should be_true
        end
      end
    end
  end

  describe 'instances' do

    include_context :webapp

    let(:my_page_class) do
      Class.new do
        include PageMagic
        url '/page1'
        link(:next, :text => "next page")
      end
    end

    let(:another_page_class) do
      Class.new do
        include PageMagic
        url '/another_page1'
      end
    end

    before :each do
      @page = my_page_class.new
    end


    describe 'browser integration' do
      it "should use capybara's default session if a one is not supplied" do
        Capybara.default_driver = :rack_test
        my_page_class.new.browser.mode.should == :rack_test
      end
    end


    describe 'parent pages' do
      before :all do
        module ParentPage
          include PageMagic
          link(:next, :text => "next page")
        end

        class ChildPage
          include ParentPage
          url '/page1'
        end
      end

      context 'children' do
        it 'override parents url' do
          ChildPage.url.should == '/page1'
        end

        it 'inherit elements' do
          child_page = ChildPage.new
          child_page.visit
          child_page.element_definitions.should include(:next)
        end

        it 'are added to PageMagic.pages list' do
          PageMagic.pages.find_all { |page| page == ChildPage }.size.should == 1
        end
      end

      context 'parent' do
        it 'is not registered as Page' do
          PageMagic.pages.should_not include(ParentPage)
        end

        it 'cannot be instantiated' do
          expect { ParentPage.new }.to raise_error("You can only instantiate child pages")
        end
      end
    end

    describe 'visit' do
      it 'should go to the page' do
        @page.visit
        @page.current_path.should == '/page1'
      end
    end

    describe 'text_on_page' do
      it 'should return true' do
        @page.visit
        @page.text_on_page?('next page').should be_true
      end

      it 'should return false' do
        @page.visit
        @page.text_on_page?('billy bob').should be_false
      end

    end


    it 'can have fields' do
      @page.element_definitions[:next].call(@page).should == PageMagic::PageElement.new(:next, @page, :button, :text => "next")
    end

    it 'should copy fields on to element' do
      new_page = my_page_class.new
      @page.element_definitions[:next].call(@page).should_not equal(new_page.element_definitions[:next].call(new_page))
    end

    it 'gives access to the page text' do
      @page.visit.text.should == 'next page'
    end

    it 'should access a field' do
      @page.visit
      @page.click_next
      @page.text.should == 'page 2 content'
    end

    it 'are registered at class level' do
      PageMagic.instance_variable_set(:@pages, nil)

      page = Class.new { include PageMagic }
      PageMagic.pages.should == [page]
    end
  end
end