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

import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.text.TextUtils;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.espressif.AppConstants;
import com.espressif.rainmaker.R;
import com.espressif.ui.user_module.ChangePasswordActivity;
import com.espressif.ui.user_module.DeleteUserActivity;

import java.util.ArrayList;

public class AccountAdapter extends RecyclerView.Adapter<AccountAdapter.AccountItemViewHolder> {

    private Context context;
    private ArrayList<String> accountItemList;

    public AccountAdapter(Context context, ArrayList<String> accountItemList) {
        this.context = context;
        this.accountItemList = accountItemList;
    }

    @Override
    public AccountItemViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {

        LayoutInflater layoutInflater = LayoutInflater.from(context);
        View view = layoutInflater.inflate(R.layout.item_account, parent, false);
        return new AccountItemViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull final AccountItemViewHolder accountItemVH, final int position) {

        String accountItem = accountItemList.get(position);
        accountItemVH.tvAccountItem.setText(accountItem);

        if (accountItem.equals(context.getString(R.string.email))) {
            SharedPreferences sharedPreferences = context.getSharedPreferences(AppConstants.ESP_PREFERENCES, Context.MODE_PRIVATE);
            accountItemVH.tvEmail.setVisibility(View.VISIBLE);
            accountItemVH.ivArrow.setVisibility(View.GONE);
            accountItemVH.tvEmail.setText(sharedPreferences.getString(AppConstants.KEY_EMAIL, ""));
        } else if (accountItem.equals(context.getString(R.string.user_id))) {
            SharedPreferences sharedPreferences = context.getSharedPreferences(AppConstants.ESP_PREFERENCES, Context.MODE_PRIVATE);
            accountItemVH.tvEmail.setVisibility(View.VISIBLE);
            accountItemVH.ivArrow.setVisibility(View.GONE);
            accountItemVH.tvEmail.setText(sharedPreferences.getString(AppConstants.KEY_USER_ID, ""));
        } else {
            accountItemVH.tvEmail.setVisibility(View.GONE);
            accountItemVH.ivArrow.setVisibility(View.VISIBLE);
        }

        accountItemVH.itemView.setOnClickListener(new View.OnClickListener() {

            @Override
            public void onClick(View v) {

                int position = accountItemVH.getAdapterPosition();
                String str = accountItemList.get(position);

                if (!TextUtils.isEmpty(str) &&
                        str.equals(context.getString(R.string.title_activity_change_password))) {

                    context.startActivity(new Intent(context, ChangePasswordActivity.class));

                } else if (!TextUtils.isEmpty(str) &&
                        str.equals(context.getString(R.string.title_activity_delete_user))) {

                    context.startActivity(new Intent(context, DeleteUserActivity.class));
                }
            }
        });
    }

    @Override
    public int getItemCount() {
        return accountItemList.size();
    }

    static class AccountItemViewHolder extends RecyclerView.ViewHolder {

        TextView tvAccountItem, tvEmail;
        ImageView ivArrow;

        public AccountItemViewHolder(View itemView) {
            super(itemView);

            tvAccountItem = itemView.findViewById(R.id.tv_item_name);
            tvEmail = itemView.findViewById(R.id.tv_email);
            ivArrow = itemView.findViewById(R.id.iv_arrow);
            itemView.setTag(this);
        }
    }
}
