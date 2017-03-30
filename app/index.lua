local args = ngx.req.get_uri_args()



local redis = require "resty.redis"
redis.add_commands("sadd")
local cache= redis:new()

local ok,err = cache:connect("127.0.0.1",6379)

if not ok then
  ngx.say("fail to connect",err)
  return false
end


local function isLogin(token)
  res,err = cache:get(token.."Login")
  if res==ngx.null or tonumber(res)==0 then
    return false
  else
    return true
  end
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


-- 记录操作
local function recordLog(token,expression)
  local remoteIp = ngx.var.remote_addr
  local time = ngx.now()
  local tokenLocal = token
  local expressionLocal = expression


  local IpKey = remoteIp.."CountIp"
  local TokenKey = token.."CountToken"
  -- 设置IP集合
  cache:sadd("IpSet",remoteIp)
  -- 以 IP+Collections 为 key ，放入list中，以 ‘-’ 为分割
  cache:lpush(remoteIp.."Collections",expression.."-"..time.."-"..token)
  local res,err = cache:get(IpKey)
  if res==ngx.null then
    cache:set(IpKey,1)
    -- cache:expire(IpKey,"86400")
  else
    cache:incr(IpKey)
  end
end

local ep,tp  = "",""
if args["token"]~=nil then
  tp = args["token"]
end
if args["expression"]~=nil then
  ep = args["expression"]
end
recordLog(tp,ep)


if args["token"]~=nil and args["page"]~=nil and args["expression"]~=nil then
  local e = args["expression"]
  local p = args["page"]

  if isLogin(args["token"]) then
    if not isOften(args["token"]) then
      -- 访问太频繁
      ngx.say('{"error": -3, "msg": "too often visit"}')
    else
      local res = ngx.location.capture("/proxy",{args={expression=e,page=p}})
      ngx.say(res.body)
    end
  else
    -- 未登陆
    ngx.say('{"error":-1,"msg":"please login and visit"}')
  end
else
  -- 参数不完整
  ngx.say('{"error":-2,"msg":"please check your expression"}')
end
