--[[
ģ�����ƣ�logo
ģ�鹦�ܣ���ʾ������ӭ���logoͼƬ
ģ������޸�ʱ�䣺2017.08.08
]]

module(...,package.seeall)

require"prompt"
require"idle"

--���LCD��ʾ������
disp.clear()
--������16,0λ�ÿ�ʼ��ʾ"��ӭʹ��Luat"
disp.puttext("��ӭʹ��Luat",16,0)
--������41,18λ�ÿ�ʼ��ʾͼƬlogo.bmp
disp.putimage("/ldata/logo.bmp",41,18)
--ˢ��LCD��ʾ��������LCD��Ļ��
disp.update()

--5��󣬴���ʾ�򴰿ڣ���ʾ"3�������������"
--��ʾ�򴰿ڹرպ��Զ������������
sys.timer_start(prompt.open,5000,"3���","�����������",nil,idle.open)