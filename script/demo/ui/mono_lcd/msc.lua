--[[
ģ�����ƣ�msc
ģ�鹦�ܣ�������������
ģ������޸�ʱ�䣺2017.08.14
]]

module(...,package.seeall)

--LCD�ֱ��ʵĿ�Ⱥ͸߶�(��λ������)
WIDTH,HEIGHT = 128,64
--1��ASCII�ַ����Ϊ8���أ��߶�Ϊ16���أ����ֿ�Ⱥ͸߶ȶ�Ϊ16����
CHAR_WIDTH = 8

--[[
��������getxpos
����  �������ַ���������ʾ��X����
����  ��
		str��string���ͣ�Ҫ��ʾ���ַ���
����ֵ��X����
]]
function getxpos(str)
	return (WIDTH-string.len(str)*CHAR_WIDTH)/2
end
