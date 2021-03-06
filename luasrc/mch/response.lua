#!/usr/bin/env lua
-- -*- lua -*-
-- Copyright 2012 Appwill Inc.
-- Author : KDr2
--
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--
--

module('mch.response',package.seeall)

mchutil=require('mch.util')
functional=require('mch.functional')
ltp=require("ltp.template")

Response={ltp=ltp}

function Response:new()
    local ret={
        headers=ngx.header,
        _cookies={},
        _output={}
    }
    setmetatable(ret,self)
    self.__index=self
    return ret
end

function Response:write(content)
    table.insert(self._output,content)
end

function Response:writeln(content)
    table.insert(self._output,content)
    table.insert(self._output,"\r\n")
end

function Response:redirect(url, status)
    ngx.redirect(url, status)
end

function Response:_set_cookie(key, value, encrypt, duration, path)

    if not value then return nil end
    
    if not key or key=="" or not value then
        return
    end

    if not duration or duration<=0 then
        duration=86400
    end

    if not path or path=="" then
        path = "/"
    end

    if value and value~="" and encrypt==true then
        value=ndk.set_var.set_encrypt_session(value)
        value=ndk.set_var.set_encode_base64(value)
    end

    local expiretime=ngx.time()+duration
    expiretime = ngx.cookie_time(expiretime)
    return table.concat({key, "=", value, "; expires=", expiretime, "; path=", path})
end

function Response:set_cookie(key, value, encrypt, duration, path)
    local cookie=self:_set_cookie(key, value, encrypt, duration, path)
    self._cookies[key]=cookie
    ngx.header["Set-Cookie"]=mch.functional.table_values(self._cookies)
end

--[[
LTP Template Support
--]]

ltp_templates_cache={}

function ltp_function(template)
    ret=ltp_templates_cache[template]
    if ret then return ret end
    local tdata=mchutil.read_all(MOOCHINE_APP_PATH .. "/templates/" .. template)
    local rfun = ltp.load_template(tdata, '<?lua','?>')
    ltp_templates_cache[template]=rfun
    return rfun
end

function Response:ltp(template,data)
    local rfun=ltp_function(template)
    local output = {}
    local mt={__index=_G}
    setmetatable(data,mt)
    ltp.execute_template(rfun, data, output)
    table.insert(self._output,output)
end


