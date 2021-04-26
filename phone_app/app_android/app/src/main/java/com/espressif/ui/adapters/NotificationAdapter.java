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

package com.espressif.ui.adapters;

import android.app.Activity;
import android.text.TextUtils;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.espressif.rainmaker.R;
import com.espressif.ui.models.NotificationEvent;

import java.text.DateFormat;
import java.util.ArrayList;
import java.util.Date;

public class NotificationAdapter extends RecyclerView.Adapter<NotificationAdapter.NotificationVH> {

    private final String TAG = NotificationAdapter.class.getSimpleName();

    private Activity context;
    private ArrayList<NotificationEvent> notifications;

    public NotificationAdapter(Activity context, ArrayList<NotificationEvent> notifications) {
        this.context = context;
        this.notifications = notifications;
    }

    @NonNull
    @Override
    public NotificationVH onCreateViewHolder(ViewGroup parent, int viewType) {

        LayoutInflater layoutInflater = LayoutInflater.from(context);
        View notificationView = layoutInflater.inflate(R.layout.item_notification, parent, false);
        NotificationVH notificationVH = new NotificationVH(notificationView);
        return notificationVH;
    }

    @Override
    public void onBindViewHolder(@NonNull final NotificationVH notificationVH, final int position) {

        NotificationEvent event = notifications.get(position);
        Log.d(TAG, "NotificationEvent type : " + event.getEventType());
        Log.d(TAG, "NotificationEvent data : " + event.getEventData());
        Date date = new Date(event.getTimestamp());
        notificationVH.tvDate.setText(DateFormat.getDateInstance().format(date));
        notificationVH.tvTime.setText(DateFormat.getTimeInstance().format(date));

        String notificationText = event.getNotificationMsg();
        if (TextUtils.isEmpty(notificationText)) {
            notificationVH.tvNotification.setText(event.getEventDescription());
        } else {
            notificationVH.tvNotification.setText(notificationText);
        }
    }

    public void updateList(ArrayList<NotificationEvent> notificationList) {

        this.notifications = notificationList;
        notifyDataSetChanged();
    }

    @Override
    public int getItemCount() {
        return notifications.size();
    }

    static class NotificationVH extends RecyclerView.ViewHolder {

        TextView tvNotification, tvDate, tvTime;

        public NotificationVH(View itemView) {
            super(itemView);

            tvNotification = itemView.findViewById(R.id.tv_notification);
            tvDate = itemView.findViewById(R.id.tv_day);
            tvTime = itemView.findViewById(R.id.tv_time);
        }
    }
}
