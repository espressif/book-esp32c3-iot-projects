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
#include "mdns.h"

#define LIGHT_ESP_WIFI_SSID     "YOUR-SSID"
#define LIGHT_ESP_WIFI_PASS     "YOUR-PASS"
#define LIGHT_ESP_MAXIMUM_RETRY 5

/* The event group allows multiple bits for each event, but we only care about two events:
 * - we are connected to the AP with an IP
 * - we failed to connect after the maximum amount of retries */
#define WIFI_CONNECTED_BIT BIT0
#define WIFI_FAIL_BIT      BIT1

static const char *TAG = "mdns discovery";

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

static esp_err_t esp_mdns_discovery_start(void)
{
   char *host_name = "my_smart_light";
   char *instance_name = "esp32c3_smart_light";

   /* 初始化 mdns 组件 */
   if (mdns_init() != ESP_OK) {
      ESP_LOGE(TAG, "mdns_init fail");
      return ESP_FAIL;
   }

   /* 设置主机名，用于其他主机查询的 DNS 域名标识 */
   if (mdns_hostname_set(host_name) != ESP_OK) {
      ESP_LOGE(TAG, "mdns_hostname_set fail");
      goto err;
   }

   ESP_LOGI(TAG, "mdns hostname set to: [%s]", host_name);

   /* 设置 mDNS 实例名，用于 mDNS 局域网发现 */
   if (mdns_instance_name_set(instance_name) != ESP_OK) {
      ESP_LOGE(TAG, "mdns_instance_name_set fail");
      goto err;
   }

   /* 设置服务 TXT 字段数据 （可选的）*/
   mdns_txt_item_t serviceTxtData[1] = {
      {"board", "esp32c3"}
   };

   /* 添加 http 服务，端口号 80 到 mDNS 服务 */
   /* 第二个参数代表应用层协议， 第三个参数代表传输层协议，需要对应 */
   if (mdns_service_add(instance_name, "_http", "_tcp", 80, serviceTxtData, 1) != ESP_OK) {
      ESP_LOGE(TAG, "mdns_instance_name_set fail");
      goto err;
   }

   /* 设置服务 TXT 字段数据 */
   if (mdns_service_txt_item_set("_http", "_tcp", "path", "/foobar") != ESP_OK) {
      ESP_LOGE(TAG, "mdns_service_txt_item_set fail");
      goto err;
   }
   return ESP_OK;
err:
   mdns_free();
   return ESP_FAIL;
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

    esp_mdns_discovery_start();

    while (1) {
        ESP_LOGI(TAG, "[%02d] Hello world!", i++);
        vTaskDelay(pdMS_TO_TICKS(5000));
    }
}
