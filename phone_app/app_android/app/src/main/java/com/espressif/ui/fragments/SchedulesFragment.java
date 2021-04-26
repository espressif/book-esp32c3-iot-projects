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

package com.espressif.ui.fragments;

import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.os.Vibrator;
import android.text.TextUtils;
import android.util.Log;
import android.view.HapticFeedbackConstants;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.RelativeLayout;
import android.widget.TextView;

import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout;

import com.espressif.AppConstants;
import com.espressif.EspApplication;
import com.espressif.rainmaker.R;
import com.espressif.ui.activities.AddScheduleActivity;
import com.espressif.ui.activities.EspMainActivity;
import com.espressif.ui.adapters.ScheduleAdapter;
import com.espressif.ui.models.EspNode;
import com.espressif.ui.models.Schedule;
import com.espressif.ui.models.Service;
import com.google.android.material.card.MaterialCardView;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashMap;
import java.util.Map;

public class SchedulesFragment extends Fragment {

    private static final String TAG = SchedulesFragment.class.getSimpleName();

    private MaterialCardView btnAddSchedule;
    private TextView txtAddScheduleBtn;
    private ImageView arrowImage;

    private RecyclerView recyclerView;
    private TextView tvNoSchedule, tvAddSchedule;
    private RelativeLayout rlNoSchedules;
    private SwipeRefreshLayout swipeRefreshLayout;
    private ImageView ivNoSchedule;

    private EspApplication espApp;
    private ScheduleAdapter scheduleAdapter;
    private ArrayList<Schedule> schedules;

    public SchedulesFragment() {
        // Required empty public constructor
    }

    public static SchedulesFragment newInstance() {
        return new SchedulesFragment();
    }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {

        // Inflate the layout for this fragment
        View root = inflater.inflate(R.layout.fragment_schedules, container, false);
        schedules = new ArrayList<>();
        espApp = (EspApplication) getActivity().getApplicationContext();
        init(root);
        tvNoSchedule.setVisibility(View.GONE);
        rlNoSchedules.setVisibility(View.GONE);
        recyclerView.setVisibility(View.GONE);
        updateScheduleUi();
        ((EspMainActivity) getActivity()).setUpdateListener(updateListener);
        return root;
    }

    @Override
    public void onResume() {
        super.onResume();
        updateScheduleUi();
    }

    @Override
    public void onDestroy() {
        ((EspMainActivity) getActivity()).removeUpdateListener(updateListener);
        super.onDestroy();
    }

    EspMainActivity.UiUpdateListener updateListener = new EspMainActivity.UiUpdateListener() {

        @Override
        public void updateUi() {
            updateScheduleUi();
        }
    };

    View.OnClickListener addScheduleBtnClickListener = new View.OnClickListener() {

        @Override
        public void onClick(View v) {

            Vibrator vib = (Vibrator) getActivity().getSystemService(Context.VIBRATOR_SERVICE);
            vib.vibrate(HapticFeedbackConstants.VIRTUAL_KEY);
            goToAddScheduleActivity();
        }
    };

    public void updateScheduleList() {
        swipeRefreshLayout.setRefreshing(true);
        ((EspMainActivity) getActivity()).refreshDeviceList();
    }

    private void init(View view) {

        rlNoSchedules = view.findViewById(R.id.rl_no_schedule);
        tvNoSchedule = view.findViewById(R.id.tv_no_schedule);
        tvAddSchedule = view.findViewById(R.id.tv_add_schedule);
        ivNoSchedule = view.findViewById(R.id.iv_no_schedule);
        recyclerView = view.findViewById(R.id.rv_schedule_list);
        swipeRefreshLayout = view.findViewById(R.id.swipe_container);

        btnAddSchedule = view.findViewById(R.id.btn_add_schedule);
        txtAddScheduleBtn = btnAddSchedule.findViewById(R.id.text_btn);
        arrowImage = btnAddSchedule.findViewById(R.id.iv_arrow);
        txtAddScheduleBtn.setText(R.string.btn_add_schedule);
        btnAddSchedule.setVisibility(View.GONE);
        arrowImage.setVisibility(View.GONE);

        btnAddSchedule.setOnClickListener(addScheduleBtnClickListener);

        // set a LinearLayoutManager with default orientation
        recyclerView.setLayoutManager(new LinearLayoutManager(getActivity())); // set LayoutManager to RecyclerView

        scheduleAdapter = new ScheduleAdapter(getActivity(), this, schedules);
        recyclerView.setAdapter(scheduleAdapter);

        swipeRefreshLayout.setOnRefreshListener(new SwipeRefreshLayout.OnRefreshListener() {

            @Override
            public void onRefresh() {
                ((EspMainActivity) getActivity()).refreshDeviceList();
            }
        });
    }

    private void updateScheduleUi() {

        switch (espApp.getAppState()) {

            case NO_INTERNET:
            case GET_DATA_SUCCESS:
            case GET_DATA_FAILED:
                updateUi(false);
                break;

            case GETTING_DATA:
            case REFRESH_DATA:
                updateUi(true);
                break;
        }
    }

    private void updateUi(boolean isRefreshing) {

        schedules.clear();
        for (Map.Entry<String, Schedule> entry : espApp.scheduleMap.entrySet()) {

            String key = entry.getKey();
            Schedule schedule = entry.getValue();

            if (schedule != null) {
                schedules.add(schedule);
            }
        }

        Log.d(TAG, "Schedules size : " + schedules.size());

        // Sort schedule list by time.
        Collections.sort(schedules, new Comparator<Schedule>() {

            @Override
            public int compare(Schedule s1, Schedule s2) {
                HashMap<String, Integer> t1 = s1.getTriggers();
                HashMap<String, Integer> t2 = s2.getTriggers();
                Integer m1 = t1.get(AppConstants.KEY_MINUTES);
                Integer m2 = t2.get(AppConstants.KEY_MINUTES);
                if (m1 == null) {
                    m1 = 0;
                }
                if (m2 == null) {
                    m2 = 0;
                }
                return m1.compareTo(m2);
            }
        });

        if (schedules.size() > 0) {

            rlNoSchedules.setVisibility(View.GONE);
            btnAddSchedule.setVisibility(View.GONE);
            recyclerView.setVisibility(View.VISIBLE);

        } else {

            boolean isScheduleDevicesAvailable = false;
            for (Map.Entry<String, EspNode> entry : espApp.nodeMap.entrySet()) {

                EspNode node = entry.getValue();
                ArrayList<Service> services = node.getServices();

                if (node != null) {

                    for (int i = 0; i < services.size(); i++) {

                        Service s = services.get(i);
                        if (!TextUtils.isEmpty(s.getType()) && s.getType().equals(AppConstants.SERVICE_TYPE_SCHEDULE)) {
                            isScheduleDevicesAvailable = true;
                            break;
                        }
                    }
                }
            }

            if (isScheduleDevicesAvailable) {
                tvNoSchedule.setText(R.string.no_schedules);
                btnAddSchedule.setVisibility(View.VISIBLE);
            } else {
                tvNoSchedule.setText(R.string.no_device_support_this_feature);
                btnAddSchedule.setVisibility(View.GONE);
            }

            rlNoSchedules.setVisibility(View.VISIBLE);
            tvNoSchedule.setVisibility(View.VISIBLE);
            tvAddSchedule.setVisibility(View.GONE);
            ivNoSchedule.setVisibility(View.VISIBLE);
            recyclerView.setVisibility(View.GONE);
        }

        scheduleAdapter.updateList(schedules);
        swipeRefreshLayout.setRefreshing(isRefreshing);
        ((EspMainActivity) getActivity()).updateActionBar();
    }

    private void goToAddScheduleActivity() {

        Intent intent = new Intent(getActivity(), AddScheduleActivity.class);
        startActivity(intent);
    }
}
