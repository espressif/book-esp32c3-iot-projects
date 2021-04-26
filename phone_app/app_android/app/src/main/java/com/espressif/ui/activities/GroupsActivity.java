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

package com.espressif.ui.activities;

import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.widget.ImageView;
import android.widget.RelativeLayout;
import android.widget.TextView;

import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout;

import com.espressif.EspApplication;
import com.espressif.cloudapi.ApiManager;
import com.espressif.cloudapi.ApiResponseListener;
import com.espressif.rainmaker.R;
import com.espressif.ui.adapters.GroupAdapter;
import com.espressif.ui.models.Group;
import com.google.android.material.appbar.MaterialToolbar;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.Map;

public class GroupsActivity extends AppCompatActivity {

    private static final String TAG = GroupsActivity.class.getSimpleName();

    private RecyclerView rvGroups;
    private TextView tvNoGroups;
    private RelativeLayout rlNoGroups;
    private SwipeRefreshLayout swipeRefreshLayout;
    private ImageView ivNoGroups;

    private EspApplication espApp;
    private GroupAdapter groupAdapter;
    private ArrayList<Group> groups;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_groups);

        groups = new ArrayList<>();
        espApp = (EspApplication) getApplicationContext();
        init();

        tvNoGroups.setVisibility(View.GONE);
        rlNoGroups.setVisibility(View.GONE);
        rvGroups.setVisibility(View.GONE);
        updateUi();
    }

    @Override
    protected void onResume() {
        super.onResume();
        swipeRefreshLayout.setRefreshing(true);
        updateUi();
        getGroups();
    }

    @Override
    public boolean onPrepareOptionsMenu(Menu menu) {
        super.onPrepareOptionsMenu(menu);
        menu.add(Menu.NONE, 1, Menu.NONE, R.string.btn_add).setIcon(R.drawable.ic_menu_add).setShowAsAction(MenuItem.SHOW_AS_ACTION_ALWAYS);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {

        switch (item.getItemId()) {

            case 1:
                goToGroupDetailActivity();
                return true;

            default:
                return super.onOptionsItemSelected(item);
        }
    }

    private void init() {

        MaterialToolbar toolbar = findViewById(R.id.toolbar);
        setSupportActionBar(toolbar);
        getSupportActionBar().setDisplayHomeAsUpEnabled(true);
        getSupportActionBar().setDisplayShowHomeEnabled(true);
        getSupportActionBar().setTitle(R.string.title_activity_manage_groups);
        toolbar.setNavigationIcon(R.drawable.ic_arrow_left);
        toolbar.setNavigationOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                finish();
            }
        });

        rlNoGroups = findViewById(R.id.rl_no_group);
        tvNoGroups = findViewById(R.id.tv_no_group);
        ivNoGroups = findViewById(R.id.iv_no_group);
        rvGroups = findViewById(R.id.rv_group_list);
        swipeRefreshLayout = findViewById(R.id.swipe_container);

        groupAdapter = new GroupAdapter(this, groups);
        rvGroups.setLayoutManager(new LinearLayoutManager(this));
        rvGroups.setAdapter(groupAdapter);

        swipeRefreshLayout.setOnRefreshListener(new SwipeRefreshLayout.OnRefreshListener() {

            @Override
            public void onRefresh() {
                refreshGroupList();
            }
        });
    }

    private void updateUi() {

        groups.clear();
        for (Map.Entry<String, Group> entry : espApp.groupMap.entrySet()) {

            String key = entry.getKey();
            Group group = entry.getValue();

            if (group != null) {
                groups.add(group);
            }
        }
        Log.d(TAG, "Number of Groups : " + groups.size());

        // Sort groups list to display alphabetically.
        Collections.sort(groups, new Comparator<Group>() {

            @Override
            public int compare(Group g1, Group g2) {
                return g1.getGroupName().compareToIgnoreCase(g2.getGroupName());
            }
        });

        if (groups.size() > 0) {
            rlNoGroups.setVisibility(View.GONE);
            rvGroups.setVisibility(View.VISIBLE);
        } else {
            tvNoGroups.setText(R.string.no_groups);
            rlNoGroups.setVisibility(View.VISIBLE);
            tvNoGroups.setVisibility(View.VISIBLE);
            ivNoGroups.setVisibility(View.VISIBLE);
            rvGroups.setVisibility(View.GONE);
        }
        groupAdapter.notifyDataSetChanged();
    }

    private void goToGroupDetailActivity() {

        Intent intent = new Intent(this, GroupDetailActivity.class);
        startActivity(intent);
    }

    private void refreshGroupList() {

        getGroups();
    }

    private void getGroups() {

        ApiManager apiManager = ApiManager.getInstance(this);
        apiManager.getUserGroups(null, new ApiResponseListener() {

            @Override
            public void onSuccess(Bundle data) {
                swipeRefreshLayout.setRefreshing(false);
                updateUi();
            }

            @Override
            public void onResponseFailure(Exception e) {
                e.printStackTrace();
                swipeRefreshLayout.setRefreshing(false);
            }

            @Override
            public void onNetworkFailure(Exception exception) {
                exception.printStackTrace();
                swipeRefreshLayout.setRefreshing(false);
            }
        });
    }
}
