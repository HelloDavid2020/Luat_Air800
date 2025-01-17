--[[
模块名称：模块生产功能测试
模块功能：支持IMEI读写、SN读写、SIM卡测试、信号强度测试、GPIO测试、音频测试
模块最后修改时间：2017.05.24
]]

require"misc"
require"net"
require"sim"
require"pm"

module(...,package.seeall)

local UART_ID = 1
local smatch,slen = string.match,string.len
local waitimeirst,waitsnrst,csqshreshold
local tgpio = {}

local function print(...)
	_G.print("factory1",...)
end

local function wake()	
	--sys.timer_start(pm.sleep,300000,"factory")
end

local function rsp(s)
	print("rsp",s)
	--wake()
	uart.write(UART_ID,s)
end

local function imeicb(suc)
	print("imeicb",suc)
	rsp("\r\nAT+WIMEI\r\n"..(suc and "OK" or "ERROR").."\r\n")
end

local function sncb(suc)
	print("sncb",suc)
	rsp("\r\nAT+WISN\r\n"..(suc and "OK" or "ERROR").."\r\n")
end

local function stoptimer(s)
	sys.timer_stop(loopqry,s)
	sys.timer_stop(looptimeout,s)
end

function loopqry(s)
	print("loopqry",s,sim.getstatus(),net.getstate(),net.getrssi(),csqshreshold)
	if s=="SIM" then
		if sim.getstatus() then
			stoptimer(s)
			rsp("\r\nAT+SIM\r\nOK\r\n")
		end
	elseif s=="CREG" then
		if net.getstate()=="REGISTERED" then
			stoptimer(s)
			rsp("\r\nAT+CREG\r\nOK\r\n")
		end
	elseif s=="CSQ" then
		net.csqquery()
		if net.getrssi()>=csqshreshold then
			stoptimer(s)
			rsp("\r\nAT+CSQ\r\nOK\r\n")
		end
	end
end

function looptimeout(s)
	print("looptimeout",s)
	sys.timer_stop(loopqry,s)
	if s=="SIM" then
		rsp("\r\nAT+SIM\r\nERROR\r\n")
	elseif s=="CREG" then
		rsp("\r\nAT+CREG\r\nERROR\r\n")
	elseif s=="CSQ" then
		rsp("\r\nAT+CSQ\r\n"..net.getrssi().."\r\nERROR\r\n")
	end
end

local adc0opn,adc1opn
local uart2close
local function proc(item)
	local s = string.upper(item)
	print("proc",s,waitimeirst,waitsnrst)
	if smatch(s,"AT%+WIMEI=") then
		waitimeirst = true
		misc.setimei(smatch(item,"=\"(.+)\""),imeicb)		
	elseif smatch(s,"AT%+CGSN") then
		local imei = misc.getimei()
		if waitimeirst or imei=="" then
			rsp("\r\nAT+CGSN?\r\nERROR\r\n")
		else			
			rsp("\r\nAT+CGSN?\r\n" .. imei .. "\r\nOK\r\n")
		end
	elseif smatch(s,"AT%+WISN=") then
		waitsnrst = true
		misc.setsn(smatch(item,"=\"(.+)\""),sncb)		
	elseif smatch(s,"AT%+WISN%?") then
		local sn = misc.getsn()
		if waitsnrst --[[ or sn=="" ]]then
			rsp("\r\nAT+WISN?\r\nERROR\r\n")
		else			
			rsp("\r\nAT+WISN?\r\n" .. sn .. "\r\nOK\r\n")
		end
	elseif smatch(s,"AT%+RESTART") then
		waitimeirst,waitsnrst = true,true
		uart.close(UART_ID)
		rtos.restart()
	elseif smatch(s,"AT%+SIM") then
		--if not uart2close then uart2close=true uart.close(2) end
		if sim.getstatus() then
			rsp("\r\nAT+SIM\r\nOK\r\n")
		else
			sys.timer_loop_start(loopqry,1000,"SIM")
			sys.timer_start(looptimeout,tonumber(smatch(item,"=(%d+)"))*1000,"SIM")
		end
	elseif smatch(s,"AT%+CREG") then
		if net.getstate()=="REGISTERED" then
			rsp("\r\nAT+CREG\r\nOK\r\n")
		else
			sys.timer_loop_start(loopqry,1000,"CREG")
			sys.timer_start(looptimeout,tonumber(smatch(item,"=(%d+)"))*1000,"CREG")
		end
	elseif smatch(s,"AT%+CSQ") then
		csqshreshold = tonumber(smatch(item,"=(%d+)"))
		if net.getrssi()>=csqshreshold then
			rsp("\r\nAT+CSQ\r\nOK\r\n")
		else
			sys.timer_loop_start(loopqry,1000,"CSQ")
			sys.timer_start(looptimeout,tonumber(smatch(item,",(%d+)"))*1000,"CSQ")
		end
	elseif smatch(s,"AT%+GPIO") then
		pmd.ldoset(6,pmd.LDO_VMMC)
		tgpio = {}
		local k,v,kk
		for v in string.gmatch(item,"(%d+)") do
			table.insert(tgpio,tonumber(v))
		end
		if #tgpio<2 then rsp("\r\nAT+GPIO\r\nERROR\r\n") return end
		net.setled(false)
		if wdt then wdt.close() end
		--第一步：全部配置为输入，读取输入电平，应该全部为低电平
		for k=1,#tgpio do
			pio.pin.close(tgpio[k])
			pio.pin.setdir(pio.INPUT,tgpio[k])
		end
		for k=1,#tgpio do
			if pio.pin.getval(tgpio[k])~=0 then
				rsp("\r\nAT+GPIO\r\n1_"..tgpio[k].."\r\nERROR\r\n")
				return
			end
		end
		
		--第二步：从第2个gpio开始，先设置为输出高，通过读第一个gpio的电平，验证输出是否正确
		--正确后，再配置为输入，然后读取本身的输入电平，应该为低电平
		for k=2,#tgpio do
			pio.pin.close(tgpio[k])
			pio.pin.setdir(pio.OUTPUT,tgpio[k])
			pio.pin.setval(1,tgpio[k])
			if pio.pin.getval(tgpio[1])~=1 then
				rsp("\r\nAT+GPIO\r\n2_"..tgpio[k].."\r\nERROR\r\n")
				return
			end
			for kk=2,#tgpio do
				if k~=kk then
					if pio.pin.getval(tgpio[kk])~=0 then
						rsp("\r\nAT+GPIO\r\n3_"..tgpio[kk].."\r\nERROR\r\n")
						return
					end
				end
			end
			pio.pin.close(tgpio[k])
			pio.pin.setdir(pio.INPUT,tgpio[k])
			if pio.pin.getval(tgpio[k])~=0 then
				rsp("\r\nAT+GPIO\r\n4_"..tgpio[k].."\r\nERROR\r\n")
				return
			end
		end
		rsp("\r\nAT+GPIO\r\nOK\r\n")
	elseif smatch(s,"AT%+ADC=%d") then
		local adcid = smatch(s,"AT%+ADC=(%d)")
		adcid = tonumber(adcid)
		if adcid==0 then
			if not adc0opn then adc0opn=true adc.open(adcid) end
		elseif adcid==1 then
			if not adc1opn then adc1opn=true adc.open(adcid) end
		else
			rsp("\r\nAT+ADC="..adcid.."\r\n65535\r\nOK\r\n")
			return
		end		
		local adcval,voltval = adc.read(adcid)
		if voltval and voltval~=0xFFFF then
			voltval = voltval/3
		end
		rsp("\r\nAT+ADC="..adcid.."\r\n"..voltval.."\r\nOK\r\n")
	elseif smatch(s,"AT%+AUDIO") then
		rsp("\r\nAT+AUDIO\r\nOK\r\n")
	end
end

local rdbuf = ""

--[[
函数名：read
功能  ：读取串口接收到的数据
参数  ：无
返回值：无
]]
local function read()
	local s
	while true do
		s = uart.read(UART_ID,"*l",0)
		if not s or string.len(s) == 0 then break end
		print("read",s)
		rdbuf = rdbuf..s
	end
	if smatch(rdbuf,"\r") then
		proc(rdbuf)
		rdbuf = ""
	end
end

uart.setup(UART_ID,115200,8,uart.PAR_NONE,uart.STOP_1)
sys.reguart(UART_ID,read)
pm.wake("factory1")
--wake()
