require"pins"
module(...,package.seeall)

--���������˿�Դģ�������п�����GPIO�����ţ�ÿ������ֻ����ʾ��Ҫ
--�û�����������Լ������������޸�
--Air800������GPIO��֧���ж�

--pinֵ�������£�
--pio.P0_XX����ʾGPIOXX������pio.P0_15����ʾGPIO15
--pio.P1_XX����ʾGPIO(XX+32)������pio.P1_2����ʾGPIO34

--dirֵ�������£�Ĭ��ֵΪpio.OUTPUT����
--pio.OUTPUT����ʾ�������ʼ��������͵�ƽ
--pio.OUTPUT1����ʾ�������ʼ��������ߵ�ƽ
--pio.INPUT����ʾ���룬��Ҫ��ѯ����ĵ�ƽ״̬
--pio.INT����ʾ�жϣ���ƽ״̬�����仯ʱ���ϱ���Ϣ�����뱾ģ���intmsg����

--validֵ�������£�Ĭ��ֵΪ1����
--valid��ֵ��pins.lua�е�set��get�ӿ����ʹ��
--dirΪ���ʱ�����pins.set�ӿ�ʹ�ã�pins.set�ĵ�һ���������Ϊtrue��������validֵ��ʾ�ĵ�ƽ��0��ʾ�͵�ƽ��1��ʾ�ߵ�ƽ
--dirΪ������ж�ʱ�����get�ӿ�ʹ�ã�������ŵĵ�ƽ��valid��ֵһ�£�get�ӿڷ���true�����򷵻�false
--dirΪ�ж�ʱ��cbΪ�ж����ŵĻص����������жϲ���ʱ�����������cb�������cb����������жϵĵ�ƽ��valid��ֵ��ͬ����cb(true)������cb(false)

--�ȼ���PIN8 = {pin=pio.P0_1,dir=pio.OUTPUT,valid=1}
--��7�����ţ�GPIO_1������Ϊ�������ʼ������͵�ƽ��valid=1������pins.set(true,PIN8),������ߵ�ƽ������pins.set(false,PIN8),������͵�ƽ
PIN7 = {pin=pio.P0_1}

--��8�����ţ�GPIO_0������Ϊ�������ʼ������ߵ�ƽ��valid=0������pins.set(true,PIN9),������͵�ƽ������pins.set(false,PIN9),������ߵ�ƽ
PIN8 = {pin=pio.P0_0,dir=pio.OUTPUT1,valid=0}

--�������ú����PIN7����
PIN5 = {pin=pio.P0_3}
PIN6 = {pin=pio.P0_2}
PIN29 = {pin=pio.P0_29}
PIN28 = {pin=pio.P0_31}
PIN27 = {pin=pio.P0_30}
PIN20 = {pin=pio.P0_10}
PIN19 = {pin=pio.P0_8}
PIN21 = {pin=pio.P0_11}
PIN22 = {pin=pio.P0_12}


local function pin4cb(v)
	print("pin29cb",v)
end
--��4�����ţ�GPIO_6������Ϊ�жϣ�valid=1
--intcb��ʾ�жϹܽŵ��жϴ��������������ж�ʱ�����Ϊ�ߵ�ƽ����ص�intcb(true)�����Ϊ�͵�ƽ����ص�intcb(false)
--����pins.get(PIN4)ʱ�����Ϊ�ߵ�ƽ���򷵻�true�����Ϊ�͵�ƽ���򷵻�false
PIN4 = {pin=pio.P0_6,dir=pio.INT,valid=1,intcb=pin4cb}


--��17�����ţ�GPIO_13������Ϊ���룻valid=0
--����pins.get(PIN17)ʱ�����Ϊ�ߵ�ƽ���򷵻�false�����Ϊ�͵�ƽ���򷵻�true
PIN17 = {pin=pio.P0_13,dir=pio.INPUT,valid=0}

PIN18 = {pin=pio.P0_9}
PIN47 = {pin=pio.P1_2}
PIN37 = {pin=pio.P0_14}
PIN38 = {pin=pio.P0_15}
PIN39 = {pin=pio.P0_16}
PIN40 = {pin=pio.P0_17}
PIN41 = {pin=pio.P0_18}

pins.reg(PIN4,PIN5,PIN6,PIN7,PIN8,PIN29,PIN28,PIN27,PIN20,PIN19,PIN21,PIN22,PIN17,PIN18,PIN47,PIN37,PIN38,PIN39,PIN40,PIN41)