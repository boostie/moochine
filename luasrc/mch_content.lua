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



function setup_app()
    local app_path = ngx.var.MOOCHINE_APP_PATH
    local app_name = ngx.var.MOOCHINE_APP_NAME or "mch_default_app"
    local mch_home = ngx.var.MOOCHINE_HOME
    if not _G['MOOCHINE_HOME'] then
        _G['MOOCHINE_HOME']=mch_home
        package.path = mch_home .. '/lualibs/?.lua;' .. package.path
        package.path = mch_home .. '/luasrc/?.lua;' .. package.path
        ngx.log(ngx.ERR,"0===",tostring(package.loaded['mch.router']))
        ngx.log(ngx.ERR,"0===",tostring(mch))
    end
    local mchutil=require("mch.util")
    mchutil.setup_app_env(mch_home,app_path,app_name,_G)
    mchutil.moochine_require("routing")
end

function content()
    local app_env_key='MOOCHINE_APP_' .. (ngx.var.MOOCHINE_APP_NAME)
    if not _G[app_env_key] then
        setup_app()
    end
    if not _G[app_env_key] then
        ngx.say('Can not setup MOOCHINE APP')
        ngx.exit(501)
    end
    local uri=ngx.var.REQUEST_URI
    local route_map=_G[app_env_key]['route_map']
    for k,v in pairs(route_map) do
        local args=string.match(uri, k)
        if args then
            local request=_G['MOOCHINE_MODULES']['request']
            local response=_G['MOOCHINE_MODULES']['response']
            if type(v)=="function" then
                local response=response.Response:new()
                v(request.Request:new(),response,args)
                ngx.print(response._output)
            elseif type(v)=="table" then
                v:_handler(request.Request:new(),response.Response:new(),args)
            else
                ngx.exit(500)
            end
            break
        end
    end
end

content()


