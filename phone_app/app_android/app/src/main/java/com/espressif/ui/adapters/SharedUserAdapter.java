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
import android.content.DialogInterface;
import android.os.Bundle;
import android.text.TextUtils;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AlertDialog;
import androidx.core.widget.ContentLoadingProgressBar;
import androidx.recyclerview.widget.RecyclerView;

import com.espressif.AppConstants;
import com.espressif.cloudapi.ApiManager;
import com.espressif.cloudapi.ApiResponseListener;
import com.espressif.cloudapi.CloudException;
import com.espressif.rainmaker.R;
import com.espressif.ui.Utils;
import com.espressif.ui.activities.NodeDetailsActivity;
import com.espressif.ui.models.EspNode;
import com.espressif.ui.models.SharingRequest;

import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.concurrent.TimeUnit;

public class SharedUserAdapter extends RecyclerView.Adapter<RecyclerView.ViewHolder> {

    private final String TAG = SharedUserAdapter.class.getSimpleName();

    private final int VIEW_TYPE_ADD_MEMBER = 1;
    private final int VIEW_TYPE_SECONDARY_MEMBER = 2;
    private final int VIEW_TYPE_PENDING_REQUEST = 3;

    private Context context;
    private EspNode node;
    private ArrayList<String> users;
    private ArrayList<SharingRequest> pendingRequests;
    private ApiManager apiManager;
    private boolean isPendingReqView;

    public SharedUserAdapter(Context context, EspNode node, ArrayList<SharingRequest> sharingRequests, boolean isPendingReqAdapter) {
        this.context = context;
        this.node = node;
        this.pendingRequests = sharingRequests;
        this.isPendingReqView = isPendingReqAdapter;
        apiManager = ApiManager.getInstance(context);
        String userRole = node.getUserRole();

        if (!TextUtils.isEmpty(userRole)) {
            if (userRole.equals(AppConstants.KEY_USER_ROLE_PRIMARY)) {
                users = node.getSecondaryUsers();
            } else {
                users = new ArrayList<>();
                users.add(node.getPrimaryUsers().get(0));
            }
        }
    }

    @Override
    public RecyclerView.ViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {

        LayoutInflater layoutInflater = LayoutInflater.from(context);
        switch (viewType) {
            case VIEW_TYPE_ADD_MEMBER:
                View addMemberView = layoutInflater.inflate(R.layout.item_add_user, parent, false);
                return new AddMemberViewHolder(addMemberView);

            case VIEW_TYPE_SECONDARY_MEMBER:
                View memberView = layoutInflater.inflate(R.layout.item_shared_user, parent, false);
                return new MemberViewHolder(memberView);

            case VIEW_TYPE_PENDING_REQUEST:
                View pendingReqView = layoutInflater.inflate(R.layout.item_shared_user, parent, false);
                return new PendingRequestViewHolder(pendingReqView);
        }
        return null;
    }

    @Override
    public int getItemViewType(int position) {

        if (isPendingReqView) {
            return VIEW_TYPE_PENDING_REQUEST;
        } else {
            if (position == users.size()) {
                return VIEW_TYPE_ADD_MEMBER;
            } else {
                return VIEW_TYPE_SECONDARY_MEMBER;
            }
        }
    }

    @Override
    public void onBindViewHolder(@NonNull final RecyclerView.ViewHolder holder, final int position) {

        switch (holder.getItemViewType()) {

            case VIEW_TYPE_ADD_MEMBER:
                final AddMemberViewHolder addMemberViewHolder = (AddMemberViewHolder) holder;
                addMemberViewHolder.itemView.setOnClickListener(new View.OnClickListener() {
                    @Override
                    public void onClick(View v) {
                        askForUserEmail(addMemberViewHolder);
                    }
                });
                break;

            case VIEW_TYPE_SECONDARY_MEMBER:
                final MemberViewHolder memberViewHolder = (MemberViewHolder) holder;

                if (node.getUserRole().equals(AppConstants.KEY_USER_ROLE_PRIMARY)) {
                    memberViewHolder.tvMemberEmail.setText(users.get(position));
                    memberViewHolder.ivRemoveMember.setOnClickListener(new View.OnClickListener() {
                        @Override
                        public void onClick(View v) {
                            confirmForRemoveNodeSharing(memberViewHolder, users.get(position));
                        }
                    });
                } else {
                    memberViewHolder.ivRemoveMember.setVisibility(View.GONE);
                    memberViewHolder.tvMemberEmail.setText(users.get(position));
                }
                break;

            case VIEW_TYPE_PENDING_REQUEST:

                SharingRequest pendingReq = pendingRequests.get(position);
                final PendingRequestViewHolder pendingRequestViewHolder = (PendingRequestViewHolder) holder;
                pendingRequestViewHolder.tvMemberEmail.setText(pendingReq.getUserName());

                if (pendingReq.getReqTime() != 0) {

                    int remainingDDays = getRemainingDays(pendingReq.getReqTime());
                    String timeStampString = context.getString(R.string.expires_in);
                    timeStampString = timeStampString + " " + remainingDDays;
                    timeStampString = timeStampString + " " + context.getString(R.string.expire_days);
                    pendingRequestViewHolder.tvExpireTime.setText(timeStampString);
                    pendingRequestViewHolder.tvExpireTime.setVisibility(View.VISIBLE);
                } else {
                    pendingRequestViewHolder.tvExpireTime.setVisibility(View.GONE);
                }

                pendingRequestViewHolder.ivRemoveMember.setOnClickListener(new View.OnClickListener() {
                    @Override
                    public void onClick(View v) {
                        confirmForRemoveNodeSharingRequest(pendingRequestViewHolder, pendingRequests.get(position));
                    }
                });
                break;
        }
    }

    @Override
    public int getItemCount() {

        if (isPendingReqView) {
            return pendingRequests.size();
        } else {
            if (node.getUserRole().equals(AppConstants.KEY_USER_ROLE_PRIMARY)) {
                return users.size() + 1;
            } else {
                return users.size();
            }
        }
    }

    public void updatePendingRequestList(ArrayList<SharingRequest> requests) {
        this.pendingRequests = requests;
        notifyDataSetChanged();
    }

    static class MemberViewHolder extends RecyclerView.ViewHolder {

        TextView tvMemberEmail;
        ImageView ivRemoveMember;
        ContentLoadingProgressBar loadingRemoveMember;

        public MemberViewHolder(View itemView) {
            super(itemView);

            tvMemberEmail = itemView.findViewById(R.id.tv_member_email);
            ivRemoveMember = itemView.findViewById(R.id.iv_remove_member);
            loadingRemoveMember = itemView.findViewById(R.id.progress_remove_member);
            ivRemoveMember.setVisibility(View.VISIBLE);
            loadingRemoveMember.setVisibility(View.GONE);
        }
    }

    static class AddMemberViewHolder extends RecyclerView.ViewHolder {

        ImageView ivRightArrow;
        ContentLoadingProgressBar loadingAddMember;

        public AddMemberViewHolder(View itemView) {
            super(itemView);
            ivRightArrow = itemView.findViewById(R.id.iv_right_arrow);
            loadingAddMember = itemView.findViewById(R.id.progress_add_member);
        }
    }

    static class PendingRequestViewHolder extends RecyclerView.ViewHolder {

        TextView tvMemberEmail, tvExpireTime;
        ImageView ivRemoveMember;
        ContentLoadingProgressBar loadingRemoveMember;

        public PendingRequestViewHolder(View itemView) {
            super(itemView);

            tvMemberEmail = itemView.findViewById(R.id.tv_member_email);
            tvExpireTime = itemView.findViewById(R.id.pr_time);
            ivRemoveMember = itemView.findViewById(R.id.iv_remove_member);
            loadingRemoveMember = itemView.findViewById(R.id.progress_remove_member);
            ivRemoveMember.setVisibility(View.VISIBLE);
            loadingRemoveMember.setVisibility(View.GONE);
        }
    }

    private void askForUserEmail(final AddMemberViewHolder addMemberViewHolder) {

        final AlertDialog.Builder builder = new AlertDialog.Builder(context);
        LayoutInflater inflater = LayoutInflater.from(context);
        final View dialogView = inflater.inflate(R.layout.dialog_user_email, null);
        builder.setView(dialogView);

        final EditText etEmail = dialogView.findViewById(R.id.et_email);
        builder.setTitle(R.string.dialog_title_user_email);

        builder.setPositiveButton(R.string.btn_add, new DialogInterface.OnClickListener() {

            @Override
            public void onClick(DialogInterface dialog, int which) {

                final String email = etEmail.getText().toString();
                if (TextUtils.isEmpty(email)) {
                    etEmail.setError(context.getString(R.string.error_email_empty));
                } else if (!Utils.isValidEmail(email)) {
                    etEmail.setError(context.getString(R.string.error_invalid_email));
                } else {
                    dialog.dismiss();
                    addMemberViewHolder.ivRightArrow.setVisibility(View.GONE);
                    addMemberViewHolder.loadingAddMember.setVisibility(View.VISIBLE);
                    apiManager.shareNodeWithUser(node.getNodeId(), email, new ApiResponseListener() {

                        @Override
                        public void onSuccess(Bundle data) {
                            if (data != null) {
                                String reqId = data.getString(AppConstants.KEY_REQ_ID);
                                SharingRequest request = new SharingRequest(reqId);
                                request.setUserName(email);
                                long timestampInSec = TimeUnit.SECONDS.convert(System.currentTimeMillis(), TimeUnit.MILLISECONDS);
                                request.setReqTime(timestampInSec);
                                ((NodeDetailsActivity) context).addPendingRequest(request);
                            }
                            addMemberViewHolder.ivRightArrow.setVisibility(View.VISIBLE);
                            addMemberViewHolder.loadingAddMember.setVisibility(View.GONE);
                        }

                        @Override
                        public void onResponseFailure(Exception exception) {
                            addMemberViewHolder.ivRightArrow.setVisibility(View.VISIBLE);
                            addMemberViewHolder.loadingAddMember.setVisibility(View.GONE);
                            exception.printStackTrace();

                            if (exception instanceof CloudException) {
                                Toast.makeText(context, exception.getMessage(), Toast.LENGTH_SHORT).show();
                            } else {
                                Toast.makeText(context, R.string.error_add_member, Toast.LENGTH_SHORT).show();
                            }
                        }

                        @Override
                        public void onNetworkFailure(Exception exception) {
                            addMemberViewHolder.ivRightArrow.setVisibility(View.VISIBLE);
                            addMemberViewHolder.loadingAddMember.setVisibility(View.GONE);
                            exception.printStackTrace();

                            if (exception instanceof CloudException) {
                                Toast.makeText(context, exception.getMessage(), Toast.LENGTH_SHORT).show();
                            } else {
                                Toast.makeText(context, R.string.error_add_member, Toast.LENGTH_SHORT).show();
                            }
                        }
                    });
                }
            }
        });

        builder.setNegativeButton(R.string.btn_cancel, new DialogInterface.OnClickListener() {

            @Override
            public void onClick(DialogInterface dialog, int which) {

                dialog.dismiss();
            }
        });

        AlertDialog alertDialog = builder.create();
        alertDialog.show();
    }

    private void confirmForRemoveNodeSharing(final MemberViewHolder memberViewHolder, final String email) {

        AlertDialog.Builder builder = new AlertDialog.Builder(context);
        builder.setMessage(R.string.dialog_msg_delete_node);

        // Set up the buttons
        builder.setPositiveButton(R.string.btn_yes, new DialogInterface.OnClickListener() {

            @Override
            public void onClick(DialogInterface dialog, int which) {

                dialog.dismiss();
                removeNodeSharing(memberViewHolder, email);
            }
        });

        builder.setNegativeButton(R.string.btn_no, new DialogInterface.OnClickListener() {

            @Override
            public void onClick(DialogInterface dialog, int which) {

                dialog.dismiss();
            }
        });

        AlertDialog alertDialog = builder.create();
        alertDialog.show();
    }

    private void confirmForRemoveNodeSharingRequest(final PendingRequestViewHolder pendingReqViewHolder, final SharingRequest sharingRequest) {

        AlertDialog.Builder builder = new AlertDialog.Builder(context);
        builder.setMessage(R.string.dialog_msg_delete_node);

        // Set up the buttons
        builder.setPositiveButton(R.string.btn_yes, new DialogInterface.OnClickListener() {

            @Override
            public void onClick(DialogInterface dialog, int which) {

                dialog.dismiss();
                removeSharingRequest(pendingReqViewHolder, sharingRequest);
            }
        });

        builder.setNegativeButton(R.string.btn_no, new DialogInterface.OnClickListener() {

            @Override
            public void onClick(DialogInterface dialog, int which) {

                dialog.dismiss();
            }
        });

        AlertDialog alertDialog = builder.create();
        alertDialog.show();
    }

    private void removeNodeSharing(final MemberViewHolder memberViewHolder, String email) {

        memberViewHolder.ivRemoveMember.setVisibility(View.GONE);
        memberViewHolder.loadingRemoveMember.setVisibility(View.VISIBLE);

        apiManager.removeSharing(node.getNodeId(), email, new ApiResponseListener() {

            @Override
            public void onSuccess(Bundle data) {
                memberViewHolder.ivRemoveMember.setVisibility(View.VISIBLE);
                memberViewHolder.loadingRemoveMember.setVisibility(View.GONE);
                updateMemberList();
            }

            @Override
            public void onResponseFailure(Exception exception) {
                memberViewHolder.ivRemoveMember.setVisibility(View.VISIBLE);
                memberViewHolder.loadingRemoveMember.setVisibility(View.GONE);
                exception.printStackTrace();
                if (exception instanceof CloudException) {
                    Toast.makeText(context, exception.getMessage(), Toast.LENGTH_SHORT).show();
                } else {
                    Toast.makeText(context, R.string.error_remove_member, Toast.LENGTH_SHORT).show();
                }
            }

            @Override
            public void onNetworkFailure(Exception exception) {
                memberViewHolder.ivRemoveMember.setVisibility(View.VISIBLE);
                memberViewHolder.loadingRemoveMember.setVisibility(View.GONE);
                exception.printStackTrace();
                if (exception instanceof CloudException) {
                    Toast.makeText(context, exception.getMessage(), Toast.LENGTH_SHORT).show();
                } else {
                    Toast.makeText(context, R.string.error_remove_member, Toast.LENGTH_SHORT).show();
                }
            }
        });
    }

    private void removeSharingRequest(final PendingRequestViewHolder memberViewHolder, SharingRequest sharingRequest) {

        memberViewHolder.ivRemoveMember.setVisibility(View.GONE);
        memberViewHolder.loadingRemoveMember.setVisibility(View.VISIBLE);

        apiManager.removeSharingRequest(sharingRequest.getReqId(), new ApiResponseListener() {

            @Override
            public void onSuccess(Bundle data) {
                memberViewHolder.ivRemoveMember.setVisibility(View.VISIBLE);
                memberViewHolder.loadingRemoveMember.setVisibility(View.GONE);
                pendingRequests.remove(memberViewHolder.getAdapterPosition());
                if (pendingRequests.size() == 0) {
                    ((NodeDetailsActivity) context).clearPendingRequest();
                }
                updatePendingRequestList(pendingRequests);
            }

            @Override
            public void onResponseFailure(Exception exception) {
                memberViewHolder.ivRemoveMember.setVisibility(View.VISIBLE);
                memberViewHolder.loadingRemoveMember.setVisibility(View.GONE);
                exception.printStackTrace();
                if (exception instanceof CloudException) {
                    Toast.makeText(context, exception.getMessage(), Toast.LENGTH_SHORT).show();
                } else {
                    Toast.makeText(context, R.string.error_remove_sharing_req, Toast.LENGTH_SHORT).show();
                }
            }

            @Override
            public void onNetworkFailure(Exception exception) {
                memberViewHolder.ivRemoveMember.setVisibility(View.VISIBLE);
                memberViewHolder.loadingRemoveMember.setVisibility(View.GONE);
                exception.printStackTrace();
                if (exception instanceof CloudException) {
                    Toast.makeText(context, exception.getMessage(), Toast.LENGTH_SHORT).show();
                } else {
                    Toast.makeText(context, R.string.error_remove_sharing_req, Toast.LENGTH_SHORT).show();
                }
            }
        });
    }

    private void updateMemberList() {
        users = node.getSecondaryUsers();
        notifyDataSetChanged();
    }

    private int getRemainingDays(long timestamp) {

        int remainingDays = 7;
        SimpleDateFormat formatter = new SimpleDateFormat("dd/MM/yyyy");

        Date date = new Date(timestamp * 1000);
        String pendingReqDate = formatter.format(date);
        String currentDate = formatter.format(new Date());
        Log.d(TAG, "Pending request date : " + pendingReqDate + " and current Date :" + currentDate);
        Date date1 = null, date2 = null;
        try {
            date1 = formatter.parse(pendingReqDate);
            date2 = formatter.parse(currentDate);
        } catch (ParseException e) {
            e.printStackTrace();
        }

        long diff = date2.getTime() - date1.getTime();
        long diffInDays = TimeUnit.DAYS.convert(diff, TimeUnit.MILLISECONDS);
        remainingDays = (int) (7 - diffInDays);
        return remainingDays;
    }
}
