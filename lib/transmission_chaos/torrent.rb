# frozen_string_literal: true

module TransmissionChaos
  class Torrent
    STATUS_MAPPING = %i[stopped check_wait checking download_wait downloading seed_wait seeding].freeze

    attr_reader :id, :date_done, :seconds_seeding, :name, :data, :error, :upload_ratio

    def initialize(id:, name: nil, status: nil, error: nil, **data)
      @id = id
      @name = name
      @status = status
      @error = error
      @date_done = data.delete :doneDate
      @upload_ratio = data.delete :uploadRatio
      @seconds_seeding = data.delete :secondsSeeding
      @data = data

      @date_done = nil if @date_done.zero?
      @date_done = Time.at(@date_done) if @date_done
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

    def seed_weight
      weight = 1

      prioritized_time = 30 * 24 * 60 * 60
      if @date_done
        dist = (Time.now - @date_done)
        weight += (prioritized_time - dist) / 1_000 if dist < prioritized_time
      end

      want_seed_time = 14 * 24 * 60 * 60
      weight += (want_seed_time - @seconds_seeding) / 1_000 if @seconds_seeding && @seconds_seeding < want_seed_time

      if @upload_ratio
        weight += if @upload_ratio < 2
                    (2 - @upload_ratio) * 20
                  elsif @upload_ratio > 4
                    @upload_ratio
                  else
                    0
                  end
      end

      weight
    end
  end
end
