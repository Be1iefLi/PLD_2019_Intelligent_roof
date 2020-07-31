
import json
import network
import machine
from umqtt import MQTTClient
from machine import Pin, SPI

#SPI
spi = SPI(2, polarity = 1, phase = 1, sck = Pin(18), mosi = Pin(23), miso = Pin(19), cs = Pin(5))

def regRead(address):
  buf = bytearray(1)
  buf[0] = address
  spi.select()
  spi.write(buf)
  buf = spi.read(1)
  spi.deselect()
  v = buf[0]
  return v

def regWrite(address, value):
  buf = bytearray(3)
  buf[0] = address | 0x80
  buf[1] = value
  buf[2] = 0
  spi.select()
  v = spi.write(buf)
  spi.deselect()
  return v

#WIFI
wifi = network.WLAN(network.STA_IF)  

#MQTT
Service = 'xxx.xxx.xxx.xxx'
Client_ID = 'PLD'

class Environment(object):
    Temperature = 0
    Humidity = 0
    
Outside = Environment()

def mqtt_callback(topic, msg):
    #AutoControl
    print('{}'.format(topic))
    print('{}'.format(msg))
    
mqtt = MQTTClient(Client_ID, Service)
mqtt.set_callback(mqtt_callback)

#Timer
Time_Period = 2000

def timer_callback(Timer):
    #MQTT Check
    mqtt.check_msg()
    #Sensors
    Outside.Temperature = int(regRead(0x10))
    Outside.Humidity = int(regRead(0x11))
    Ill1 = int(regRead(0x12))
    Ill2 = int(regRead(0x13))
    Illumination1 = int((Ill1 * 128 + Ill2) / 1.2)
    Ill1 = int(regRead(0x14))
    Ill2 = int(regRead(0x15))
    Illumination2 = int((Ill1 * 128 + Ill2) / 1.2)
    #Outside
    mqtt.publish('Out_Temperature','{}'.format(Outside.Temperature))
    mqtt.publish('Out_Humidity','{}'.format(Outside.Humidity))
    #Illumination
    mqtt.publish('Illumination1','{}'.format(Illumination1))
    mqtt.publish('Illumination2','{}'.format(Illumination2))


t1 = machine.Timer(1)

def do_connect():
    # 尝试读取配son,方式来存储WIFI配置
    # wifi_config.json在根目录下
    # 若不是初次运行,则将文件中的内容读取并加载到     with open('wifi_config.json','r') as f:
    try:
        with open('wifi_config.json','r') as f:
            config = json.loads(f.read())
    # 若初次运行,则将进入excpet,执行配置文件的创建        
    except:
        essid = input('wifi name:') # 输入essid
        password = input('wifi passwrod:') # 输入password
        config = dict(essid=essid, password=password) # 创建字典
        with open('wifi_config.json','w') as f:
            f.write(json.dumps(config)) # 将字典序列化为json字符串,存入wifi_config.json
    #以下为正常的WIFI连接流程        
    if not wifi.isconnected(): 
        print('connecting to network...')
        wifi.active(True) 
        wifi.connect(config['essid'], config['password']) 
        while not wifi.isconnected():
            pass 
    print('network config:', wifi.ifconfig()) 
    
def MQTT_Init():
    mqtt.connect()
    print('mqtt connect')
    
    mqtt.subscribe('Roof_Speed')
    mqtt.publish('Roof_Speed1','1')
    print('MQTT_subscibe:Roof_Speed')
    
    mqtt.subscribe('Roof_Open')
    mqtt.publish('Roof_Open1','0')
    print('MQTT_subscibe:Roof_Open')
    
    mqtt.subscribe('Auto')
    print('MQTT_subscibe:Auto')
    mqtt.publish('Auto1','Off')
    

if __name__ == '__main__':
    do_connect()
    MQTT_Init()
    t1.init(period = Time_Period, callback = timer_callback)



