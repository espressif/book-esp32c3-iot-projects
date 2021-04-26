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

#define LIGHT_MULTICAST_CLIENT  1
#define LIGHT_ESP_WIFI_SSID     "YOUR-SSID"
#define LIGHT_ESP_WIFI_PASS     "YOUR-PASS"
#define LIGHT_ESP_MAXIMUM_RETRY 5

/* The event group allows multiple bits for each event, but we only care about two events:
 * - we are connected to the AP with an IP
 * - we failed to connect after the maximum amount of retries */
#define WIFI_CONNECTED_BIT BIT0
#define WIFI_FAIL_BIT      BIT1

static const char *TAG = "multicast discovery";

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

#define MULTICAST_IPV4_ADDR "232.10.11.12"
static int esp_join_multicast_group(int sockfd)
{
   struct ip_mreq imreq = { 0 };
   struct in_addr iaddr = { 0 };
   int err = 0;
   
   // 配置组播报文发送的接口
   esp_netif_ip_info_t ip_info = { 0 };
   err = esp_netif_get_ip_info(esp_netif_get_handle_from_ifkey("WIFI_STA_DEF"), &ip_info);
   if (err != ESP_OK) {
      ESP_LOGE(TAG, "Failed to get IP address info. Error 0x%x", err);
      goto err;
   }
   inet_addr_from_ip4addr(&iaddr, &ip_info.ip);
   err = setsockopt(sockfd, IPPROTO_IP, IP_MULTICAST_IF, &iaddr,
                     sizeof(struct in_addr));
   if (err < 0) {
      ESP_LOGE(TAG, "Failed to set IP_MULTICAST_IF. Error %d", errno);
      goto err;
   }

   // 配置监听的组播组地址
   inet_aton(MULTICAST_IPV4_ADDR, &imreq.imr_multiaddr.s_addr);

   // 配置套接字加入组播组
   err = setsockopt(sockfd, IPPROTO_IP, IP_ADD_MEMBERSHIP,
                        &imreq, sizeof(struct ip_mreq));
   if (err < 0) {
      ESP_LOGE(TAG, "Failed to set IP_ADD_MEMBERSHIP. Error %d", errno);
   }

err:
   return err;
}

static esp_err_t esp_send_multicast(void)
{
   esp_err_t err = ESP_FAIL;
   struct sockaddr_in saddr = {0};
   struct sockaddr_in from_addr = {0};
   socklen_t from_addr_len      = sizeof(struct sockaddr_in);
   char udp_recv_buf[64 + 1] = {0};

   // 创建 IPv4 UDP 套接字
   int sockfd = socket(AF_INET, SOCK_DGRAM, 0);
   if (sockfd == -1) {
      ESP_LOGE(TAG, "Create UDP socket fail");
      return err;
   }

   // 绑定套接字
   saddr.sin_family = PF_INET;
   saddr.sin_port = htons(3333);
   saddr.sin_addr.s_addr = htonl(INADDR_ANY);
   int ret = bind(sockfd, (struct sockaddr *)&saddr, sizeof(struct sockaddr_in));
   if (ret < 0) {
      ESP_LOGE(TAG, "Failed to bind socket. Error %d", errno);
      goto exit;
   }

   // 设置组播 TTL 为 1，表示该组播包只能经由一个路由
   uint8_t ttl = 1;
   ret = setsockopt(sockfd, IPPROTO_IP, IP_MULTICAST_TTL, &ttl, sizeof(uint8_t));
   if (ret < 0) {
      ESP_LOGE(TAG, "Failed to set IP_MULTICAST_TTL. Error %d", errno);
      goto exit;
   }

   // 加入组播组
   ret = esp_join_multicast_group(sockfd);
   if (ret < 0) {
      ESP_LOGE(TAG, "Failed to join multicast group");
      goto exit;
   }

   // 设置组播目的地址和端口
   struct sockaddr_in dest_addr = {
      .sin_family = AF_INET,
      .sin_port = htons(3333),
   };
   inet_aton(MULTICAST_IPV4_ADDR, &dest_addr.sin_addr.s_addr);

   char *multicast_msg_buf = "Are you Espressif IOT Smart Light";

   // 调用 sendto 接口发送组播数据
   ret = sendto(sockfd, multicast_msg_buf, strlen(multicast_msg_buf), 0, (struct sockaddr *)&dest_addr, sizeof(struct sockaddr));
   if (ret < 0) {
      ESP_LOGE(TAG, "Error occurred during sending: errno %d", errno);
   } else {
      ESP_LOGI(TAG, "Message sent successfully");
      ret = recvfrom(sockfd, udp_recv_buf, sizeof(udp_recv_buf) - 1, 0, (struct sockaddr *)&from_addr, (socklen_t *)&from_addr_len);
      if (ret > 0) {
         ESP_LOGI(TAG, "Receive udp unicast from %s:%d, data is %s", inet_ntoa(((struct sockaddr_in *)&from_addr)->sin_addr), ntohs(((struct sockaddr_in *)&from_addr)->sin_port), udp_recv_buf);
         err = ESP_OK;
      }
   }

exit:
   close(sockfd);
   return err;
}

static esp_err_t esp_recv_multicast(void)
{
   esp_err_t err = ESP_FAIL;
   struct sockaddr_in saddr = {0};
   struct sockaddr_in from_addr = {0};
   socklen_t from_addr_len      = sizeof(struct sockaddr_in);
   char udp_server_buf[64 + 1] = {0};
   char *udp_server_send_buf = "ESP32-C3 Smart Light https 443";

   // 创建 IPv4 UDP 套接字
   int sockfd = socket(AF_INET, SOCK_DGRAM, 0);
   if (sockfd == -1) {
      ESP_LOGE(TAG, "Create UDP socket fail");
      return err;
   }

   // 绑定套接字
   saddr.sin_family = PF_INET;
   saddr.sin_port = htons(3333);
   saddr.sin_addr.s_addr = htonl(INADDR_ANY);
   int ret = bind(sockfd, (struct sockaddr *)&saddr, sizeof(struct sockaddr_in));
   if (ret < 0) {
      ESP_LOGE(TAG, "Failed to bind socket. Error %d", errno);
      goto exit;
   }

   // 设置组播 TTL 为 1，表示该组播包只能经由一个路由
   uint8_t ttl = 1;
   ret = setsockopt(sockfd, IPPROTO_IP, IP_MULTICAST_TTL, &ttl, sizeof(uint8_t));
   if (ret < 0) {
      ESP_LOGE(TAG, "Failed to set IP_MULTICAST_TTL. Error %d", errno);
      goto exit;
   }

   // 加入组播组
   ret = esp_join_multicast_group(sockfd);
   if (ret < 0) {
      ESP_LOGE(TAG, "Failed to join multicast group");
      goto exit;
   }

   // 调用 recvfrom 接口接收组播数据
   while (1) {
      ret = recvfrom(sockfd, udp_server_buf, sizeof(udp_server_buf) - 1, 0, (struct sockaddr *)&from_addr, (socklen_t *)&from_addr_len);
      if (ret > 0) {
         ESP_LOGI(TAG, "Receive udp multicast from %s:%d, data is %s", inet_ntoa(((struct sockaddr_in *)&from_addr)->sin_addr), ntohs(((struct sockaddr_in *)&from_addr)->sin_port), udp_server_buf);
         // 如果收到组播请求数据，单播发送对端数据通信应用端口
         if (!strcmp(udp_server_buf, "Are you Espressif IOT Smart Light")) {
            ret = sendto(sockfd, udp_server_send_buf, strlen(udp_server_send_buf), 0, (struct sockaddr *)&from_addr, from_addr_len);
            if (ret < 0) {
               ESP_LOGE(TAG, "Error occurred during sending: errno %d", errno);
            } else {
               ESP_LOGI(TAG, "Message sent successfully");
            }
         }
      }
   }

exit:
   close(sockfd);
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

#if LIGHT_MULTICAST_CLIENT
    esp_send_multicast();
#else
    esp_recv_multicast();
#endif

    while (1) {
        ESP_LOGI(TAG, "[%02d] Hello world!", i++);
        vTaskDelay(pdMS_TO_TICKS(5000));
    }
}
