# frozen_string_literal: true

module TransmissionChaos
  class Torrent
    STATUS_MAPPING = %i[stopped check_wait checking download_wait downloading seed_wait seeding].freeze

    attr_reader :id, :name, :data, :error

    def initialize(id:, name: nil, status: nil, error: nil, **data)
      @id = id
      @name = name
      @status = status
      @error = error
      @data = data
    end

    def errored?
      !@error.zero?
    end

    def stopped?
      @status.zero?
    end

    def active?
      [4, 6].include? @status
    end

    def seeding?
      @status == 6
    end

    def status
      STATUS_MAPPING[@status]
    end
  end
end
