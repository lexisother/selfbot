require 'pg'
require 'thread'

module Selfbot
  # Database adapter extensions
  module DBC; end

  class Database
    include DBC

    def initialize(config = {})
      @pg = PG::Connection.open(**config)
      @mutex = Mutex.new

      @pg.type_map_for_queries = PG::BasicTypeMapForQueries.new(@pg)
      @pg.type_map_for_results = PG::BasicTypeMapForResults.new(@pg)
    end

    def query(sql, args = [], &blk)
      @mutex.synchronize { @pg.exec_params(sql, args, &blk) }
    end

    def transaction
      @mutex.synchronize { @pg.transaction { yield self } }
    end

    def disconnect
      @pg.close
    end
  end
end
