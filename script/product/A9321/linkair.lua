--[[
模块名称：mqtt client应用处理模块
模块功能：连接服务器，发送登陆报文，定时上报定位信息
模块最后修改时间：2017.08.25
]]

module(...,package.seeall)

require"protoair"
require"sms"
require"dbg"
require"socket"

local ssub,schar,smatch = string.sub,string.char,string.match
local SCK_IDX,KEEP_ALIVE_TIME = 1,720
local rests,shkcnt = "",0
local locshk,firstloc,firstgps = "SIL"
local chgalm,shkalm = true,true
local verno,mqttconnfailcnt,mqttconn,monitnum = 1,0
local histloc = {}
local mqttclient
local PROT,ADDR,PORT = nvm.get("prot"),nvm.get("addr"),nvm.get("port")

local function print(...)
	_G.print("linkair",...)
end

--[[
函数名：getstatus
功能  ：获取需要状态
参数  ：无
返回值：状态
]]
local function getstatus()
	local t = {}

	t.shake = (shkcnt > 0) and 1 or 0
	shkcnt = 0
	t.charger = chg.getcharger() and 1 or 0
	t.acc = acc.getflag() and 1 or 0
	t.gps = gps.isopen() and 1 or 0
	t.sleep = pm.isleep() and 1 or 0
	t.volt = chg.getvolt()	
	t.fly = 0
	t.poweroff = 0
	t.rest = 0
	return t
end

--[[
函数名：getgps
功能  ：获取GPS状态
参数  ：无
返回值：GPS经纬度，定位状态，速度
]]
local function getgps()
	local t = {}
	print("getgps:",gps.getgpslocation(),gps.getgpscog(),gps.getgpsspd())
	t.fix = gps.isfix() or nvm.get("workmod")=="LONGPS"
	if gps.isfix() then
		t.lng,t.lat = smatch(gps.getgpslocation(),"[EW]*,(%d+%.%d+),[NS]*,(%d+%.%d+)")
	elseif nvm.get("workmod")=="LONGPS" or (nvm.get("gpsleep") and nvm.get("workmod" == "GPS")) then
		t.lng,t.lat = manage.getlastgps()
	end
	t.lng,t.lat = t.lng or "",t.lat or ""
	t.cog = gps.getgpscog()
	t.spd = gps.getgpsspd()

	return t
end

--[[
函数名：getgpstat
功能  ：获取GPS可见卫星个数
参数  ：无
返回值：GPS可见卫星个数
]]
local function getgpstat()
	local t = {}
	t.satenum = gps.getgpssatenum()
	return t
end

local function getfncpara()
	local n1 = (manage.GUARDFNC and 1 or 0) + (manage.HANDLEPWRFNC and 1 or 0)*2 + (manage.MOTORPWRFNC and 1 or 0)*4 + (manage.RMTPWRFNC and 1 or 0)*8
	n1 = n1 + (manage.BUZZERFNC and 1 or 0)*16
	local n2,n3,n4,n5,n6,n7,n8 = 0,0,0,0,0,0,0
	return pack.pack("bbbbbbbb",n1,n2,n3,n4,n5,n6,n7,n8)
end

local tget = {
	["VERSION"] = function() return _G.VERSION end,
	PROJECTID = function() return _G.PRJID end,
	PROJECT = function() return 1 end,
	HEART = function() 				
				local v = nvm.get("heart")
				return v
			end,
	IMEI = misc.getimei,
	IMSI = sim.getimsi,
	ICCID = sim.geticcid,
	RSSI = net.getrssi,
	MNC = function() return tonumber(net.getmnc()) end,
	MCC = function() return tonumber(net.getmcc()) end,
	CELLID = function() return tonumber(net.getci(),16) end,
	LAC = function() return tonumber(net.getlac(),16) end,
	CELLINFO = net.getcellinfo,
	CELLINFOEXT = net.getcellinfoext,
	TA = net.getta,
	STATUS = getstatus,
	GPS = getgps,
	GPSTAT = getgpstat,
	FNCPARA = getfncpara,
	BTMAC = function() return common.hexstobins(string.gsub(nvm.get("mac"),":","")) end,
	GPSLEEP = function() return nvm.get("gpsleep") end
}
local function getf(id)
	assert(tget[id] ~= nil,"getf nil id:" .. id)
	return tget[id]()
end

protoair.reget(getf)

local levt,lval,lerrevt,lerrval = "","","",""

--[[
函数名：chgalmrpt
功能  ：低电告警上报
参数  ：无
返回值：无
]]
local function chgalmrpt()
	if not chg.getcharger() and chgalm then
		chgalm = false
		sys.dispatch("ALM_IND","CHG")
		heart("LIDLE")
	end
end

--[[
函数名：shkalmrpt
功能  ：震动告警上报
参数  ：无
返回值：无
]]
local function shkalmrpt()
	print("shkalmrpt",nvm.get("guard"),shkalm)
	if nvm.get("guard") and shkalm then
		shkalm = false
		sys.dispatch("ALM_IND","SHK")
		heart()
		startalmtimer("SHK",true)
	end
end

function almtimerfnc(tag)
	print("almtimerfnc",tag)
	local val = nvm.get("guard")
	if tag == "CHG" then
		chgalm = val
		chgalmrpt()
	elseif tag == "SHK" then
		shkalm = val
	end
end

function startalmtimer(tag,val)
	print("startalmtimer",tag,val,nvm.get("guard"))
	if nvm.get("guard") then
		if val then
			sys.timer_start(almtimerfnc,nvm.get("almfreq")*60000+5000,tag)
		end
	end
end

local function stopalmtimer(tag)
	print("stopalmtimer",tag)
	sys.timer_stop(almtimerfnc,tag)
end

local function alminit()
	print("alminit",nvm.get("guard"))
	local val = nvm.get("guard")
	chgalm,shkalm = val,val
	stopalmtimer("CHG")
	stopalmtimer("SHK")
end

--[[
函数名：qrylocfnc
功能  ：主动定位
参数  ：无
返回值：无
]]
local function qrylocfnc()
	locrpt("QRYLOC")
end

--[[
函数名：preloc
功能  ：定时上报定位处理
参数  ：无
返回值：无
]]
local function preloc()
	print("preloc",locshk)
	if locshk == "SHK" then
		loc()
	end
end

local function loctimerfnc()
	if cell.move() then locshk = "SHK" end
	print("loctimerfnc",locshk)
	if locshk == "SIL" then	startloctimer() end
	preloc()
end

--[[
函数名：startloctimer
功能  ：定时上报定时器
参数  ：无
返回值：无
]]
function startloctimer()
	print("startloctimer",gps.isfix(),nvm.get("workmod"),nvm.get("gpsleep"),nvm.get("rptfreq"))
	if not gps.isfix() and nvm.get("workmod") == "GPS" and not nvm.get("gpsleep") then
		sys.timer_start(loctimerfnc,600*1000)
	else
		sys.timer_start(loctimerfnc,nvm.get("rptfreq")*1000)
	end
end

local function entopic(t)
	return "/v"..verno.."/device/"..tget["IMEI"]().."/"..t
end

--[[
函数名：starthearttimer
功能  ：心跳上报定时器
参数  ：无
返回值：无
]]
local function starthearttimer()
	sys.timer_start(heart,nvm.get("heart")*1000)
end

local function removepast(tbl)
    local tmp ={}	
    tmp = tbl
	
    local i = 1
    while i <= #tmp do
        local val = tmp [i].timeloc
        if os.difftime(os.time(),val) > 3600 then
            table.remove(tmp,i)
         else
            i = i + 1
         end
     end
	 
    return tmp
end

function savehistgps()
	local p = {}	
	if getgps().fix then
		p.lng = getgps().lng
		p.lat = getgps().lat
		p.timeloc = os.time()
		table.insert(histloc,{lng=p.lng,lat=p.lat,timeloc=p.timeloc})	
	end
	table.sort(histloc,function(a,b) return tonumber(a.timeloc)<tonumber(b.timeloc) end )
	histloc = removepast(histloc)
end

--[[
函数名：locrpt
功能  ：定位信息上报后台
参数  ：定位模式
返回值：无
]]
function locrpt(r,w)
	print("locrpt",mqttconn)
	if not mqttconn then return end
	if (nvm.get("workmod") == "LONGIDLE" or nvm.get("workmod") == "ONEYIDLE") and r ~= "LIDLE" then return end
	local id,mod,extyp = protoair.LBS3,r or nvm.get("fixmod")
	if mod == "LBS" then
		id = nvm.get("lbstyp")==1 and protoair.LBS1 or protoair.LBS3
	elseif mod == "GPS" or mod == "LIDLE" then
		id = gps.isfix() and (nvm.get("gpslbsmix") and protoair.GPSLBS1 or protoair.GPS) or (nvm.get("lbstyp")==1 and protoair.LBS1 or (nvm.get("gpslbsmix") and protoair.GPSLBS1 or protoair.LBS3))
	elseif mod == "QRYLOC" then
		id = protoair.GPSLBSWIFIEXT
		extyp = protoair.QRYPOS
	end	
		id = protoair.GPSLBS1
	print("locrpt",gps.isfix(),gps.is3dfix(),id,w,r,#histloc)
	local p = {}
	p.lbs1 = tget["LAC"]().."@"..tget["CELLID"]()
	p.lbs2 = tget["CELLINFOEXT"]()
	if #histloc > 0 then
		p.gpsfix = 	true
		p.gps = histloc[1].lng.."@"..histloc[1].lat
	else
		p.gpsfix = getgps().fix
		p.gps = getgps().lng.."@"..getgps().lat
	end
	if gps.isfix() then
		manage.setlastgps(getgps().lng,getgps().lat)	
	else
		manage.setlastlbs2(p.lbs2,true)
	end
	mqttclient:publish(entopic("devdata"),protoair.pack(id,w,extyp),0,mqttpubcb,"MQTTPUBLOC")
end

function loc(r,p)
	print("loc",gps.isfix(),r)
	startloctimer()
	local isfix = gps.isfix()
	local is3dfix = gps.is3dfix()
	
	if  isfix and is3dfix then 
		local t = getgps()
		if manage.isgpsmove(t.lng,t.lat) then
			return locrpt(nil,p)
		else
			locshk = "SIL"
		end
	else
		if manage.islbs2move(tget["CELLINFOEXT"]()) then
			return locrpt(nil,p)
		else
			locshk = "SIL"
		end
	end
end

--[[
函数名：heart
功能  ：心跳上报后台
参数  ：心跳模式
返回值：无
]]
function heart(tag)
	starthearttimer()
	if not mqttconn then return end
	print("heart",nvm.get("workmod"),nvm.get("gpsleep"),nvm.get("autosleep"),tag)
	if nvm.get("workmod") == "LONGIDLE" and tag ~= "LIDLE" then return end
	if nvm.get("workmod") == "GPS" and nvm.get("gpsleep") and not nvm.get("autosleep") then
	else
		mqttclient:publish(entopic("devdata"),protoair.pack(protoair.HEART),0,mqttpubcb,"MQTTPUBHEART")
	end
end

--[[
函数名：enrptpara
功能  ：上报参数封包
参数  ：参数类型
返回值：无
]]
local function enrptpara(typ)
	local function enunsignshort(p)
		return pack.pack(">H",nvm.get(p))
	end	
	
	local proc =
	{
		rptfreq = {k=protoair.RPTFREQ,v=enunsignshort},
		almfreq = {k=protoair.ALMFREQ,v=enunsignshort},
		guard = {v=function() return schar(nvm.get("guard") and protoair.GUARDON or protoair.GUARDOFF) end},		
		fixmod = {v=function() return pack.pack("bb",protoair.FIXMOD,(nvm.get("fixmod")=="LBS") and 0 or ((nvm.get("fixmod")=="GPS") and 1 or 2)) end},
		workmod = {v=function() return pack.pack("bb",protoair.FIXMOD,(nvm.get("workmod")=="SMS") and 3 or ((nvm.get("workmod")=="GPS") and 4 or ((nvm.get("workmod")=="PWRGPS") and 5 or 6))) end},
		horn = {v=function() return schar(nvm.get("horn") and protoair.HORNON or protoair.HORNOFF) end},
	}
	if not proc[typ] then return "" end
	local ret = ""
	if proc[typ].k then ret = schar(proc[typ].k) end
	if proc[typ].v then ret = ret..proc[typ].v(typ) end
	return ret
end

local tpara,tparapend =
{
	"rptfreq","almfreq","guard","fixmod","workmod","horn"
},{}

--[[
函数名：rptpara
功能  ：上报参数到后台
参数  ：参数类型
返回值：无
]]
local function rptpara(typ)
	if nvm.get("workmod") == "SMS" and typ~="workmod" then return end
	print("rptpara",typ,tget["IMEI"](),#tparapend)
	if typ then
		if tget["IMEI"]() ~= "" then
			for k,v in pairs(tpara) do
				if typ == v then
					mqttclient:publish(entopic("devpararpt"),protoair.pack(protoair.RPTPARA,enrptpara(v)),1,mqttpubcb,"MQTTPUBRPTPARA")
				end
			end
		else
			local fnd
			for i=1,#tparapend do
				if tparapend[i] == typ then fnd = true break end
			end
			if not fnd then
				for k,v in pairs(tpara) do
					if v == typ then tparapend[#tparapend+1] = typ end
				end
			end
		end
	else
		for i=1,#tparapend do
			if tparapend[i]~="workmod" then
				rptpara(tparapend[i])
			end
		end
		tparapend = {}
	end
end

--[[
函数名：devinfo
功能  ：上报设备信息到后台
参数  ：无
返回值：无
]]
function devinfo()
	if not mqttconn then return end
	mqttclient:publish(entopic("devdata"),protoair.pack(protoair.INFO),0,mqttpubcb,"MQTTPUBINFO")
end

--[[
函数名：fixmodpara
功能  ：根据APP设置模式切换设备定位模式
参数  ：定位模式
返回值：无
]]
local function fixmodpara(p)
	local mod = p.val==8 and "LONGIDLE" or (p.val==4 and "GPS" or (p.val==9 and "ONEYIDLE" or "LONGPS"))
	print("fixmodpara mod",mod)
	return nvm.set("workmod",mod,"SVR")
end

--[[
函数名：setpara
功能  ：参数设置状态上报后台
参数  ：参数类型
返回值：无
]]
local function setpara(packet)
	local procer,result = {
		[protoair.RPTFREQ] = "rptfreq",
		[protoair.ALMFREQ] = "almfreq",		
		[protoair.GUARDON] = {k="guard",v=true},
		[protoair.GUARDOFF] = {k="guard",v=false},		
		[protoair.FIXMOD] = fixmodpara,
		[protoair.AUTOGUARDON] = {k="autoguard",v=true},
		[protoair.AUTOGUARDOFF] = {k="autoguard",v=false},
		[protoair.AUTOSLEEPON] = {k="autosleep",v=true},
		[protoair.AUTOSLEEPOFF] = {k="autosleep",v=false},
		[protoair.LOCRPON] = {k="locrp",v=true},
		[protoair.LOCRPOFF] = {k="locrp",v=false},
		[protoair.HORNON] = {k="horn",v=true},
		[protoair.HORNOFF] = {k="horn",v=false},		
	}
	if procer[packet.cmd] then
		local typ = type(procer[packet.cmd])
		if typ == "function" then
			result = procer[packet.cmd](packet)
		elseif typ == "table" then
			if type(procer[packet.cmd].k) == "function" then
				result = procer[packet.cmd].k(packet,procer[packet.cmd].v)
			else
				result = nvm.set(procer[packet.cmd].k,procer[packet.cmd].v,"SVR")
			end
		else
			result = nvm.set(procer[packet.cmd],packet.val,"SVR")
		end		
	end
	mqttclient:publish(entopic("devpararsp/"..(smatch(packet.topic,"devparareq/(.+)") or "")),protoair.pack(protoair.SETPARARSP,packet.cmd,schar(result and 1 or 0)),1,mqttpubcb,"MQTTPUBSETPARARSP")
end

local function sendsms(packet)
	if packet.coding == "UCS2" then
		local num,i = ""
		for i=1,#packet.num do
			print("sendsms",packet.num[i])
			if string.len(packet.num[i]) >= 5 and not string.match(num,packet.num[i]) then
				num = num..packet.num[i].."@"
			end
		end
		print("sendsms1",num)
		for i in string.gmatch(num,"(%d+)@") do
			sms.send(i,common.binstohexs(packet.data))
		end		
	end
end

--[[
函数名：deveventrsp
功能  ：设备被动处理的事件应答
参数  ：事件类型
返回值：无
]]
local function deveventrsp(packet)
	print("deveventrsp",packet.id)
	local evenrsp = "MQTTPUBDEVEVENTRSP"
	if packet.id == protoair.QRYLOC then
		evenrsp = "MQTTPUBDEVEVENTRSPQRYLOC"
	elseif packet.id == protoair.RESET then
		evenrsp = "MQTTPUBDEVEVENTRSPRESET"	
	end
	mqttclient:publish(entopic("deveventrsp/"..(smatch(packet.topic,"deveventreq/(.+)") or "")),protoair.pack(protoair.DEVEVENTRSP,packet.id,schar(1)),1,mqttpubcb,evenrsp)
end

--[[
函数名：qryloc
功能  ：主动定位应答
参数  ：事件类型
返回值：无
]]
local function qryloc(packet)
	if not gps.isactive(gps.TIMERORSUC,{cause="QRYLOC"}) then
		gps.open(gps.TIMERORSUC,{cause="QRYLOC",val=30,cb=qrylocfnc})
	end
	deveventrsp(packet)
	sys.dispatch("SVR_QRY_LOC_IND")	
end

local function restore(packet)
	sys.dispatch("SVR_RESTORE_IND")
	deveventrsp(packet)
end

--[[
函数名：devqrypararsp
功能  ：设备参数被动变化请求
参数  ：packet，rsp
返回值：无
]]
local function devqrypararsp(packet,rsp)
	mqttclient:publish(entopic("deveventrsp/"..smatch(packet.topic,"deveventreq/(.+)")),protoair.pack(protoair.DEVEVENTRSP,packet.id,schar(packet.val)..rsp),1,mqttpubcb,"MQTTPUBDEVEVENTRSP")
end

local function qrypara(packet)
	local procer,rsp = {
		[protoair.VER] = function() return _G.PROJECT.."_".._G.VERSION end,
	}
	if procer[packet.val] then
		rsp = procer[packet.val]()
	end
	if rsp then devqrypararsp(packet,rsp) end
end

local function btctl(packet)
	sys.dispatch("SVR_BT_CTL_REQ",packet)
	if packet.val==protoair.BTCLS or packet.val==protoair.BTOPN then
		devqrypararsp(packet,schar(1)..common.hexstobins(string.gsub(nvm.get("mac"),":","")))
	end
end

--[[
函数名：datetime
功能  ：设置设备时间
参数  ：后台上报时间
返回值：无
]]
local setclked
local function datetime(p)
	if not setclked then
		misc.setclock(p)
		setclked = true
	end
	sntinfo = true
	sys.timer_stop(sndinfo)
end

local function smpset(packet)	
	local procer,result = {
		[protoair.DATETIME] = datetime,
	}
	if procer[packet.cmd] then
		local typ = type(procer[packet.cmd])
		if typ == "function" then
			procer[packet.cmd](packet)
		end		
	end
end

local cmds = {
	[protoair.SETPARA] = setpara,
	[protoair.SENDSMS] = sendsms,
	[protoair.DIAL] = dial,
	[protoair.QRYLOC] = qryloc,
	[protoair.RESET] = deveventrsp,
	[protoair.POWEROFF] = deveventrsp,	
	[protoair.RESTORE] = restore,
	[protoair.QRYPARA] = qrypara,
	[protoair.BTCTL] = btctl,
	[protoair.SMPSET] = smpset,
}

local function mqttconncb(v)
	--print("mqttconncb",common.binstohexs(v))
	mqttdup.ins("CONN",v)
end

function mqttsubcb(v)
	mqttdup.ins("SUB",mqtt.pack(mqtt.SUBSCRIBE,v),v.seq)
end

local function mqttdupcb(v)
	mqttdup.rsm(v)
end

local function mqttdiscb()
	socket.disconnect(SCK_IDX)
end

local function mqttpublocb(v,r)
	startloctimer()
	locshk = "SIL"
	
	if v.typ == protoair.GPSLBS1 then	
		if #histloc > 0 then
			print("#histloc",#histloc)
			if r then
				table.remove(histloc,1)
				rtos.sleep(2)
				--locrpt()
			else
				rtos.sleep(500)
				--locrpt()
				testnum = testnum + 1
			end		
		end
	end
	
	if r then
		sys.dispatch("ITV_WAKE_SNDSUC")
		starthearttimer()	
		firstloc = true
		
		local function lbs1cb()
			manage.setlastlbs1(smatch(v.para.lbs1,"(%d+)@"),smatch(v.para.lbs1,"@(%d+)"),true)
		end
		
		local function lbs2cb()
			manage.setlastlbs2(v.para.lbs2,true)
		end
		
		local function gpscb()
			manage.setlastgps(smatch(v.para.gps,"([%.%d]+)@"),smatch(v.para.gps,"@([%.%d]+)"))
			manage.setlastlbs1(smatch(v.para.lbs1,"(%d+)@"),smatch(v.para.lbs1,"@(%d+)"))
			manage.setlastlbs2(v.para.lbs2)
		end
		
		local function gpslbscb()
			if v.para.gpsfix then manage.setlastgps(smatch(v.para.gps,"([%.%d]+)@"),smatch(v.para.gps,"@([%.%d]+)")) end
			manage.setlastlbs2(v.para.lbs2,not v.para.gpsfix)
		end
		
		local function gpslbswificb()
			if v.para.gpsfix then manage.setlastgps(smatch(v.para.gps,"([%.%d]+)@"),smatch(v.para.gps,"@([%.%d]+)")) end
			if v.para.wifi and #v.para.wifi > 0 then
				manage.setlastwifi(v.para.wifi)
				manage.setlastwifictl(v.para.wifi)
			end
			manage.setlastlbs2(v.para.lbs2,not (v.para.gpsfix or (v.para.wifi and #v.para.wifi > 0)))
		end
		
		local procer =
		{
			[protoair.LBS1] = lbs1cb,
			[protoair.LBS2] = lbs2cb,
			[protoair.LBS3] = lbs2cb,
			[protoair.GPS] = gpscb,
			[protoair.GPSLBS] = gpslbscb,
			[protoair.GPSLBS1] = gpslbscb,
			[protoair.GPSLBSWIFIEXT] = gpslbswificb,
		}
		if procer[v.typ] then procer[v.typ]() end
	end
end

local function mqttpubheartcb(v,r)
	--[[if nvm.get("sleep") then
		sys.dispatch("ITV_SLEEP_REQ")
	else]]if nvm.get("gpsleep") then
		--sys.dispatch("ITV_GPSLEEP_REQ")
		end
	-- else
		if r then starthearttimer() end
	--end
	if r then sys.dispatch("ITV_WAKE_SNDSUC") end
end

function mqttpubrptparacb(usertag,result)
	print("mqttpubrptparacb",usertag,result)
	--mqttdup.ins("PUBRPTPARA"..v.usr,mqtt.pack(mqtt.PUBLISH,v),v.seq)
end

function mqttpubsetpararspcb(v)
	print("mqttpubsetpararspcb",v.usr)
	mqttdup.ins("PUBSETPARARSP"..v.usr,mqtt.pack(mqtt.PUBLISH,v),v.seq)
end

function mqttpubdeveventrspcb(v)
	print("mqttpubdeveventrspcb",v.usr)
	mqttdup.ins("PUBDEVEVENTRSP"..v.usr,mqtt.pack(mqtt.PUBLISH,v),v.seq)
end

local sndcbs =
{
	MQTTCONN = mqttconncb,
	MQTTSUB = mqttsubcb,
	MQTTDUP = mqttdupcb,
	MQTTDISC = mqttdiscb,
	MQTTPUBLOC = mqttpublocb,
	MQTTPUBHEART = mqttpubheartcb,
	MQTTPUBRPTPARA = mqttpubrptparacb,
	MQTTPUBSETPARARSP = mqttpubsetpararspcb,
	MQTTPUBDEVEVENTRSP = mqttpubdeveventrspcb,
}

--[[
函数名：mqttpubcb
功能  ：publish发送结果的回调函数
参数  ：
		usertag：调用mqttclient:publish时传入的usertag
		result：true表示发送成功，false或者nil发送失败
返回值：无
]]
function mqttpubcb(usertag,result)
	print("mqttpubcb",usertag,result)
	if  usertag == "MQTTPUBDEVEVENTRSPRESET" then
		sys.timer_start(dbg.restart,1000,"AIRTCPSVR")
	end
end

--[[
函数名：shkcntind
功能  ：传感器有效震动次数
参数  ：无
返回值：有效震动次数
]]
function shkcntind()
	print("shkcntind",shkcnt)
	shkcnt = shkcnt + 1
end

--[[
函数名：shkind
功能  ：传感器震动消息处理
参数  ：无
返回值：true
]]
local function shkind()
	print("shkind",locshk)
	local oldflg = locshk
	locshk = "SHK"
	if oldflg == "TMOUT" then
		preloc()
	end
	return true
end

--[[
函数名：chgind
功能  ：充电消息处理
参数  ：上报消息
返回值：true
]]
local function chgind(evt)
	if nvm.get("workmod") == "SMS" then return true end
	if evt ~= "CHARGER" and evt ~= "BAT_LOW" then return true end
	chgalmrpt()
	if chg.getcharger() then
		chgalm = false
		stopalmtimer("CHG")
	elseif evt == "BAT_LOW" and not sys.timer_is_active(almtimerfnc,"CHG") then
		startalmtimer("CHG",nvm.get("guard"))
	end
	return true
end

local function delaysmsmod()
	socket.clrsnding(SCK_IDX)
	link.shut()
	cconnect()
end

local function workmodind(r,rpt)
	sys.timer_stop(delaysmsmod)
	locshk,firstloc,firstgps = "SIL"
	chgalm,shkalm = true,true
	alminit()
	manage.resetlastloc()
	if not rpt and r~="SVR" then
		nvm.set("workmodpend",true)
	end
end

--[[
函数名：gpstaind
功能  ：GPS定位成功后发送定位信息
参数  ：GPS消息类型
返回值：true
]]
local function gpstaind(evt)
	print("gpstaind evt",evt)
	if evt == gps.GPS_LOCATION_SUC_3D_EVT then
		startloctimer()
		locshk = "SHK"		
	end
	return true
end

local function parachangeloc()
	locshk = "SHK"
	preloc()
end

--[[
函数名：parachangeind
功能  ：参数变化消息处理
参数  ：nvm.set设置参数
返回值：true
]]
local function parachangeind(k,v,r)
	print("parachangeind",k,r)
	local rpt
	if r ~= "SVR" and nvm.get("workmod") ~= "SMS" then
		rpt = rptpara(k)
	end
	local procer =
	{
		rptfreq = parachangeloc,
		almfreq = alminit,
		guard = alminit,
		workmod = workmodind,
		fixmod = parachangeloc,
		heart = devinfo,
		gpsleep = heart,		
	}
	if procer[k] then procer[k](r,rpt) end
	return true
end

local function tparachangeind(k,kk,v,r)
	if r ~= "SVR" then
		rptpara(k)
	end
	return true
end

local pwoffcause = 0

function getpwoffcause()
	return pwoffcause
end

--[[
函数名：slporpoweroffreq
功能  ：上报关机报文
参数  ：关机模式
返回值：true
]]
local function slporpoweroffreq(tag)
	print("slporpoweroffreq tag",tag)
	if tag == "NORMAL" then 
		pwoffcause = 0
	elseif tag == "BLOW" then 
		pwoffcause = 1	
	end
	if heart() then
		sys.timer_start(sys.dispatch,5000,"SLEEP_OR_POWEROFF_CNF",tag)
	else
		sys.dispatch("SLEEP_OR_POWEROFF_CNF",tag)
	end
end

--[[
函数名：mqttstatus
功能  ：mqtt状态
参数  ：无
]]
local function mqttstatus()
	print("statustest",mqttclient:getstatus())
	if "CONNECTED" == mqttclient:getstatus() then
		mqttconn = true
	else
		mqttconn = false	
	end
end

function getsta()
	mqttstatus()
	return mqttconn
end
--[[
函数名：subackcb
功能  ：MQTT SUBSCRIBE之后收到SUBACK的回调函数
参数  ：
		usertag：调用mqttclient:subscribe时传入的usertag
		result：true表示订阅成功，false或者nil表示失败
返回值：无
]]
local function subackcb(usertag,result)
	print("subackcb",usertag,result)
	devinfo()
	loc()
end
--[[
函数名：rcvmessage
功能  ：收到PUBLISH消息时的回调函数
参数  ：
		topic：消息主题（gb2312编码）
		payload：消息负载（原始编码，收到的payload是什么内容，就是什么内容，没有做任何编码转换）
		qos：消息质量等级
返回值：无
]]
local function rcvmessagecb(topic,payload,qos)
	print("rcvmessagecb",topic,payload,qos)
	local packet = protoair.unpack(payload)
	if packet and packet.id and cmds[packet.id] then
		packet.topic = topic
		print("packet.id",packet.id)
		cmds[packet.id](packet)
	end
end
--[[
函数名：discb
功能  ：MQTT连接断开后的回调
参数  ：无		
返回值：无
]]
local function discb()
	print("discb")
	--20秒后重新建立MQTT连接
	--sys.timer_start(connect,20000)
end
--[[
函数名：disconnect
功能  ：断开MQTT连接
参数  ：无		
返回值：无
]]
local function disconnect()
	mqttclient:disconnect(discb)
end
--[[
函数名：connectedcb
功能  ：MQTT CONNECT成功回调函数
参数  ：无		
返回值：无
]]
local function connectedcb()
	print("connectedcb")
	mqttconn = true
	sys.dispatch("LINKAIR_CONNECT_SUC")
	--订阅主题
	mqttclient:subscribe({{topic=entopic("devparareq/+"),qos=1},{topic=entopic("deveventreq/+"),qos=1},{topic=entopic("set"),qos=1}}, subackcb, "subscribetest")
	--注册事件的回调函数，MESSAGE事件表示收到了PUBLISH消息
	mqttclient:regevtcb({MESSAGE=rcvmessagecb})
	--发布一条心跳包消息
	heart()
end
--[[
函数名：connecterrcb
功能  ：MQTT CONNECT失败回调函数
参数  ：
		r：失败原因值
			1：Connection Refused: unacceptable protocol version
			2：Connection Refused: identifier rejected
			3：Connection Refused: server unavailable
			4：Connection Refused: bad user name or password
			5：Connection Refused: not authorized
返回值：无
]]
local function connecterrcb(r)
	print("connecterrcb",r)
end
function connect()
	--连接mqtt服务器
	--mqtt lib中，如果socket一直重连失败，默认会自动重启软件
	--注意sckerrcb参数，如果打开了注释掉的sckerrcb，则mqtt lib中socket一直重连失败时，不会自动重启软件，而是调用sckerrcb函数
	mqttclient:connect(misc.getimei(),600,"user","password",connectedcb,connecterrcb--[[,sckerrcb]])
end
--mqttclient = mqtt.create(PROT,ADDR,PORT--[[,"3.1.1"]])
--[[
函数名：imeirdy
功能  ：IMEI读取成功，成功后，才去创建mqtt client，连接服务器，因为用到了IMEI号
参数  ：无		
返回值：无
]]
local function imeirdy()
	--创建一个mqtt client，默认使用的MQTT协议版本是3.1，如果要使用3.1.1，打开下面的注释--[[,"3.1.1"]]即可
	mqttclient = mqtt.create(PROT,ADDR,PORT--[[,"3.1.1"]])
	--配置遗嘱参数,如果有需要，打开下面一行代码，并且根据自己的需求调整will参数
	--mqttclient:configwill(1,0,0,"/willtopic","will payload")
	--查询client状态测试
	--sys.timer_loop_start(statustest,1000)
	connect()
end
local procer =
{
	DEV_SHK_IND = shkind,
	DEV_CHG_IND = chgind,
	[gps.GPS_STATE_IND] = gpstaind,
	PARA_CHANGED_IND = parachangeind,
	TPARA_CHANGED_IND = tparachangeind,
	IMEI_READY = imeirdy,
	SLEEP_OR_POWEROFF_REQ = slporpoweroffreq,
	RESTART_REQ = heart,
	SHKCNT_VALIDSHK_IND = shkcntind 
}

sys.regapp(procer)
net.startquerytimer()
