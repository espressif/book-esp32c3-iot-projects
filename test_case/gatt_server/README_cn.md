# GATT 服务端示例

功能：

1. 支持手机扫描 `ESP_GATTS_DEMO` 的蓝牙并且连接后获取和发送数据。

## 开发环境搭建

根据您的开发板上使用的乐鑫芯片选择开发环境搭建指导文档：

- [ESP32 Getting Started Guide](https://docs.espressif.com/projects/esp-idf/en/v4.3.2/get-started/index.html)
- [ESP32-C3 Getting Started Guide](https://docs.espressif.com/projects/esp-idf/en/v4.3.2/esp32c3/get-started/index.html)

## 编译、烧录

使用以下命令编译、烧录、监视：

```shell
$ idf.py -p /dev/ttyUSBx -b 460800 flash monitor
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
