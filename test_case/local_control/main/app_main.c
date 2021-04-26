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

#include ”mdns.h“
#include "esp_local_ctrl.h"
#include “esp_https_server.h”

#include "app_storage.h"
#include "app_priv.h"

#define LIGHT_ESP_WIFI_SSID     "YOUR-SSID"
#define LIGHT_ESP_WIFI_PASS     "YOUR-PASS"
#define LIGHT_ESP_MAXIMUM_RETRY 5

/* The event group allows multiple bits for each event, but we only care about two events:
 * - we are connected to the AP with an IP
 * - we failed to connect after the maximum amount of retries */
#define WIFI_CONNECTED_BIT BIT0
#define WIFI_FAIL_BIT      BIT1

static const char *TAG = "local control";

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

#define PROPERTY_NAME_STATUS "status"
static char light_status[64] = "{\"status\": true}";
// 属性类型定义，配合脚本使用
enum property_types {
    PROP_TYPE_TIMESTAMP = 0,
    PROP_TYPE_INT32,
    PROP_TYPE_BOOLEAN,
    PROP_TYPE_STRING,
};

// 获取属性值
static esp_err_t get_property_values(size_t props_count,
                              const esp_local_ctrl_prop_t props[],
                              esp_local_ctrl_prop_val_t prop_values[],
                              void *usr_ctx)
{
    int i = 0;
    for (i = 0; i < props_count; i ++) {
        ESP_LOGI(TAG, "Reading property : %s", props[i].name);
        if (!strncmp(PROPERTY_NAME_STATUS, props[i].name, strlen(props[i].name))) {
            prop_values[i].size = strlen(light_status);
            prop_values[i].data = &light_status;// prop_values[i].data 只是指针，不能赋值
            break;
        }
    }
    if (i == props_count) {
        ESP_LOGE(TAG, "Not found property %s", props[i].name);
        return ESP_FAIL;
    }
    return ESP_OK;
}

// 设置属性值
static esp_err_t set_property_values(size_t props_count,
                              const esp_local_ctrl_prop_t props[],
                              const esp_local_ctrl_prop_val_t prop_values[],
                              void *usr_ctx)
{
    int i = 0;
    for (i = 0; i < props_count; i ++) {
        ESP_LOGI(TAG, "Setting property : %s", props[i].name);
        if (!strncmp(PROPERTY_NAME_STATUS, props[i].name, strlen(props[i].name))) {
            memset(light_status, 0, sizeof(light_status));
            strncpy(light_status, (const char *)prop_values[i].data, prop_values[i].size);
            if (strstr(light_status, "true")) {
                app_driver_set_state(true);
            } else {
                app_driver_set_state(false);
            }
            break;
        }
    }
    if (i == props_count) {
        ESP_LOGE(TAG, "Not found property %s", props[i].name);
        return ESP_FAIL;
    }
    return ESP_OK;
}

#define SERVICE_NAME "my_esp_ctrl_device"

static void esp_local_ctrl_service_start(void)
{
    // 初始化 HTTPS 服务端配置
    httpd_ssl_config_t https_conf = HTTPD_SSL_CONFIG_DEFAULT();

    // 加载服务端证书
    extern const unsigned char cacert_pem_start[] asm("_binary_cacert_pem_start");
    extern const unsigned char cacert_pem_end[]   asm("_binary_cacert_pem_end");
    https_conf.cacert_pem = cacert_pem_start;
    https_conf.cacert_len = cacert_pem_end - cacert_pem_start;

    // 加载服务端私钥
    extern const unsigned char prvtkey_pem_start[] asm("_binary_prvtkey_pem_start");
    extern const unsigned char prvtkey_pem_end[]   asm("_binary_prvtkey_pem_end");
    https_conf.prvtkey_pem = prvtkey_pem_start;
    https_conf.prvtkey_len = prvtkey_pem_end - prvtkey_pem_start;

    esp_local_ctrl_config_t config = {
        .transport = ESP_LOCAL_CTRL_TRANSPORT_HTTPD,
        .transport_config = {
            .httpd = &https_conf
        },
        .proto_sec = {
            .version = PROTOCOM_SEC0,
            .custom_handle = NULL,
            .pop = NULL,
        },
        .handlers = {
            // 用户自定义处理函数
            .get_prop_values = get_property_values,
            .set_prop_values = set_property_values,
            .usr_ctx         = NULL,
            .usr_ctx_free_fn = NULL
        },
        // 设置属性最大个数
        .max_properties = 10
    };

    // 初始化本地发现
    mdns_init();
    mdns_hostname_set(SERVICE_NAME);

    // 启动本地控制服务
    ESP_ERROR_CHECK(esp_local_ctrl_start(&config));
    ESP_LOGI(TAG, "esp_local_ctrl service started with name : %s", SERVICE_NAME);

    esp_local_ctrl_prop_t status = {
        .name        = PROPERTY_NAME_STATUS,
        .type        = PROP_TYPE_STRING,
        .size        = 0,
        .flags       = 0,
        .ctx         = NULL,
        .ctx_free_fn = NULL
    };

    // 添加属性值
    ESP_ERROR_CHECK(esp_local_ctrl_add_property(&status));
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

    esp_local_ctrl_service_start();

    while (1) {
        ESP_LOGI(TAG, "[%02d] Hello world!", i++);
        vTaskDelay(pdMS_TO_TICKS(5000));
    }
}
