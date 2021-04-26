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

import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;

import androidx.annotation.NonNull;
import androidx.appcompat.widget.PopupMenu;
import androidx.fragment.app.Fragment;
import androidx.viewpager2.widget.ViewPager2;

import com.espressif.AppConstants;
import com.espressif.EspApplication;
import com.espressif.rainmaker.BuildConfig;
import com.espressif.rainmaker.R;
import com.espressif.ui.activities.EspMainActivity;
import com.espressif.ui.activities.GroupDetailActivity;
import com.espressif.ui.activities.GroupsActivity;
import com.espressif.ui.adapters.GroupsPageAdapter;
import com.espressif.ui.models.Group;
import com.google.android.material.tabs.TabLayout;
import com.google.android.material.tabs.TabLayoutMediator;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.Map;

public class DevicesFragment extends Fragment {

    private static final String TAG = DevicesFragment.class.getSimpleName();

    private ImageView ivMore;
    private TabLayout tabLayout;
    private ViewPager2 groupPager;

    private EspApplication espApp;
    private GroupsPageAdapter adapter;
    private ArrayList<Group> groups;

    public DevicesFragment() {
        // Required empty public constructor
    }

    public static DevicesFragment newInstance() {
        return new DevicesFragment();
    }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {

        View root = inflater.inflate(R.layout.fragment_devices, container, false);
        groups = new ArrayList<>();
        espApp = (EspApplication) getActivity().getApplicationContext();
        init(root);
        updateDeviceUi();
        ((EspMainActivity) getActivity()).setUpdateListener(updateListener);
        return root;
    }

    @Override
    public void onDestroy() {
        ((EspMainActivity) getActivity()).removeUpdateListener(updateListener);
        super.onDestroy();
    }

    EspMainActivity.UiUpdateListener updateListener = new EspMainActivity.UiUpdateListener() {

        @Override
        public void updateUi() {
            updateDeviceUi();
        }
    };

    View.OnClickListener moreBtnClickListener = new View.OnClickListener() {

        @Override
        public void onClick(View view) {

            showPopupMenu(view);
        }
    };

    private void init(View view) {

        tabLayout = view.findViewById(R.id.tab_layout);
        groupPager = view.findViewById(R.id.pager);
        ivMore = view.findViewById(R.id.iv_more);

        if (!BuildConfig.isNodeGroupingSupported) {
            ivMore.setVisibility(View.GONE);
        }

        adapter = new GroupsPageAdapter(getActivity(), groups);
        groupPager.setAdapter(adapter);

        TabLayoutMediator tabLayoutMediator = new TabLayoutMediator(tabLayout, groupPager, new TabLayoutMediator.TabConfigurationStrategy() {

            @Override
            public void onConfigureTab(@NonNull TabLayout.Tab tab, int position) {
                tab.setText("" + groups.get(position).getGroupName());
            }
        });
        tabLayoutMediator.attach();
        ivMore.setOnClickListener(moreBtnClickListener);
    }

    private void updateDeviceUi() {

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

        groups.clear();

        for (Map.Entry<String, Group> entry : espApp.groupMap.entrySet()) {

            String key = entry.getKey();
            Group group = entry.getValue();

            if (group != null) {
                groups.add(group);
            }
        }

        // Sort groups list to display alphabetically.
        Collections.sort(groups, new Comparator<Group>() {

            @Override
            public int compare(Group g1, Group g2) {
                return g1.getGroupName().compareToIgnoreCase(g2.getGroupName());
            }
        });

        groups.add(0, new Group(getString(R.string.group_all_devices)));
        Log.d(TAG, "Number of groups : " + groups.size());
        adapter.notifyDataSetChanged();
        adapter.setRefreshing(isRefreshing);
    }

    private void showPopupMenu(View anchor) {
        PopupMenu popupMenu = new PopupMenu(getActivity(), anchor);
        popupMenu.getMenuInflater().inflate(R.menu.menu_group, popupMenu.getMenu());
        popupMenu.setOnMenuItemClickListener(new PopupMenu.OnMenuItemClickListener() {

            @Override
            public boolean onMenuItemClick(MenuItem item) {

                switch (item.getItemId()) {

                    case R.id.action_create_group:
                        Intent intent = new Intent(getActivity(), GroupDetailActivity.class);
                        intent.putExtra(AppConstants.KEY_OPERATION, AppConstants.KEY_OPERATION_ADD);
                        startActivity(intent);
                        return true;

                    case R.id.action_manage_group:
                        Intent intent1 = new Intent(getActivity(), GroupsActivity.class);
                        startActivity(intent1);
                        return true;

                    default:
                        return false;
                }
            }
        });
        popupMenu.show();
    }
}
