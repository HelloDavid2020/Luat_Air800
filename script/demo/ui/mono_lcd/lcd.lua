--[[
ģ�����ƣ�lcd
ģ�鹦�ܣ�lcd����ӿ�
ģ������޸�ʱ�䣺2017.08.17
]]

require"lcd_ssd1306"
--require"lcd_st7567"
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
