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

import android.app.Activity;
import android.os.Bundle;
import android.text.TextUtils;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.espressif.AppConstants;
import com.espressif.cloudapi.ApiManager;
import com.espressif.cloudapi.ApiResponseListener;
import com.espressif.cloudapi.CloudException;
import com.espressif.rainmaker.R;
import com.espressif.ui.activities.NotificationsActivity;
import com.espressif.ui.models.SharingRequest;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;

public class SharingRequestAdapter extends RecyclerView.Adapter<SharingRequestAdapter.SharingRequestVH> {

    private final String TAG = SharingRequestAdapter.class.getSimpleName();

    private Activity context;
    private ApiManager apiManager;
    private ArrayList<SharingRequest> pendingRequests;

    public SharingRequestAdapter(Activity context, ArrayList<SharingRequest> pendingRequests) {
        this.context = context;
        this.pendingRequests = pendingRequests;
        this.apiManager = ApiManager.getInstance(context);
    }

    @NonNull
    @Override
    public SharingRequestVH onCreateViewHolder(ViewGroup parent, int viewType) {

        LayoutInflater layoutInflater = LayoutInflater.from(context);
        View sharingReqView = layoutInflater.inflate(R.layout.item_sharing_request, parent, false);
        SharingRequestVH sharingRequestVH = new SharingRequestVH(sharingReqView);
        return sharingRequestVH;
    }

    @Override
    public void onBindViewHolder(@NonNull final SharingRequestVH sharingRequestVH, final int position) {

        SharingRequest sharingReq = pendingRequests.get(position);
        StringBuilder text = new StringBuilder();
        text.append(pendingRequests.get(position).getPrimaryUserName());
        Log.d(TAG, "Sharing request metadata : " + sharingReq.getMetadata());

        if (!TextUtils.isEmpty(sharingReq.getMetadata())) {

            String metadata = sharingReq.getMetadata();

            try {
                JSONObject metadataJson = new JSONObject(metadata);
                JSONArray deviceJsonArray = metadataJson.optJSONArray(AppConstants.KEY_DEVICES);

                if (deviceJsonArray != null) {

                    text.append(" ");
                    text.append(context.getString(R.string.wants_to_share));
                    ArrayList<String> deviceNames = new ArrayList<>();

                    for (int i = 0; i < deviceJsonArray.length(); i++) {
                        JSONObject deviceObj = deviceJsonArray.optJSONObject(i);
                        if (deviceObj != null) {
                            String deviceName = deviceObj.optString(AppConstants.KEY_NAME);
                            deviceNames.add(deviceName);
                        }
                    }

                    int deviceListSize = deviceNames.size();
                    if (deviceListSize == 0) {
                        text = new StringBuilder();
                        text.append(displayGeneralText(sharingReq));
                    } else if (deviceListSize == 1) {
                        text.append(" ");
                        text.append(deviceNames.get(0));
                    } else {

                        for (int i = 0; i < deviceNames.size(); i++) {
                            text.append(" ");
                            if (i == (deviceListSize - 1)) {
                                text.append(context.getString(R.string.and));
                                text.append(" ");
                                text.append(deviceNames.get(i));
                            } else {
                                text.append(deviceNames.get(i));
                                text.append(",");
                            }
                        }
                    }

                    text.append(" ");
                    if (deviceListSize > 1) {
                        text.append(context.getString(R.string.devices));
                    } else {
                        text.append(context.getString(R.string.device));
                    }
                    text.append(" ");
                    text.append(context.getString(R.string.with_you));
                    text.append(".");

                } else {
                    text = new StringBuilder();
                    text.append(displayGeneralText(sharingReq));
                }
            } catch (JSONException e) {
                e.printStackTrace();
            }
        } else {
            text = new StringBuilder();
            text.append(displayGeneralText(sharingReq));
        }

        sharingRequestVH.tvSharingText.setText(text.toString());

        sharingRequestVH.layoutBtnAccept.setOnClickListener(new View.OnClickListener() {

            @Override
            public void onClick(View v) {
                ((NotificationsActivity) context).showLoading(context.getString(R.string.progress_accepting));

                apiManager.updateSharingRequest(pendingRequests.get(position).getReqId(), true, new ApiResponseListener() {

                    @Override
                    public void onSuccess(Bundle data) {
                        pendingRequests.remove(position);
                        notifyDataSetChanged();
                        if (pendingRequests.size() == 0) {
                            ((NotificationsActivity) context).clearPendingRequest();
                        }
                        ((NotificationsActivity) context).hideLoading();
                    }

                    @Override
                    public void onResponseFailure(Exception exception) {
                        if (exception instanceof CloudException) {
                            Toast.makeText(context, exception.getMessage(), Toast.LENGTH_SHORT).show();
                        } else {
                            Toast.makeText(context, R.string.error_get_sharing_request, Toast.LENGTH_SHORT).show();
                        }
                        ((NotificationsActivity) context).hideLoading();
                    }

                    @Override
                    public void onNetworkFailure(Exception exception) {
                        if (exception instanceof CloudException) {
                            Toast.makeText(context, exception.getMessage(), Toast.LENGTH_SHORT).show();
                        } else {
                            Toast.makeText(context, R.string.error_get_sharing_request, Toast.LENGTH_SHORT).show();
                        }
                        ((NotificationsActivity) context).hideLoading();
                    }
                });
            }
        });

        sharingRequestVH.layoutBtnDecline.setOnClickListener(new View.OnClickListener() {

            @Override
            public void onClick(View v) {
                ((NotificationsActivity) context).showLoading(context.getString(R.string.progress_declining));

                apiManager.updateSharingRequest(pendingRequests.get(position).getReqId(), false, new ApiResponseListener() {
                    @Override
                    public void onSuccess(Bundle data) {
                        pendingRequests.remove(position);
                        notifyDataSetChanged();
                        if (pendingRequests.size() == 0) {
                            ((NotificationsActivity) context).clearPendingRequest();
                        }
                        ((NotificationsActivity) context).hideLoading();
                    }

                    @Override
                    public void onResponseFailure(Exception exception) {
                        if (exception instanceof CloudException) {
                            Toast.makeText(context, exception.getMessage(), Toast.LENGTH_SHORT).show();
                        } else {
                            Toast.makeText(context, R.string.error_get_sharing_request, Toast.LENGTH_SHORT).show();
                        }
                        ((NotificationsActivity) context).hideLoading();
                    }

                    @Override
                    public void onNetworkFailure(Exception exception) {
                        if (exception instanceof CloudException) {
                            Toast.makeText(context, exception.getMessage(), Toast.LENGTH_SHORT).show();
                        } else {
                            Toast.makeText(context, R.string.error_get_sharing_request, Toast.LENGTH_SHORT).show();
                        }
                        ((NotificationsActivity) context).hideLoading();
                    }
                });
            }
        });
    }

    private String displayGeneralText(SharingRequest request) {

        StringBuilder text = new StringBuilder();
        text.append(request.getPrimaryUserName());
        text.append(" ");
        text.append(context.getString(R.string.wants_to_share));
        text.append(" ");
        text.append(context.getString(R.string.node));
        text.append(" ");

        ArrayList<String> nodeIds = request.getNodeIds();
        for (int i = 0; i < nodeIds.size(); i++) {

            if (i == 0) {
                text.append(nodeIds.get(i));
            } else {
                text.append(", ");
                text.append(nodeIds.get(i));
            }
        }

        text.append(" ");
        text.append(context.getString(R.string.with_you));
        text.append(".");
        return text.toString();
    }

    @Override
    public int getItemCount() {
        return pendingRequests.size();
    }

    static class SharingRequestVH extends RecyclerView.ViewHolder {

        TextView tvSharingText;
        TextView layoutBtnAccept, layoutBtnDecline;

        public SharingRequestVH(View itemView) {
            super(itemView);

            tvSharingText = itemView.findViewById(R.id.tv_sharing_text);
            layoutBtnAccept = itemView.findViewById(R.id.btn_accept);
            layoutBtnDecline = itemView.findViewById(R.id.btn_decline);
        }
    }
}
