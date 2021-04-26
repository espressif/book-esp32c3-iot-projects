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

import android.content.Context;
import android.content.Intent;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.espressif.rainmaker.R;
import com.espressif.ui.activities.AboutAppActivity;
import com.espressif.ui.activities.AccountActivity;
import com.espressif.ui.activities.NotificationsActivity;
import com.espressif.ui.activities.VoiceServicesActivity;

import java.util.ArrayList;

public class UserProfileAdapter extends RecyclerView.Adapter<UserProfileAdapter.ProfileViewHolder> {

    private Context context;
    private ArrayList<String> userInfoList;
    private int pendingReqCnt;

    public UserProfileAdapter(Context context, ArrayList<String> userInfoList, int pendingReqCnt) {

        this.context = context;
        this.userInfoList = userInfoList;
        this.pendingReqCnt = pendingReqCnt;
    }

    @Override
    public ProfileViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {

        LayoutInflater layoutInflater = LayoutInflater.from(context);
        View v = layoutInflater.inflate(R.layout.item_user_profile, parent, false);
        ProfileViewHolder profileViewHolder = new ProfileViewHolder(v);
        return profileViewHolder;
    }

    @Override
    public void onBindViewHolder(@NonNull final ProfileViewHolder profileViewHolder, final int position) {

        profileViewHolder.tvUserInfoLabel.setText(userInfoList.get(position));

        if (userInfoList.get(position).equals(context.getString(R.string.title_activity_sharing_requests))) {
            if (pendingReqCnt > 0) {
                profileViewHolder.tvCount.setVisibility(View.VISIBLE);
                profileViewHolder.tvCount.setText(String.valueOf(pendingReqCnt));
            } else {
                profileViewHolder.tvCount.setVisibility(View.GONE);
            }
        }

        profileViewHolder.itemView.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {

                int position = profileViewHolder.getAdapterPosition();
                String str = userInfoList.get(position);

                if (str.equals(context.getString(R.string.title_activity_account_settings))) {

                    context.startActivity(new Intent(context, AccountActivity.class));

                } else if (str.equals(context.getString(R.string.title_activity_sharing_requests))) {

                    context.startActivity(new Intent(context, NotificationsActivity.class));

                } else if (str.equals(context.getString(R.string.voice_services))) {

                    context.startActivity(new Intent(context, VoiceServicesActivity.class));

                } else if (str.equals(context.getString(R.string.title_activity_about))) {

                    context.startActivity(new Intent(context, AboutAppActivity.class));
                }
            }
        });
    }

    @Override
    public int getItemCount() {
        return userInfoList.size();
    }

    public void updatePendingRequestCount(int count) {

        this.pendingReqCnt = count;
        notifyDataSetChanged();
    }

    static class ProfileViewHolder extends RecyclerView.ViewHolder {

        TextView tvUserInfoLabel;
        TextView tvCount;

        public ProfileViewHolder(View itemView) {
            super(itemView);

            tvUserInfoLabel = itemView.findViewById(R.id.tv_info);
            tvCount = itemView.findViewById(R.id.tv_count);
            itemView.setTag(this);
        }
    }
}
