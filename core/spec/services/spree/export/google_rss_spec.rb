require 'spec_helper'
require 'pry'

module Spree
  describe Export::GoogleRss do
    subject { described_class.new }

    let(:store) { create(:store) }
    let(:setting) { create(:google_feed_setting, store: store) }
    let(:product) { create(:product, stores: [store]) }
    let!(:variant) { create(:with_image_variant, product: product) }
    let(:result) { subject.call(setting) }

    context 'store header is generated correctly' do
      before do
        allow(subject).to receive(:store).and_return(store)
      end

      it 'include store name' do
        expect(result).to include("<title>#{store.name}</title>").once
      end

      it 'includes store url' do
        expect(result).to include("<link>#{store.url}</link>").once
      end

      it 'includes store description' do
        expect(result).to include("<description>#{store.meta_description}</description>").once
      end
    end

    context 'required item attributes are generated correctly' do
      before do
        allow(subject).to receive(:store).and_return(store)
      end

      it 'includes id' do
        expect(result).to include("<g:id>#{variant.id}</g:id>").once
      end

      it 'includes title' do
        expect(result).to include("<g:title>#{product.name} - #{variant.option_values.first.name}</g:title>").once
      end

      it 'includes description' do
        expect(result).to include("<g:description>#{product.description}</g:description>").once
      end

      it 'includes link' do
        expect(result).to include("<g:link>#{store.url}/#{product.slug}</g:link>").once
      end

      it 'includes image link' do
        expect(result).to include("<g:image_link>#{variant.images.first.plp_url}</g:image_link>").once
      end

      it 'includes price' do
        expect(result).to include("<g:price>#{variant.price} #{variant.cost_currency}</g:price>").once
      end

      context 'availability date is in the past' do
        it 'shows that product is in stock' do
          expect(result).to include('<g:availability>in stock</g:availability>')
        end

        it 'shows that product availability date is the same' do
          expect(result).to include("<g:availability_date>#{product.available_on.xmlschema}</g:availability_date>")
        end
      end

      context 'availability date is in the future' do
        let(:product) { create(:product, stores: [store], available_on: 1.year.from_now) }

        it 'shows that product is on backorder' do
          expect(result).to include('<g:availability>backorder</g:availability>')
        end
      end

      context 'availability date is nil' do
        let(:product) { create(:product, stores: [store], available_on: nil) }

        it 'shows that product is out of stock' do
          expect(result).to include('<g:availability>out of stock</g:availability>')
        end

        it 'shows that product availability date is nil' do
          expect(result).not_to include('<g:availability_date>')
        end
      end
    end

    context 'optional item attributes are generated correctly' do
      let(:product) { create(:product_with_properties) }

      before do
        allow(subject).to receive(:store).and_return(store)
      end

      it 'adds brand to item attributes' do
        expect(result).to include("<g:brand>#{product.property('brand')}</g:brand>")
      end

      context 'brand option is set to false' do
        let(:setting) { create(:google_feed_setting, store: store, brand: false) }

        it 'does not add brand to item attributes' do
          expect(result).not_to include('<g:brand>')
        end
      end
    end
  end
end
