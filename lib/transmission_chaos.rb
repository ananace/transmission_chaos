# frozen_string_literal: true

require 'logging'
require_relative 'transmission_chaos/version'

module TransmissionChaos
  class Error < StandardError; end

  autoload :Client, 'transmission_chaos/client'

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
