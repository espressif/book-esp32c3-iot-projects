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
import android.net.Uri;
import android.os.Bundle;
import android.text.TextUtils;
import android.view.View;
import android.widget.RelativeLayout;

import androidx.appcompat.app.AppCompatActivity;

import com.espressif.rainmaker.BuildConfig;
import com.espressif.rainmaker.R;
import com.google.android.material.appbar.MaterialToolbar;

public class VoiceServicesActivity extends AppCompatActivity {

    private RelativeLayout rlAlexa, rlGva;

    @Override
    public void onCreate(Bundle savedInstanceState) {

        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_voice_services);
        initViews();
    }

    private void initViews() {

        MaterialToolbar toolbar = findViewById(R.id.toolbar);
        setSupportActionBar(toolbar);
        getSupportActionBar().setDisplayHomeAsUpEnabled(true);
        getSupportActionBar().setDisplayShowHomeEnabled(true);
        toolbar.setTitle(R.string.title_activity_voice_services);
        toolbar.setNavigationIcon(R.drawable.ic_arrow_left);
        toolbar.setNavigationOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                finish();
            }
        });

        rlAlexa = findViewById(R.id.rl_alexa);
        rlGva = findViewById(R.id.rl_gva);
        rlAlexa.setOnClickListener(alexaClickListener);
        rlGva.setOnClickListener(gvaClickListener);
    }

    private View.OnClickListener alexaClickListener = new View.OnClickListener() {

        @Override
        public void onClick(View v) {

            String nullStr = "null";

            if ((!TextUtils.isEmpty(BuildConfig.AUTH_URL) && !nullStr.equalsIgnoreCase(BuildConfig.AUTH_URL))
                    && (!TextUtils.isEmpty(BuildConfig.ALEXA_CLIENT_ID) && !nullStr.equalsIgnoreCase(BuildConfig.ALEXA_CLIENT_ID))
                    && (!TextUtils.isEmpty(BuildConfig.ALEXA_CLIENT_SECRET) && !nullStr.equalsIgnoreCase(BuildConfig.ALEXA_CLIENT_SECRET))
                    && (!TextUtils.isEmpty(BuildConfig.ALEXA_RM_CLIENT_ID) && !nullStr.equalsIgnoreCase(BuildConfig.ALEXA_RM_CLIENT_ID))
                    && (!TextUtils.isEmpty(BuildConfig.ALEXA_REDIRECT_URL) && !nullStr.equalsIgnoreCase(BuildConfig.ALEXA_REDIRECT_URL))
                    && (!TextUtils.isEmpty(BuildConfig.SKILL_ID) && !nullStr.equalsIgnoreCase(BuildConfig.SKILL_ID))
                    && (!TextUtils.isEmpty(BuildConfig.SKILL_STAGE) && !nullStr.equalsIgnoreCase(BuildConfig.SKILL_STAGE))
                    && (!TextUtils.isEmpty(BuildConfig.ALEXA_ACCESS_TOKEN_URL) && !nullStr.equalsIgnoreCase(BuildConfig.ALEXA_ACCESS_TOKEN_URL))) {

                Intent intent = new Intent(VoiceServicesActivity.this, AlexaAppLinkingActivity.class);
                startActivity(intent);
            } else {
                String url = "https://rainmaker.espressif.com/docs/3rd-party.html#enabling-alexa";
                Intent openURL = new Intent(Intent.ACTION_VIEW, Uri.parse(url));
                startActivity(openURL);
            }
        }
    };

    private View.OnClickListener gvaClickListener = new View.OnClickListener() {

        @Override
        public void onClick(View v) {
            String url = "https://rainmaker.espressif.com/docs/3rd-party.html#enabling-google-voice-assistant-gva";
            Intent openURL = new Intent(Intent.ACTION_VIEW, Uri.parse(url));
            startActivity(openURL);
        }
    };
}
