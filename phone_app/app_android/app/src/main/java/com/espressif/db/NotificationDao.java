// Copyright 2021 Espressif Systems (Shanghai) PTE LTD
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

package com.espressif.db;

import androidx.room.Dao;
import androidx.room.Delete;
import androidx.room.Insert;
import androidx.room.OnConflictStrategy;
import androidx.room.Query;

import com.espressif.AppConstants;
import com.espressif.ui.models.NotificationEvent;

import java.util.List;

@Dao
public interface NotificationDao {

    @Query("SELECT * FROM " + AppConstants.NOTIFICATION_TABLE + " ORDER BY " + AppConstants.KEY_TIMESTAMP + " DESC")
    List<NotificationEvent> getNotificationsFromStorage();

    /**
     * Update group if it exist in database, insert group otherwise.
     *
     * @param notification Notification event to be inserted / updated.
     */
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    void insertOrUpdate(NotificationEvent notification);

    /**
     * Delete the notification from database.
     *
     * @param notification Notification event to be deleted.
     */
    @Delete
    void delete(NotificationEvent notification);

    /**
     * Delete all notifications from the table.
     */
    @Query("DELETE FROM " + AppConstants.NOTIFICATION_TABLE)
    void deleteAll();
}
