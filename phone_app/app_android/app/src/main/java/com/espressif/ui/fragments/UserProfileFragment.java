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
import android.content.DialogInterface;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.RelativeLayout;
import android.widget.TextView;

import androidx.appcompat.app.AlertDialog;
import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.DividerItemDecoration;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.espressif.AppConstants;
import com.espressif.EspApplication;
import com.espressif.cloudapi.ApiManager;
import com.espressif.cloudapi.ApiResponseListener;
import com.espressif.rainmaker.BuildConfig;
import com.espressif.rainmaker.R;
import com.espressif.ui.adapters.UserProfileAdapter;
import com.espressif.ui.models.SharingRequest;

import java.util.ArrayList;

public class UserProfileFragment extends Fragment {

    private RecyclerView rvUserInfo;
    private UserProfileAdapter userInfoAdapter;

    private EspApplication espApp;
    private SharedPreferences sharedPreferences;

    private ArrayList<String> userInfoList;
    private ArrayList<SharingRequest> pendingRequests;

    public UserProfileFragment() {
        // Required empty public constructor
    }

    public static UserProfileFragment newInstance() {
        return new UserProfileFragment();
    }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {

        View rootView = inflater.inflate(R.layout.fragment_user_profile, container, false);
        espApp = (EspApplication) getActivity().getApplicationContext();
        pendingRequests = new ArrayList<>();
        sharedPreferences = espApp.getSharedPreferences(AppConstants.ESP_PREFERENCES, Context.MODE_PRIVATE);
        initViews(rootView);
        return rootView;
    }

    @Override
    public void onResume() {
        super.onResume();
        getSharingRequests();
    }

    private void initViews(View view) {

        TextView tvEmail = view.findViewById(R.id.tv_email);
        tvEmail.setText(sharedPreferences.getString(AppConstants.KEY_EMAIL, ""));

        rvUserInfo = view.findViewById(R.id.rv_user_profile);
        RelativeLayout logoutView = view.findViewById(R.id.rl_logout);

        logoutView.setOnClickListener(new View.OnClickListener() {

            @Override
            public void onClick(View v) {
                confirmLogout();
            }
        });

        LinearLayoutManager llm2 = new LinearLayoutManager(getActivity());
        llm2.setOrientation(RecyclerView.VERTICAL);
        rvUserInfo.setLayoutManager(llm2);
        DividerItemDecoration itemDecor = new DividerItemDecoration(getActivity(), DividerItemDecoration.VERTICAL);
        rvUserInfo.addItemDecoration(itemDecor);

        userInfoList = new ArrayList<>();

        userInfoList.add(getString(R.string.title_activity_account_settings));

        if (BuildConfig.isNodeSharingSupported) {
            userInfoList.add(getString(R.string.title_activity_sharing_requests));
        }

        userInfoList.add(getString(R.string.voice_services));
        userInfoList.add(getString(R.string.title_activity_about));
        userInfoAdapter = new UserProfileAdapter(getActivity(), userInfoList, 0);
        rvUserInfo.setAdapter(userInfoAdapter);
    }

    private void getSharingRequests() {

        pendingRequests.clear();
        ApiManager apiManager = ApiManager.getInstance(espApp);
        apiManager.getSharingRequests(false, new ApiResponseListener() {

            @Override
            public void onSuccess(Bundle data) {

                if (data != null) {
                    ArrayList<SharingRequest> requests = data.getParcelableArrayList(AppConstants.KEY_SHARING_REQUESTS);
                    if (requests != null && requests.size() > 0) {
                        for (int i = 0; i < requests.size(); i++) {
                            SharingRequest req = requests.get(i);
                            if (AppConstants.KEY_REQ_STATUS_PENDING.equals(req.getReqStatus())) {
                                pendingRequests.add(req);
                            }
                        }
                    }
                }
                int count = pendingRequests.size();
                userInfoAdapter.updatePendingRequestCount(count);
            }

            @Override
            public void onResponseFailure(Exception exception) {
            }

            @Override
            public void onNetworkFailure(Exception exception) {
            }
        });
    }

    private void confirmLogout() {

        AlertDialog.Builder builder = new AlertDialog.Builder(getActivity());
        builder.setTitle(R.string.dialog_title_logout);
        builder.setMessage(R.string.dialog_msg_confirmation);

        builder.setPositiveButton(R.string.btn_yes, new DialogInterface.OnClickListener() {

            @Override
            public void onClick(DialogInterface dialog, int which) {

                dialog.dismiss();
                espApp.logout();
            }
        });

        builder.setNegativeButton(R.string.btn_no, new DialogInterface.OnClickListener() {

            @Override
            public void onClick(DialogInterface dialog, int which) {

                dialog.dismiss();
            }
        });

        AlertDialog userDialog = builder.create();
        userDialog.show();
    }
}
