// Copyright 2020 Espressif Systems (Shanghai) PTE LTD
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package com.espressif.ui.models;

import android.os.Bundle;

import com.espressif.AppConstants;

public class UpdateEvent {

    private AppConstants.UpdateEventType eventType;
    private Bundle data;

    public Bundle getData() {
        return data;
    }

    public void setData(Bundle data) {
        this.data = data;
    }

    public UpdateEvent(AppConstants.UpdateEventType type) {
        eventType = type;
    }

    public AppConstants.UpdateEventType getEventType() {
        return eventType;
    }
}
