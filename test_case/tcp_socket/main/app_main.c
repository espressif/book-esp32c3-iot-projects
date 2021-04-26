/* ESP32-C3 Light Example

   This example code is in the Public Domain (or CC0 licensed, at your option.)

   Unless required by applicable law or agreed to in writing, this
   software is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
   CONDITIONS OF ANY KIND, either express or implied.
*/

#include <stdio.h>
#include <string.h>

#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/event_groups.h"

#include "esp_system.h"
#include "esp_wifi.h"
#include "esp_event.h"
#include "esp_log.h"
#include "nvs_flash.h"

#include "lwip/sockets.h"
#include "lwip/err.h"
#include "lwip/sys.h"

#include "app_storage.h"
#include "app_priv.h"

#define LIGHT_TCP_CLIENT        1
#define LIGHT_ESP_WIFI_SSID     "YOUR-SSID"
#define LIGHT_ESP_WIFI_PASS     "YOUR-PASS"
#define LIGHT_ESP_MAXIMUM_RETRY 5
#define HOST_IP                 "192.168.3.80"
#define PORT                    3333

/* The event group allows multiple bits for each event, but we only care about two events:
 * - we are connected to the AP with an IP
 * - we failed to connect after the maximum amount of retries */
#define WIFI_CONNECTED_BIT BIT0
#define WIFI_FAIL_BIT      BIT1

static const char *TAG = "tcp socket";

/* FreeRTOS event group to signal when we are connected*/
static EventGroupHandle_t s_wifi_event_group = NULL;
static int s_retry_num = 0;

static void event_handler(void *arg, esp_event_base_t event_base,
                          int32_t event_id, void *event_data)
{
    if (event_base == WIFI_EVENT && event_id == WIFI_EVENT_STA_START) {
        esp_wifi_connect();
    } else if (event_base == WIFI_EVENT && event_id == WIFI_EVENT_STA_DISCONNECTED) {
        if (s_retry_num < LIGHT_ESP_MAXIMUM_RETRY) {
            esp_wifi_connect();
            s_retry_num++;
            ESP_LOGI(TAG, "retry to connect to the AP");
        } else {
            xEventGroupSetBits(s_wifi_event_group, WIFI_FAIL_BIT);
        }
        ESP_LOGI(TAG, "connect to the AP fail");
    } else if (event_base == IP_EVENT && event_id == IP_EVENT_STA_GOT_IP) {
        ip_event_got_ip_t *event = (ip_event_got_ip_t *) event_data;
        ESP_LOGI(TAG, "got ip:" IPSTR, IP2STR(&event->ip_info.ip));
        s_retry_num = 0;
        xEventGroupSetBits(s_wifi_event_group, WIFI_CONNECTED_BIT);
    }
}

static void wifi_initialize(void)
{
    s_wifi_event_group = xEventGroupCreate();

    /* Initialize TCP/IP */
    ESP_ERROR_CHECK(esp_netif_init());

    /* Initialize the event loop */
    ESP_ERROR_CHECK(esp_event_loop_create_default());

    /* Initialize Wi-Fi including netif with default config */
    esp_netif_create_default_wifi_sta();
    wifi_init_config_t cfg = WIFI_INIT_CONFIG_DEFAULT();
    ESP_ERROR_CHECK(esp_wifi_init(&cfg));

    /* Register our event handler for Wi-Fi and IP related events */
    ESP_ERROR_CHECK(esp_event_handler_register(WIFI_EVENT, ESP_EVENT_ANY_ID, &event_handler, NULL));
    ESP_ERROR_CHECK(esp_event_handler_register(IP_EVENT, IP_EVENT_STA_GOT_IP, &event_handler, NULL));
}

static void wifi_station_initialize(void)
{
    /* Start Wi-Fi in station mode */
    wifi_config_t wifi_config = {
        .sta = {
            .ssid = LIGHT_ESP_WIFI_SSID,
            .password = LIGHT_ESP_WIFI_PASS,
            /* Setting a password implies station will connect to all security modes including WEP/WPA.
             * However these modes are deprecated and not advisable to be used. Incase your Access point
             * doesn't support WPA2, these mode can be enabled by commenting below line */
            .threshold.authmode = WIFI_AUTH_WPA2_PSK,

            .pmf_cfg = {
                .capable = true,
                .required = false
            },
        },
    };
    ESP_ERROR_CHECK(esp_wifi_set_mode(WIFI_MODE_STA));
    ESP_ERROR_CHECK(esp_wifi_set_config(WIFI_IF_STA, &wifi_config));
    ESP_ERROR_CHECK(esp_wifi_start());

    ESP_LOGI(TAG, "wifi_station_initialize finished.");

    /* Waiting until either the connection is established (WIFI_CONNECTED_BIT) or connection failed for the maximum
     * number of re-tries (WIFI_FAIL_BIT). The bits are set by event_handler() (see above) */
    EventBits_t bits = xEventGroupWaitBits(s_wifi_event_group, WIFI_CONNECTED_BIT | WIFI_FAIL_BIT, pdFALSE, pdFALSE, portMAX_DELAY);

    /* xEventGroupWaitBits() returns the bits before the call returned, hence we can test which event actually
     * happened. */
    if (bits & WIFI_CONNECTED_BIT) {
        ESP_LOGI(TAG, "connected to ap SSID:%s password:%s", LIGHT_ESP_WIFI_SSID, LIGHT_ESP_WIFI_PASS);
    } else if (bits & WIFI_FAIL_BIT) {
        ESP_LOGI(TAG, "Failed to connect to SSID:%s, password:%s", LIGHT_ESP_WIFI_SSID, LIGHT_ESP_WIFI_PASS);
    } else {
        ESP_LOGE(TAG, "UNEXPECTED EVENT");
    }
}

static esp_err_t esp_create_tcp_server(void)
{
   int len;
   int keepAlive = 1;
   int keepIdle = 5;
   int keepInterval = 5;
   int keepCount = 3;
   char rx_buffer[128] = {0};
   char addr_str[32] = {0};
   esp_err_t err = ESP_FAIL;
   struct sockaddr_in server_addr;

   // 创建 TCP 套接字
   int listenfd = socket(AF_INET, SOCK_STREAM, 0);
   if (listenfd < 0) {
      ESP_LOGE(TAG, "create socket error");
      return err;
   }

   ESP_LOGI(TAG, "create socket success, listenfd : %d", listenfd);

   // 启用 SO_REUSEADDR 选项， 允许服务器绑定当前已经存在已建立连接的地址
   int opt = 1;
   int ret = setsockopt(listenfd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));
   if (ret < 0) {
      ESP_LOGE(TAG, "Failed to set SO_REUSEADDR. Error %d", errno);
      goto exit;
   }

   // 服务器绑定 IP 全 0，端口 3333 的接口
   server_addr.sin_family = AF_INET;
   server_addr.sin_addr.s_addr = INADDR_ANY;
   server_addr.sin_port = htons(PORT);
   ret = bind(listenfd, (struct sockaddr *) &server_addr, sizeof(server_addr));
   if (ret < 0) {
      ESP_LOGE(TAG, "bind socket failed, socketfd : %d, errno : %d", listenfd, errno);
      goto exit;
   }
   ESP_LOGI(TAG, "bind socket success");

   ret = listen(listenfd, 1);
   if (ret < 0) {
      ESP_LOGE(TAG, "listen socket failed, socketfd : %d, errno : %d", listenfd, errno);
      goto exit;
   }
   ESP_LOGI(TAG, "listen socket success");

   while (1) {
      struct sockaddr_in source_addr;
      socklen_t addr_len = sizeof(source_addr);
      // 等待新的 TCP 连接建立成功，并返回与对端通信的套接字
      int sock = accept(listenfd, (struct sockaddr *)&source_addr, &addr_len);
      if (sock < 0) {
         ESP_LOGE(TAG, "Unable to accept connection: errno %d", errno);
         break;
      }

      // 启动 TCP 保活 功能，防止僵尸客户端
      setsockopt(sock, SOL_SOCKET, SO_KEEPALIVE, &keepAlive, sizeof(int));
      setsockopt(sock, IPPROTO_TCP, TCP_KEEPIDLE, &keepIdle, sizeof(int));
      setsockopt(sock, IPPROTO_TCP, TCP_KEEPINTVL, &keepInterval, sizeof(int));
      setsockopt(sock, IPPROTO_TCP, TCP_KEEPCNT, &keepCount, sizeof(int));

      if (source_addr.sin_family == PF_INET) {
         inet_ntoa_r(((struct sockaddr_in *)&source_addr)->sin_addr, addr_str, sizeof(addr_str) - 1);
      }

      ESP_LOGI(TAG, "Socket accepted ip address: %s", addr_str);

      do {
         len = recv(sock, rx_buffer, sizeof(rx_buffer) - 1, 0);
         if (len < 0) {
            ESP_LOGE(TAG, "Error occurred during receiving: errno %d", errno);
         } else if (len == 0) {
            ESP_LOGW(TAG, "Connection closed");
         } else {
            rx_buffer[len] = 0;
            ESP_LOGI(TAG, "Received %d bytes: %s", len, rx_buffer);
         }
      } while (len > 0);

      shutdown(sock, 0);
      close(sock);
   }
exit:
   close(listenfd);
   return err;
}

static esp_err_t esp_create_tcp_client(void)
{
   esp_err_t err = ESP_FAIL;
   char *payload = "Open the light";
   struct sockaddr_in dest_addr;
   dest_addr.sin_addr.s_addr = inet_addr(HOST_IP);
   dest_addr.sin_family = AF_INET;
   dest_addr.sin_port = htons(PORT);

   // 创建 TCP 套接字
   int sock =  socket(AF_INET, SOCK_STREAM, 0);
   if (sock < 0) {
      ESP_LOGE(TAG, "Unable to create socket: errno %d", errno);
      return err;
   }
   ESP_LOGI(TAG, "Socket created, connecting to %s:%d", HOST_IP, PORT);

   // 连接 TCP 服务器
   int ret = connect(sock, (struct sockaddr *)&dest_addr, sizeof(dest_addr));
   if (ret != 0) {
      ESP_LOGE(TAG, "Socket unable to connect: errno %d", errno);
      close(sock);
      return err;
   }
   ESP_LOGI(TAG, "Successfully connected");

   // 发送 TCP 数据
   ret = send(sock, payload, strlen(payload), 0);
   if (ret < 0) {
      ESP_LOGE(TAG, "Error occurred during sending: errno %d", errno);
      goto exit;
   }
   err = ESP_OK;

exit:
   shutdown(sock, 0);
   close(sock);
   return err;
}

void app_main()
{
    int i = 0;
    ESP_LOGE(TAG, "app_main");

    /**
     * @brief NVS Flash initialization
     */
    ESP_LOGI(TAG, "NVS Flash initialization");
    app_storage_init();

    /**
     * @brief Application driver initialization
     */
    ESP_LOGI(TAG, "Application driver initialization");
    app_driver_init();

    /**
     * @brief Wi-Fi initialization
     */
    ESP_LOGI(TAG, "Wi-Fi initialization");
    wifi_initialize();

    /**
     * @brief Wi-Fi Station initialization
     */
    ESP_LOGI(TAG, "Wi-Fi Station initialization");
    wifi_station_initialize();

#if LIGHT_TCP_CLIENT
    esp_create_tcp_client();
#else
    esp_create_tcp_server();
#endif

    while (1) {
        ESP_LOGI(TAG, "[%02d] Hello world!", i++);
        vTaskDelay(pdMS_TO_TICKS(5000));
    }
}
