function getRedisConnetion()
  local redis = require "resty.redis"
  redis.add_commands("sadd")
  local cache= redis:new()

  local ok,err = cache:connect("127.0.0.1",6379)

  if not ok then
    ngx.say("fail to connect",err)
    return false
  end

  return cache
