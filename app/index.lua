local args = ngx.req.get_uri_args()


local redis = require "resty.redis"
local cache= redis:new()

local ok,err = cache:connect("127.0.0.1",6379)

if not ok then
  ngx.say("fail to connect",err)
  return false
end


local function isLogin(token)
  return true
end

local function isOften(token)

  res,err = cache:get(token)

  if res==ngx.null then
    cache:set(token,1)
    cache:expire(token,"60")
    return true
  else
    if tonumber(res)>=10 then
      return false
    else
      cache:incr(token)
      return true
    end
  end
end



if args["token"]~=nil and args["page"]~=nil and args["expression"]~=nil then
  local e = args["expression"]
  local p = args["page"]

  if isLogin(args["token"]) then
    if not isOften(args["token"]) then
      -- 访问太频繁
      ngx.say("{error:-3}")
    else
      -- local url = "http://localhost:8080/m/s?expression="..e.."&page="..p
      -- local url = "http://127.0.0.1:8080/m/s?expression=S%26K&page=1"
      local res = ngx.location.capture("/proxy",{args={expression=e,page=p}})
      ngx.say(res.body)
    end
  else
    -- 未登陆
    ngx.say("{error:-1}")
  end
else
  -- 参数不完整
  ngx.say("{error:-2}")
end
