module Selfbot::Defs

  ## DB: keyvalues ##

  KEYVALUE_GET = %(select value from keyvalues where key = $1)
  KEYVALUE_SET = %(insert into keyvalues (key, value) values ($1, $2) on conflict (key) do update set value = $2)
  KEYVALUE_CLEAR = %(delete from keyvalues where key = $1)

  ## DB: tagstore ##

  TAG_FIND = %(select content from tagstore where tag = $1)
  TAG_LIST = %(select tag from tagstore where owner = $1)
  TAG_ADD = %(insert into tagstore (tag, owner, content) values ($1, $2, $3))
  TAG_EDIT = %(update tagstore set content = $2 where tag = $1)
  TAG_REMOVE = %(delete from tagstore where tag = $1 or owner = $2)

  ## DBC Object Extensions ##
  
  module Selfbot::DBC

    ## DBC: keyvalue ##

    def keyvalue(**args)
      if (key = args[:clear])
        query(KEYVALUE_CLEAR, [key])
        nil
      elsif (key = args[:set])
        value = args[:value].to_s
        query(KEYVALUE_SET, [key, value])
        nil
      elsif (key = args[:get])
        res = query(KEYVALUE_GET, [key])
        res.one? ? res.first['value'] : nil
      end
    end
  end
end
