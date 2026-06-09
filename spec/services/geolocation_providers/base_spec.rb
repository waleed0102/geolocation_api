require "rails_helper"

RSpec.describe GeolocationProviders::Base do
  describe "#fetch" do
    it "raises NotImplementedError, enforcing the provider contract" do
      expect { described_class.new.fetch("1.2.3.4") }
        .to raise_error(NotImplementedError, /must implement #fetch/)
    end
  end
end
