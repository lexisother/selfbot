require 'pg'
require 'thread'

module Selfbot
  # Database adapter extensions
  module DBC; end

  class Database
    include DBC

    RECONN_MAX = 3

    def initialize(config = {})
      @pg = PG::Connection.open(**config)
      @mutex = Mutex.new

      @pg.type_map_for_queries = PG::BasicTypeMapForQueries.new(@pg)
      @pg.type_map_for_results = PG::BasicTypeMapForResults.new(@pg)
    end

    def query(sql, args = [], &blk)
      @mutex.synchronize do
        reconn = 0

        begin
          @pg.exec_params(sql, args, &blk)
        rescue PG::UnableToSend
          raise if reconn > RECONN_MAX

          LOGGER.warn("Selfbot") { "Database connection failure, reconnecting..." }

          @pg.reset
          reconn += 1
          retry
        end
      end
    end

    def transaction
      @mutex.synchronize { @pg.transaction { yield self } }
    end

    def disconnect
      @pg.close
    end
  end
end
