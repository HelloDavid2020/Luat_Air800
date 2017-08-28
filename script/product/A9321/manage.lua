--[[
模块名称：manage
模块功能：是否满足定位条件判断
模块最后修改时间：2017.08.25
]]
module(...,package.seeall)

GUARDFNC,HANDLEPWRFNC,MOTORPWRFNC,RMTPWRFNC,BUZZERFNC = true,false,false,false,false

local lastyp,lastlng,lastlat,lastmlac,lastmci,lastlbs2 = "","","","","",""

--[[
函数名：setlastgps
功能  ：保存GPS经纬度
参数  ：
		lng：经度
		lat：纬度
返回值：无
]]
function setlastgps(lng,lat)
	lastyp,lastlng,lastlat = "GPS",lng,lat
	nvm.set("lastlng",lng,nil,false)
	nvm.set("lastlat",lat)
end

--[[
函数名：getlastgps
功能  ：获取GPS经纬度
参数  ：无
返回值：经度，纬度
]]
function getlastgps()
	return nvm.get("lastlng"),nvm.get("lastlat")
end

--[[
函数名：isgpsmove
功能  ：是否满足GPS上报条件
参数  ：经度，纬度
返回值：true，false
]]
function isgpsmove(lng,lat)
	if lastlng=="" or lastlat=="" or lastyp~="GPS" then return true end
	local dist = gps.diffofloc(lat,lng,lastlat,lastlng)
	print("isgpsmove",lat,lng,lastlat,lastlng,dist)
	return dist >= 5*5 or dist < 0
end

--[[
函数名：setlastlbs1
功能  ：设置基站信息
参数  ：基站信息
返回值：无
]]
function setlastlbs1(lac,ci,flg)
	lastmlac,lastmci = lac,ci
	if flg then lastyp = "LBS1" end
end

--[[
函数名：islbs1move
功能  ：是否满足基站移动条件
参数  ：基站信息
返回值：true，false
]]
function islbs1move(lac,ci)
	return lac ~= lastmlac or ci ~= lastmci
end

--[[
函数名：setlastlbs2
功能  ：设置基站信息
参数  ：基站信息
返回值：无
]]
function setlastlbs2(v,flg)
	lastlbs2 = v
	if flg then lastyp = "LBS2" end
	sys.dispatch("LBS_LOC_RPT",v)	
end

--[[
函数名：islbs2move
功能  ：是否满足基站移动条件
参数  ：基站信息
返回值：true，false
]]
function islbs2move(v)
	if lastlbs2 == "" then return true end
	local oldcnt,newcnt,subcnt,chngcnt,laci = 0,0,0,0
	
	for laci in string.gmatch(lastlbs2,"(%d+%.%d+%.%d+%.%d+%.)%d+;") do
		oldcnt = oldcnt + 1
	end
	
	for laci in string.gmatch(v,"(%d+%.%d+%.%d+%.%d+%.)%d+;") do
		newcnt = newcnt + 1
		if not string.match(lastlbs2,laci) then chngcnt = chngcnt + 1 end
	end
	
	if oldcnt > newcnt then chngcnt = chngcnt + (oldcnt-newcnt) end
	local move = chngcnt*100/(newcnt>oldcnt and newcnt or oldcnt)
	print("islbs2move",lastlbs2,v,move)
	return move >= 80
end

--[[
函数名：getlastyp
功能  ：获取最后定位模式
参数  ：无
返回值：最后定位模式
]]
function getlastyp()
	return lastyp
end

--[[
函数名：resetlastloc
功能  ：恢复最后定位信息
参数  ：无
返回值：无
]]
function resetlastloc()
	lastyp,lastlng,lastlat,lastmlac,lastmci,lastlbs2 = "","","","","",""
end

--[[
函数名：workmodind
功能  ：根据定位模式设置位置上报，心跳上报频率
参数  ：无
返回值：true
]]
local function workmodind()
	local mod = nvm.get("workmod")
	print("workmodind mod",mod,nvm.get("gpsleep"))
	if mod=="GPS" then
		if nvm.get("gpsleep") then
			nvm.set("rptfreq",_G.GPSMOD_NOGPS_RPTFREQ,"workmod")
			nvm.set("heart",_G.GPSMOD_NOGPS_HEART,"workmod")	
		else
			nvm.set("rptfreq",_G.GPSMOD_DFT_RPTFREQ,"workmod")
			nvm.set("heart",_G.GPSMOD_DFT_HEART,"workmod")
		end
	elseif mod=="LONGPS" then
		nvm.set("rptfreq",_G.LONGPSMOD_DFT_RPTFREQ,"workmod")
		nvm.set("heart", _G.LONGPSMOD_DFT_HEART,"workmod")
	elseif mod=="PWRGPS" then
		nvm.set("rptfreq",_G.PWRMOD_DFT_RPTFREQ,"workmod")
		nvm.set("heart",_G.PWRMOD_DFT_HEART,"workmod")
	end
	return true
end

local function parachangeind(k,v,r)	
	if k == "workmod" or k=="gpsleep" then
		workmodind()
	end
	return true
end

local procer =
{
	PARA_CHANGED_IND = parachangeind,
}
--注册消息的处理函数
sys.regapp(procer)
workmodind()
