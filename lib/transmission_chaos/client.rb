# frozen_string_literal: true

require 'json'
require 'net/http'

module TransmissionChaos
  class Client
    UPDATE_INTERVAL = 30

    attr_accessor :url, :validate_certificate, :proxy_uri, :read_timeout, :target_percent, :target_number

    def initialize(url, target_percent: nil, target_number: nil, **params)
      url = URI.parse(url) unless url.is_a? URI

      @url = url
      @url.path = '/transmission/rpc'

      @validate_certificate = params[:validate_certificate]
      @proxy_uri = params[:proxy_uri]
      @read_timeout = params.fetch(:read_timeout, 30)
      @target_percent = target_percent.to_f if target_percent
      @target_number = target_number.to_i if target_number
      @ignore_downloading = params.fetch(:ignore_downloading, false)

      raise ArgumentError, 'Either target percentage or number must be specified' unless target_percent || target_number
      logger.info 'Both target number and percentage given, acting on percentage' if target_percent && target_number

      @torrents_updated = Time.new(0)
    end

    def logger
      @logger ||= ::Logging.logger[self]
    end

    def add_chaos
      filter = @ignore_downloading ? :seeding? : :active?
      running = torrents.select(&filter)
      ready_for_more = torrents.select { |t| t.stopped? && !t.errored? }

      return unless ready_for_more.any?

      if target_percent
        running_perc = running.count.to_f / torrents.count.to_f

        if running_perc < (target_percent / 100.0)
          logger.info "Less than #{target_percent}% active torrents (#{running.count}/#{torrents.count} | #{(running_perc * 100).to_i}%), starting some more;"

          to_start = (((target_percent / 100.0) - running_perc) * torrents.count).ceil
          to_start = ready_for_more.sample(to_start)

          to_start.each do |torrent|
            logger.info "Starting #{torrent.name}"
          end

          rpc_call('torrent-start', ids: to_start.map(&:id))
        else
          logger.info "Transmission currently in chaos. #{running.count}/#{torrents.count} active (#{(running_perc * 100).to_i}%)"
        end
      elsif target_number
        if running.count < target_number
          logger.info "Less than #{target_number} active torrents (#{running.count}/#{torrents.count}), starting some more;"
          to_start = ready_for_more.sample(target_number - running.count)

          to_start.each do |torrent|
            logger.info "Starting #{torrent.name}"
          end

          rpc_call('torrent-start', ids: to_start.map(&:id))
        else
          logger.info "Transmission currently in chaos. #{running.count}/#{torrents.count} active."
        end
      end
    end

    def torrents
      @torrents = nil if Time.now - @torrents_updated > UPDATE_INTERVAL

      @torrents ||= begin
        data = rpc_call('torrent-get', fields: %i[id error name status])
        @torrents_updated = Time.now
        data[:torrents].map { |t| Torrent.new(**t) }
      end
    end

    def rpc_call(method, **arguments)
      req = Net::HTTP::Post.new url
      req.body = { method: method, arguments: arguments }.to_json
      req.content_type = 'application/json'
      req.content_length = req.body.size
      req['x-transmission-session-id'] = @session_id if @session_id

      loop do
        print_http(req)
        begin
          response = http.request req
        rescue EOFError => e
          logger.error 'Socket closed unexpectedly'
          raise e
        end
        print_http(response)

        if response.is_a? Net::HTTPConflict
          @session_id = response['x-transmission-session-id']
          req['x-transmission-session-id'] = @session_id
        else
          data = JSON.parse(response.body, symbolize_names: true) rescue nil

          return data[:arguments]
        end
      end
    end

    private

    def print_http(http)
      return unless logger.debug?

      if http.is_a? Net::HTTPRequest
        dir = '>'
        logger.debug "#{dir} Sending a #{http.method} request to `#{http.path}`:"
      else
        dir = '<'
        logger.debug "#{dir} Received a #{http.code} #{http.message} response:"
      end
      http.to_hash.map { |k, v| "#{k}: #{k == 'authorization' ? '[ REDACTED ]' : v.join(', ')}" }.each do |h|
        logger.debug "#{dir} #{h}"
      end
      logger.debug dir
      clean_body = JSON.parse(http.body) rescue nil if http.body
      clean_body.keys.each { |k| clean_body[k] = '[ REDACTED ]' if %w[password access_token].include?(k) }.to_json if clean_body
      logger.debug "#{dir} #{clean_body.length < 200 ? clean_body : clean_body.slice(0..200) + "... [truncated, #{clean_body.length} Bytes]"}" if clean_body
    rescue StandardError => e
      logger.warn "#{e.class} occured while printing request debug; #{e.message}\n#{e.backtrace.join "\n"}"
    end

    def http
      return @http if @http&.active?

      host = (@connection_address || url.host)
      port = (@connection_port || url.port)
      @http ||= if proxy_uri
                  Net::HTTP.new(host, port, proxy_uri.host, proxy_uri.port, proxy_uri.user, proxy_uri.password)
                else
                  Net::HTTP.new(host, port)
                end

      @http.read_timeout = read_timeout
      @http.use_ssl = url.scheme == 'https'
      @http.verify_mode = validate_certificate ? ::OpenSSL::SSL::VERIFY_NONE : nil
      @http.start
      @http
    end
  end
end
