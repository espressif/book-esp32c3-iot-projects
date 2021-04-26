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

import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.os.Bundle;
import android.text.Html;
import android.text.method.LinkMovementMethod;
import android.view.View;
import android.widget.TextView;

import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;

import com.espressif.rainmaker.BuildConfig;
import com.espressif.rainmaker.R;
import com.google.android.material.appbar.MaterialToolbar;

public class AboutAppActivity extends AppCompatActivity {

    private TextView tvAppVersion;
    private TextView linkDoc, linkPrivacy, linkTerms;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_about);
        initViews();
    }

    private void initViews() {

        MaterialToolbar toolbar = findViewById(R.id.toolbar);
        setSupportActionBar(toolbar);
        getSupportActionBar().setDisplayHomeAsUpEnabled(true);
        getSupportActionBar().setDisplayShowHomeEnabled(true);
        toolbar.setTitle(R.string.title_activity_about);
        toolbar.setNavigationIcon(R.drawable.ic_arrow_left);
        toolbar.setNavigationOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                finish();
            }
        });

        tvAppVersion = findViewById(R.id.tv_app_version);
        linkDoc = findViewById(R.id.tv_documentation);
        linkPrivacy = findViewById(R.id.tv_privacy);
        linkTerms = findViewById(R.id.tv_terms_condition);

        // Set app version
        String version = "";
        try {
            PackageInfo pInfo = getPackageManager().getPackageInfo(getPackageName(), 0);
            version = pInfo.versionName;
        } catch (PackageManager.NameNotFoundException e) {
            e.printStackTrace();
        }
        tvAppVersion.setText(version);

        // Set documentation URL
        linkDoc.setMovementMethod(LinkMovementMethod.getInstance());
        String docUrl = "<a href='" + BuildConfig.DOCUMENTATION_URL + "'>" + getString(R.string.documentation) + "</a>";
        linkDoc.setText(Html.fromHtml(docUrl));

        // Set privacy URL
        linkPrivacy.setMovementMethod(LinkMovementMethod.getInstance());
        String privacyUrl = "<a href='" + BuildConfig.PRIVACY_URL + "'>" + getString(R.string.privacy_policy) + "</a>";
        linkPrivacy.setText(Html.fromHtml(privacyUrl));

        // Set terms of use URL
        linkTerms.setMovementMethod(LinkMovementMethod.getInstance());
        String termsUrl = "<a href='" + BuildConfig.TERMS_URL + "'>" + getString(R.string.terms_of_use) + "</a>";
        linkTerms.setText(Html.fromHtml(termsUrl));
    }
}
