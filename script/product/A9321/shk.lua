--[[
ģ�����ƣ�shk
ģ�鹦�ܣ��𶯴������жϴ���
ģ������޸�ʱ�䣺2017.08.25
]]
module(...,package.seeall)

--[[
��������ind
����  ���𶯴������жϴ���
����  ���жϻص�����ֵ
����ֵ����
]]
function ind(data)
	print("shk.ind",data)
	if not data then  --�½����ж�
		print("shk.ind DEV_SHK_IND")
		sys.dispatch("DEV_SHK_IND")
	end
end
