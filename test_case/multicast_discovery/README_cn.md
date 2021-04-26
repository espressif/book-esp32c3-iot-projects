# 本地控制组播客户端和服务端示例

功能：支持组播客户端和服务端

通过 `#define LIGHT_MULTICAST_CLIENT   1` 来选择客户端还是服务端

## 开发环境搭建

根据您的开发板上使用的乐鑫芯片选择开发环境搭建指导文档：

- [ESP32 Getting Started Guide](https://docs.espressif.com/projects/esp-idf/en/v4.3.2/get-started/index.html)
- [ESP32-C3 Getting Started Guide](https://docs.espressif.com/projects/esp-idf/en/v4.3.2/esp32c3/get-started/index.html)

## 编译、烧录

使用以下命令编译、烧录、监视：

```shell
$ idf.py -p /dev/ttyUSBx -b 460800 flash monitor
```

## 服务端日志

```
I (591) wifi station: wifi_station_initialize finished.
I (621) wifi:new:<1,0>, old:<1,0>, ap:<255,255>, sta:<1,0>, prof:1
I (621) wifi:state: init -> auth (b0)
I (641) wifi:state: auth -> assoc (0)
I (661) wifi:state: assoc -> run (10)
I (681) wifi:connected with HUAWEI_888, aid = 3, channel 1, BW20, bssid = 34:29:12:43:c5:40
I (681) wifi:security: WPA2-PSK, phy: bgn, rssi: -35
I (681) wifi:pm start, type: 1

I (691) wifi:set rx beacon pti, rx_bcn_pti: 0, bcn_timeout: 0, mt_pti: 25000, mt_time: 10000
I (821) wifi:BcnInt:102400, DTIM:1
I (1421) esp_netif_handlers: sta ip: 192.168.3.119, mask: 255.255.255.0, gw: 192.168.3.1
I (1421) wifi station: got ip:192.168.3.119
I (1421) wifi station: connected to ap SSID:HUAWEI_888 password:12345678
W (35341) wifi:<ba-add>idx:0 (ifx:0, 34:29:12:43:c5:40), tid:5, ssn:0, winSize:64
I (39461) wifi station: Receive udp multicast from 192.168.3.106:3333, data is Are you Espressif IOT Smart Light
I (39461) wifi station: Message sent successfully
```

## 客户端日志

```
I (613) wifi station: wifi_station_initialize finished.
I (613) wifi:new:<1,0>, old:<1,0>, ap:<255,255>, sta:<1,0>, prof:1
I (623) wifi:state: init -> auth (b0)
I (643) wifi:state: auth -> assoc (0)
I (653) wifi:state: assoc -> run (10)
I (683) wifi:connected with HUAWEI_888, aid = 2, channel 1, BW20, bssid = 34:29:12:43:c5:40
I (683) wifi:security: WPA2-PSK, phy: bgn, rssi: -36
I (683) wifi:pm start, type: 1

I (683) wifi:set rx beacon pti, rx_bcn_pti: 0, bcn_timeout: 0, mt_pti: 25000, mt_time: 10000
I (723) wifi:BcnInt:102400, DTIM:1
I (1423) esp_netif_handlers: sta ip: 192.168.3.106, mask: 255.255.255.0, gw: 192.168.3.1
I (1423) wifi station: got ip:192.168.3.106
I (1423) wifi station: connected to ap SSID:HUAWEI_888 password:12345678
I (1433) wifi station: Message sent successfully
I (1683) wifi station: Receive udp unicast from 192.168.3.119:3333, data is ESP32-C3 Smart Light https 443
```
## 示例工程结构

以下是项目文件夹中文件的简短说明：

```
├── main
│   ├── app_driver.c
│   ├── app_main.c
│   ├── CMakeLists.txt
│   └── include
│       ├── app_priv.h
│       └── board_esp32c3_devkitc.h
├── partitions.csv              Partition table file
├── README_cn.md                This is the file you are currently reading
├── sdkconfig                   Project current configuration
└── sdkconfig.defaults          Project default configuration
```

## 技术支持和反馈

请使用以下反馈渠道：

* 技术问题请到 [《ESP32-C3 物联网工程开发实战》书籍讨论版](https://esp32.com/)
* 对于功能请求或错误报告，请创建 [GitHub 问题](https://github.com/espressif/book-esp32c3-iot-projects/issues)

我们会尽快回复您。
