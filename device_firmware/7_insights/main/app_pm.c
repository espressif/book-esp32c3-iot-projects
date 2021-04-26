/*
   This example code is in the Public Domain (or CC0 licensed, at your option.)

   Unless required by applicable law or agreed to in writing, this
   software is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
   CONDITIONS OF ANY KIND, either express or implied.
*/

#include <stdio.h>

#include "esp_log.h"
#include "esp_pm.h"

#include "app_priv.h"

#if CONFIG_PM_ENABLE

#define LIGHT_EXAMPLE_MAX_CPU_FREQ_MHZ (80)
#define LIGHT_EXAMPLE_MIN_CPU_FREQ_MHZ (10)

static const char *TAG = "app-pm";
static bool g_pm_lock_acquired = false;
static esp_pm_lock_handle_t g_pm_apb_lock = NULL;

esp_err_t app_pm_init()
{
#if CONFIG_PM_ENABLE
    // Configure dynamic frequency scaling:
    // maximum and minimum frequencies are set in sdkconfig,
    // automatic light sleep is enabled if tickless idle support is enabled.
#if CONFIG_IDF_TARGET_ESP32
    esp_pm_config_esp32_t pm_config = {
#elif CONFIG_IDF_TARGET_ESP32S2
    esp_pm_config_esp32s2_t pm_config = {
#elif CONFIG_IDF_TARGET_ESP32C3
    esp_pm_config_esp32c3_t pm_config = {
#endif
            .max_freq_mhz = LIGHT_EXAMPLE_MAX_CPU_FREQ_MHZ,
            .min_freq_mhz = LIGHT_EXAMPLE_MIN_CPU_FREQ_MHZ,
#if CONFIG_FREERTOS_USE_TICKLESS_IDLE
            .light_sleep_enable = true
#endif
    };
    ESP_ERROR_CHECK( esp_pm_configure(&pm_config) );
#endif // CONFIG_PM_ENABLE

    if (g_pm_apb_lock == NULL) {
        if (esp_pm_lock_create(ESP_PM_APB_FREQ_MAX, 0, "l_apb", &g_pm_apb_lock) != ESP_OK) {
            ESP_LOGE(TAG, "esp pm lock l_apb create failed");
        }
    }

    return ESP_OK;
}

esp_err_t app_pm_lock_acquire()
{
    if (!g_pm_lock_acquired) {
        ESP_ERROR_CHECK(esp_pm_lock_acquire(g_pm_apb_lock));
        g_pm_lock_acquired = true;
    } else {
        ESP_LOGI(TAG, "already acquire");
    }
    return ESP_OK;
}

esp_err_t app_pm_lock_release()
{
    if (g_pm_lock_acquired) {
        ESP_ERROR_CHECK(esp_pm_lock_release(g_pm_apb_lock));
        g_pm_lock_acquired = false;
    } else {
        ESP_LOGI(TAG, "already release");
    }

    return ESP_OK;
}

#else

esp_err_t app_pm_init()
{
    return ESP_FAIL;
}

esp_err_t app_pm_lock_acquire()
{
    return ESP_FAIL;
}

esp_err_t app_pm_lock_release()
{
    return ESP_FAIL;
}

#endif // CONFIG_PM_ENABLE
