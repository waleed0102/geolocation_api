module GeolocationProviders
  class Result
    attr_reader :data, :error

    def self.success(data)
      new(data: data)
    end

    def self.failure(error)
      new(error: error)
    end

    def success?
      @error.nil?
    end

    def failure?
      !success?
    end

    private

    def initialize(data: nil, error: nil)
      @data = data
      @error = error
    end
  end
end
