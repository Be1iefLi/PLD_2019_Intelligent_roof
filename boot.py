import os
import time
import json
import machine
from machine import Pin
import xfpga

os.mountsd()
boot_btn = Pin(0,mode=Pin.IN)
if(boot_btn()):
  start = time.ticks_ms()
  xfpga.overlay('system_wrapper.bit')
  xfpga.overlay('spi2device.bit')
  #print(time.ticks_ms()-start)

f_cfg=open("/sd/board_config.json")
Board_Config                                                                                                                                                                                                                                                       =json.loads(f_cfg.read())
OverList=Board_Config["Overlay_List"]
print(OverList)

#I2C and cmd
def my_task(res): 
    global OverList
    cbtype = res[0]
    #display when slave send to master 
    if (cbtype == machine.I2C.CBTYPE_TXDATA):
        print("ESP32 Data sent to Arduino : addr={}, len={}, ovf={}, data={}".format(res[1], res[2], res[3], res[4]))
    #display when slave receive from master 
    elif (cbtype == machine.I2C.CBTYPE_RXDATA):
        print("ESP32 Data received from master: addr={}, len={}, ovf={}, data: [{}]".format(res[1], res[2], res[3], res[4]))
        cmd = s.getdata(0, 5)
        if(cmd[0] == 97 ):#a
          print("fuck")
          s.setdata('0',0)
        if(cmd[1] in range(0,len(OverList))):#d
          xfpga.overlay(OverList[cmd[1]])
          s.setdata('0',1)
        if(cmd[2] == 101):#e
          print("sleep")
          s.setdata('0',2)
        if(cmd[3] == 102):#f
          print("cmd=f")
          s.setdata('0',3)
        if(cmd[4] == 103):#g
          print("cmd=9")
          s.setdata('0',4)
s = machine.I2C(1, mode=machine.I2C.SLAVE, sda=32, scl=33)
s.callback(my_task, s.CBTYPE_ADDR | s.CBTYPE_RXDATA | s.CBTYPE_TXDATA)








