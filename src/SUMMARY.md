# Summary

# ESP32-C3 实战之快速构建物联网项目

- [序言](./00/00.md)

- [第一部分、基础介绍](./01/00.md)

    - [第 1 章、ESP32-C3 介绍](./01/01/00.md)
        - [1.1 ESP32-C3 芯片介绍](./01/01/01.md)
        - [1.2 ESP32-C3 软件开发 SDK 介绍（ESP-IDF）](./01/01/02.md)
        - [1.3 ESP32-C3 开发板入门（芯片、模组、开发板）](./01/01/03.md)
        - [1.4 SDK 开发环境搭建](./01/01/04.md)
        - [1.5 固件下载、调试手段](./01/01/05.md)

    - [第 2 章、ESP32-C3 基础开发](./01/02/00.md)
        - [2.1 CMake/Make 编译系统、工程结构](./01/02/01.md)
        - [2.2 ESP32-C3 启动流程](./01/02/02.md)
        - [2.3 Flash 存储器、分区表](./01/02/03.md)
        - [2.4 物联网开发常用外设](./01/02/04.md)

    - [第 3 章、网络开发](./01/03/00.md)
        - [3.1 ESP32-C3 Wi-Fi/Bluetooth 介绍](./01/03/01.md)
        - [3.2 Wi-Fi 网络配置](./01/03/02.md)
        - [3.3 连接云平台](./01/03/03.md)
        - [3.4 固件升级（Over-The-Air）](./01/03/04.md)

    - [第 4 章、电源管理](./01/04/00.md)
        - [4.1 休眠模式（Sleep modes）](./01/04/01.md)
        - [4.2 电源管理（Power Management）](./01/04/02.md)
        - [4.3 超低功耗处理器（ULP）](./01/04/03.md)

    - [第 5 章、安全第一](./01/05/00.md)
        - [5.1 OTP（Efuse）](./01/05/01.md)
        - [5.2 Flash 加密](./01/05/02.md)
        - [5.3 安全启动（Secure Boot）](./01/05/03.md)

- [第二部分、快速构建物联网项目](./02/00.md)

    - [第 6 章、 物联网项目开发概述](./02/06/00.md)
        - [6.1 物联网项目常见框架](./02/06/01.md)
        - [6.2 物联网项目开发流程](./02/06/02.md)

    - [第 7 章、 使用 ESP32-C3 完成智能照明硬件设计](./02/07/00.md)
        - [7.1 智能照明项目中 ESP32-C3 硬件设计](./02/07/01.md)

    - [第 8 章、 搭建 Wi-Fi 网络连接、配置软件框架](./02/08/00.md)
        - [8.1 使用 Provisioning 完成 Wi-Fi 连接与配置](./02/08/01.md)
        - [8.2 优化 Wi-Fi 保持连接功耗](./02/08/02.md)

    - [第 9 章、使用 ESP32-C3 完成智能照明项目底层驱动开发](./02/09/00.md)
        - [9.1 使用 LEDC 外设完成调光驱动](./02/09/01.md)
        - [9.2 LEDC 与 Wi-Fi 同时工作功耗考虑](./02/09/02.md)

    - [第 10 章、ESP-Rainmaker 介绍](./02/10/00.md)
        - [10.1 ESP-Rainmaker 功能概述](./02/10/01.md)
        - [10.2 ESP-Rainmaker 交互流程介绍](./02/10/02.md)

    - [第 11 章、基于 IDF 提供的组件完成 ESP-Rainmaker 云平台交互开发](./02/11/00.md)
        - [11.1 ESP-Rainmaker 云服务配置](./02/11/01.md)
        - [11.2 设备接入 ESP-Rainmaker 云服务](./02/11/02.md)
        - [11.3 通过 ESP-Rainmaker 云服务和 App 实现远程控制](./02/11/03.md)
        - [11.4 通过 ESP-Rainmaker 云服务实现固件升级](./02/11/04.md)

    - [第 12 章、安全基础设施配置](./02/12/00.md)
        - [12.1 Flash 加密配置](./02/12/01.md)
        - [12.2 安全启动配置](./02/12/02.md)

    - [第 13 章、固件版本管理和量产实施方案](./02/13/00.md)
        - [13.1 固件版本管理与固件升级](./02/13/01.md)
        - [13.2 安全基础设施量产考虑](./02/13/02.md)
        - [13.3 ESP-Rainmaker 量产方案](./02/13/03.md)