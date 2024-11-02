require "ostruct"

module Forms
  class BaseService
    def self.call(*args)
      new(*args).call
    end

    private

    def success(data = {})
      OpenStruct.new({ success?: true }.merge(data))
    end

    def failure(data = {})
      OpenStruct.new({ success?: false }.merge(data))
    end
  end
end
