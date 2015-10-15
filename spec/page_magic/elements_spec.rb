describe PageMagic::Elements do


  let(:page_elements) do
    Class.new do
      extend(PageMagic::Elements)
    end
  end

  let(:selector) { {id: 'id'} }
  let(:browser_element) { double('browser_element', find: :browser_element) }
  let(:parent_page_element) do
    double('parent_page_element', browser_element: browser_element)
  end

  describe 'adding elements' do

    context 'using a selector' do
      it 'should add an element' do
        expected_element = PageMagic::Element.new(:name, parent_page_element, type: :text_field, selector: selector)
        page_elements.text_field :name, selector
        expect(page_elements.element_definitions[:name].call(parent_page_element)).to eq(expected_element)
      end
    end

    context 'complex elements' do


      let!(:section_class) do
        Class.new(PageMagic::Element) do

          def == other

            other.name == self.name &&
                other.browser_element == self.browser_element
          end

        end
      end

      context 'using a predefined class' do
        it 'should add a section' do
          expected_section = section_class.new(:page_section, parent_page_element, type: :section, selector: selector)

          page_elements.section section_class, :page_section, selector
          expect(page_elements.elements(parent_page_element).first).to eq(expected_section)
        end

        context 'name' do
          it 'should default to the name of the class if one is not supplied' do
            allow(section_class).to receive(:name).and_return('PageSection')
            page_elements.section section_class, selector
            expect(page_elements.elements(parent_page_element).first.name).to eq(:page_section)

          end
        end

        it 'does not require a block' do
          expect { page_elements.section :page_section, :object }.not_to raise_exception
        end
      end


      context 'using a block' do

        context 'browser_element' do
          before :each do

            @browser, @element, @parent_page_element = double('browser'), spy('element'), double('parent_page_element')
            allow(@parent_page_element).to receive(:browser_element).and_return(@browser)
            expect(@browser).to receive(:find).with(:css, :selector).and_return(@element)
          end

          it 'should be assigned when selector is passed to section method' do
            page_elements.section :page_section, css: :selector do
              browser_element.example
            end

            page_elements.element_definitions[:page_section].call(@parent_page_element)
            expect(@element).to have_received(:example)
          end

          it 'should be assigned when selector is defined in the block passed to the section method' do
            page_elements.section :page_section do
              selector css: :selector
              browser_element.example
            end

            page_elements.elements(@parent_page_element, nil)
            expect(@element).to have_received(:example)
          end
        end


        it 'should pass args through to the block' do
          page_elements.section :page_section, css: '.blah' do |arg|
            arg[:passed_through] = true
          end

          arg, browser = {}, double('browser', find: :browser_element)
          parent_page_element = double('parent_browser_element', browser_element: browser)
          page_elements.elements(parent_page_element, arg)
          expect(arg[:passed_through]).to be true
        end


        it 'should return your a copy of the core definition' do
          page_elements.section section_class, :page_section, selector
          first = page_elements.element_definitions[:page_section].call(parent_page_element)
          second = page_elements.element_definitions[:page_section].call(parent_page_element)
          expect(first).not_to equal(second)
        end

      end

      describe 'location' do
        context 'a prefetched object' do
          it 'should add a section' do
            expected_section = section_class.new(:page_section, parent_page_element, type: :section, browser_element: :object)
            page_elements.section :page_section, :object
            expect(expected_section).to eq(page_elements.elements(parent_page_element).first)
          end
        end
      end

      describe 'session handle' do
        it 'should be on instances created from a class' do
          browser_element = double(:browser_element, find: :browser_element)
          parent = double('parent', session: :current_session, browser_element: browser_element)
          page_elements.section section_class, :page_section, selector

          section = page_elements.element_definitions[:page_section].call(parent)

          expect(section.session).to eq(:current_session)

        end

        it 'should be on instances created dynamically using the section method' do

          browser_element = double('browser_element')
          allow(browser_element).to receive(:find)
          parent = double('parent', session: :current_session, browser_element: browser_element)

          page_elements.section :page_section, css: :selector do

          end

          section = page_elements.element_definitions[:page_section].call(parent)
          expect(section.session).to eq(:current_session)
        end
      end
    end
  end

  describe 'retrieving element definitions' do
    it 'should return your a copy of the core definition' do
      page_elements.text_field :name, selector
      first = page_elements.element_definitions[:name].call(parent_page_element)
      second = page_elements.element_definitions[:name].call(parent_page_element)
      expect(first).not_to equal(second)
    end
  end



  describe 'restrictions' do
    it 'should not allow method names that match element names' do
      expect do
        page_elements.class_eval do
          link(:hello, text: 'world')

          def hello;
          end
        end
      end.to raise_error(PageMagic::Elements::InvalidMethodNameException)
    end

    it 'should not allow element names that match method names' do
      expect do
        page_elements.class_eval do
          def hello;
          end

          link(:hello, text: 'world')
        end
      end.to raise_error(PageMagic::Elements::InvalidElementNameException)
    end

    it 'should not allow duplicate element names' do
      expect do
        page_elements.class_eval do
          link(:hello, text: 'world')
          link(:hello, text: 'world')
        end
      end.to raise_error(PageMagic::Elements::InvalidElementNameException)
    end

    it 'should not evaluate the elements when applying naming checks' do
      page_elements.class_eval do
        link(:link1, :selector) do
          fail("should not have been evaluated")
        end
        link(:link2, :selector)
      end
    end
  end
end
