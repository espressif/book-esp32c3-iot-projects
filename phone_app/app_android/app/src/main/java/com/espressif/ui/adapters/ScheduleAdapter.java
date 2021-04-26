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

package com.espressif.ui.adapters;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.CompoundButton;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.appcompat.widget.SwitchCompat;
import androidx.core.widget.ContentLoadingProgressBar;
import androidx.recyclerview.widget.RecyclerView;

import com.espressif.AppConstants;
import com.espressif.cloudapi.ApiManager;
import com.espressif.cloudapi.ApiResponseListener;
import com.espressif.rainmaker.R;
import com.espressif.ui.activities.AddScheduleActivity;
import com.espressif.ui.fragments.SchedulesFragment;
import com.espressif.ui.models.Action;
import com.espressif.ui.models.Schedule;
import com.google.gson.JsonArray;
import com.google.gson.JsonObject;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Set;

public class ScheduleAdapter extends RecyclerView.Adapter<ScheduleAdapter.ScheduleViewHolder> {

    private final String TAG = ScheduleAdapter.class.getSimpleName();

    private Activity context;
    private SchedulesFragment fragment;
    private ArrayList<Schedule> scheduleList;
    private ApiManager apiManager;

    public ScheduleAdapter(Activity context, SchedulesFragment fragment, ArrayList<Schedule> scheduleList) {
        this.context = context;
        this.scheduleList = scheduleList;
        apiManager = ApiManager.getInstance(context);
        this.fragment = fragment;
    }

    @Override
    public ScheduleViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {

        // infalte the item Layout
        LayoutInflater layoutInflater = LayoutInflater.from(context);
        View v = layoutInflater.inflate(R.layout.item_schedule, parent, false);
        // set the view's size, margins, paddings and layout parameters
        ScheduleViewHolder vh = new ScheduleViewHolder(v); // pass the view to View Holder
        return vh;
    }

    @Override
    public void onBindViewHolder(@NonNull final ScheduleViewHolder scheduleViewHolder, final int position) {

        Schedule schedule = scheduleList.get(position);
        scheduleViewHolder.tvScheduleName.setText(scheduleList.get(position).getName());
        scheduleViewHolder.switchSchedule.setOnCheckedChangeListener(null);
        scheduleViewHolder.switchSchedule.setChecked(scheduleList.get(position).isEnabled());
        scheduleViewHolder.progressBar.setVisibility(View.GONE);
        scheduleViewHolder.switchSchedule.setVisibility(View.VISIBLE);

        // Display action devices
        StringBuilder deviceNames = new StringBuilder();
        ArrayList<Action> actions = schedule.getActions();

        if (actions != null && actions.size() > 0) {
            for (int i = 0; i < actions.size(); i++) {

                String deviceName = actions.get(i).getDevice().getUserVisibleName();
                if (deviceNames.length() != 0) {
                    deviceNames.append(", ");
                }
                deviceNames.append(deviceName);
            }
        }
        scheduleViewHolder.tvActionDevices.setText(deviceNames);

        // Display days and time of schedule
        StringBuilder scheduleTimeText = new StringBuilder();

        HashMap<String, Integer> triggers = schedule.getTriggers();
        int daysValue = triggers.get(AppConstants.KEY_DAYS);
        int mins = triggers.get(AppConstants.KEY_MINUTES);
        int h = mins / 60;
        int m = mins % 60;

        if (h < 12) {
            if (h < 10) {
                scheduleTimeText.append("0" + h + ":");
            } else {
                scheduleTimeText.append(h + ":");
            }

            if (m < 10) {
                scheduleTimeText.append("0" + m + " AM");
            } else {
                scheduleTimeText.append(m + " AM");
            }
        } else {
            h = h - 12;
            if (h < 10) {
                scheduleTimeText.append("0" + h + ":");
            } else {
                scheduleTimeText.append(h + ":");
            }

            if (m < 10) {
                scheduleTimeText.append("0" + m + " PM");
            } else {
                scheduleTimeText.append(m + " PM");
            }
        }

        scheduleViewHolder.tvScheduleTime.setText(scheduleTimeText);
        String days = getDaysText(daysValue);
        scheduleViewHolder.tvScheduleDays.setText(days);

        scheduleViewHolder.itemView.setOnClickListener(new View.OnClickListener() {

            @Override
            public void onClick(View v) {

                Schedule s = scheduleList.get(scheduleViewHolder.getAdapterPosition());
                Intent intent = new Intent(context, AddScheduleActivity.class);
                intent.putExtra(AppConstants.KEY_SCHEDULE, s);
                context.startActivity(intent);
            }
        });

        scheduleViewHolder.switchSchedule.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {

            @Override
            public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {

                scheduleViewHolder.switchSchedule.setVisibility(View.GONE);
                scheduleViewHolder.progressBar.setVisibility(View.VISIBLE);

                Set<String> nodeIdList = new HashSet<>();
                Schedule schedule = scheduleList.get(scheduleViewHolder.getAdapterPosition());
                ArrayList<Action> actions = schedule.getActions();
                String operation = AppConstants.KEY_OPERATION_DISABLE;

                if (isChecked) {
                    operation = AppConstants.KEY_OPERATION_ENABLE;
                }

                HashMap<String, JsonObject> map = new HashMap<>();
                for (int i = 0; i < actions.size(); i++) {

                    final String nodeId = actions.get(i).getNodeId();

                    if (!nodeIdList.contains(nodeId)) {

                        nodeIdList.add(nodeId);

                        JsonObject scheduleJson = new JsonObject();
                        scheduleJson.addProperty(AppConstants.KEY_ID, schedule.getId());
                        scheduleJson.addProperty(AppConstants.KEY_OPERATION, operation);

                        JsonArray schArr = new JsonArray();
                        schArr.add(scheduleJson);

                        JsonObject finalBody = new JsonObject();
                        finalBody.add(AppConstants.KEY_SCHEDULES, schArr);

                        JsonObject body = new JsonObject();
                        body.add(AppConstants.KEY_SCHEDULE, finalBody);

                        map.put(nodeId, body);
                    }
                }

                apiManager.updateSchedules(map, new ApiResponseListener() {

                    @Override
                    public void onSuccess(Bundle data) {

                        context.runOnUiThread(new Runnable() {

                            @Override
                            public void run() {
                                scheduleViewHolder.switchSchedule.setVisibility(View.VISIBLE);
                                scheduleViewHolder.progressBar.setVisibility(View.GONE);
                                fragment.updateScheduleList();
                            }
                        });
                    }

                    @Override
                    public void onResponseFailure(Exception exception) {

                        exception.printStackTrace();
                        final String msg = exception.getMessage();

                        context.runOnUiThread(new Runnable() {

                            @Override
                            public void run() {
                                scheduleViewHolder.switchSchedule.setVisibility(View.VISIBLE);
                                scheduleViewHolder.progressBar.setVisibility(View.GONE);
                                Toast.makeText(context, "" + msg, Toast.LENGTH_LONG).show();
                                fragment.updateScheduleList();
                            }
                        });
                    }

                    @Override
                    public void onNetworkFailure(final Exception exception) {

                        exception.printStackTrace();
                        final String msg = exception.getMessage();

                        context.runOnUiThread(new Runnable() {

                            @Override
                            public void run() {
                                scheduleViewHolder.switchSchedule.setVisibility(View.VISIBLE);
                                scheduleViewHolder.progressBar.setVisibility(View.GONE);
                                Toast.makeText(context, "" + msg, Toast.LENGTH_LONG).show();
                                fragment.updateScheduleList();
                            }
                        });
                    }
                });
            }
        });
    }

    @Override
    public int getItemCount() {
        return scheduleList.size();
    }

    public void updateList(ArrayList<Schedule> updatedScheduleList) {
        scheduleList = updatedScheduleList;
        notifyDataSetChanged();
    }

    private String getDaysText(int days) {

        StringBuilder daysText = new StringBuilder();

        if (days == 0) {
            daysText.append(context.getString(R.string.schedule_once));
        } else {

            StringBuilder daysStr = new StringBuilder("00000000");
            String daysValue = Integer.toBinaryString(days);
            char[] daysCharValue = daysValue.toCharArray();
            int j = 7;

            for (int i = (daysCharValue.length - 1); i >= 0; i--) {
                daysStr.setCharAt(j, daysCharValue[i]);
                j--;
            }

            String daysStrValue = daysStr.toString();

            if (daysStrValue.equals("01111111") || daysStrValue.equals("11111111")) {
                daysText.append(context.getString(R.string.schedule_daily));
            } else if (daysStrValue.equals("01100000") || daysStrValue.equals("11100000")) {
                daysText.append(context.getString(R.string.schedule_weekends));
            } else if (daysStrValue.equals("00011111") || daysStrValue.equals("10011111")) {
                daysText.append(context.getString(R.string.schedule_weekdays));
            } else {
                String[] daysNames = context.getResources().getStringArray(R.array.days);
                char[] chars = daysStrValue.toCharArray();

                for (int i = (chars.length - 1); i > 0; i--) {

                    if (chars[i] == '1') {

                        String day = daysNames[i - 1];
                        if (daysText.length() == 0) {
                            daysText.append(context.getString(R.string.schedule_on_day));
                            daysText.append(" ");
                            daysText.append(day);
                        } else {
                            daysText.append(", " + day);
                        }
                    }
                }
            }
        }

        return daysText.toString();
    }

    static class ScheduleViewHolder extends RecyclerView.ViewHolder {

        SwitchCompat switchSchedule;
        TextView tvScheduleName, tvActionDevices, tvScheduleTime, tvScheduleDays;
        ContentLoadingProgressBar progressBar;

        public ScheduleViewHolder(View itemView) {
            super(itemView);

            switchSchedule = itemView.findViewById(R.id.sch_enable_switch);
            tvScheduleName = itemView.findViewById(R.id.tv_schedule_name);
            progressBar = itemView.findViewById(R.id.sch_progress_indicator);
            tvActionDevices = itemView.findViewById(R.id.tv_action_devices);
            tvScheduleTime = itemView.findViewById(R.id.tv_schedule_time);
            tvScheduleDays = itemView.findViewById(R.id.tv_schedule_days);
        }
    }
}
