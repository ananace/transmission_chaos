# frozen_string_literal: true

require 'transmission_chaos/client'
require 'transmission_chaos/torrent'
require 'transmission_chaos/version'

autoload :Logging, 'logging'

module TransmissionChaos
  class Error < StandardError; end

  def self.debug!
    logger.level = :debug
  end

  def self.logger
    @logger ||= ::Logging.logger[self].tap do |logger|
      logger.add_appenders ::Logging.appenders.stdout
      logger.level = :info
    end
  end
end
