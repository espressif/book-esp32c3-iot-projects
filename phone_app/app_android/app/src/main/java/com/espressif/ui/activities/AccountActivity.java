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

import android.os.Bundle;
import android.view.View;

import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.espressif.cloudapi.ApiManager;
import com.espressif.rainmaker.R;
import com.espressif.ui.adapters.AccountAdapter;
import com.google.android.material.appbar.MaterialToolbar;

import java.util.ArrayList;

public class AccountActivity extends AppCompatActivity {

    private RecyclerView rvAccountSettings;
    private AccountAdapter accountAdapter;

    private ArrayList<String> accountItemList = new ArrayList<>();

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_account);
        initViews();
    }

    private void initViews() {

        MaterialToolbar toolbar = findViewById(R.id.toolbar);
        setSupportActionBar(toolbar);
        getSupportActionBar().setDisplayHomeAsUpEnabled(true);
        getSupportActionBar().setDisplayShowHomeEnabled(true);
        toolbar.setTitle(R.string.title_activity_account_settings);
        toolbar.setNavigationIcon(R.drawable.ic_arrow_left);
        toolbar.setNavigationOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                finish();
            }
        });

        accountItemList.add(getString(R.string.email));
        accountItemList.add(getString(R.string.user_id));

        if (!ApiManager.isOAuthLogin) {
            accountItemList.add(getString(R.string.title_activity_change_password));
        }

        accountItemList.add(getString(R.string.title_activity_delete_user));

        rvAccountSettings = findViewById(R.id.rv_account_settings);
        rvAccountSettings.setLayoutManager(new LinearLayoutManager(this));
        accountAdapter = new AccountAdapter(this, accountItemList);
        rvAccountSettings.setAdapter(accountAdapter);
    }
}
