require"pincfg"
module(...,package.seeall)

--[[
��������print
����  ����ӡ�ӿڣ����ļ��е����д�ӡ�������testǰ׺
����  ����
����ֵ����
]]
local function print(...)
	_G.print("test",...)
end

-------------------------PIN8���Կ�ʼ-------------------------
local pin8flg = true
--[[
��������pin8set
����  ������PIN8���ŵ������ƽ��1�뷴תһ��
����  ����
����ֵ����
]]
local function pin8set()
	pins.set(pin8flg,pincfg.PIN8)
	pin8flg = not pin8flg
end
--����1���ѭ����ʱ��������PIN8���ŵ������ƽ
sys.timer_loop_start(pin8set,1000)
-------------------------PIN8���Խ���-------------------------


-------------------------PIN19���Կ�ʼ-------------------------
local pin19flg = true
--[[
��������pin19set
����  ������PIN19���ŵ������ƽ��1�뷴תһ��
����  ����
����ֵ����
]]
local function pin19set()
	pins.set(pin19flg,pincfg.PIN19)
	pin19flg = not pin19flg
end
--����1���ѭ����ʱ��������PIN19���ŵ������ƽ
sys.timer_loop_start(pin19set,1000)
-------------------------PIN19���Խ���-------------------------


-------------------------PIN17���Կ�ʼ-------------------------
--[[
��������pin17get
����  ����ȡPIN17���ŵ������ƽ
����  ����
����ֵ����
]]
local function pin17get()
	local v = pins.get(pincfg.PIN17)
	print("pin17get",v and "low" or "high")
end
--����1���ѭ����ʱ������ȡPIN17���ŵ������ƽ
sys.timer_loop_start(pin17get,1000)
-------------------------PIN17���Խ���-------------------------
