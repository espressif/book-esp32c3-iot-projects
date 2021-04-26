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

package com.espressif.ui.fragments;

import android.content.DialogInterface;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.appcompat.app.AlertDialog;
import androidx.core.widget.ContentLoadingProgressBar;
import androidx.fragment.app.Fragment;

import com.espressif.rainmaker.R;
import com.espressif.ui.user_module.DeleteUserActivity;
import com.google.android.material.card.MaterialCardView;

public class DeleteUserRequestFragment extends Fragment {

    private MaterialCardView btnDeleteUser;
    private TextView txtDeleteUserBtn;
    private ContentLoadingProgressBar progressBar;

    public DeleteUserRequestFragment() {
        // Required empty public constructor
    }

    public static DeleteUserRequestFragment newInstance() {
        return new DeleteUserRequestFragment();
    }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        // Inflate the layout for this fragment
        View rootView = inflater.inflate(R.layout.fragment_delete_user_req, container, false);
        initViews(rootView);
        return rootView;
    }

    private View.OnClickListener deleteUserBtnClickListener = new View.OnClickListener() {

        @Override
        public void onClick(View v) {
            displayWarningDeleteAccount();
        }
    };

    private void initViews(View view) {

        btnDeleteUser = view.findViewById(R.id.btn_delete_user);
        txtDeleteUserBtn = view.findViewById(R.id.text_btn);
        progressBar = view.findViewById(R.id.progress_indicator);
        btnDeleteUser.setOnClickListener(deleteUserBtnClickListener);
    }

    private void deleteUser() {
        showLoading();
        ((DeleteUserActivity) getActivity()).sendDeleteUserRequest();
    }

    private void showLoading() {
        btnDeleteUser.setEnabled(false);
        btnDeleteUser.setAlpha(0.5f);
        txtDeleteUserBtn.setText(R.string.btn_deleting_user);
        progressBar.setVisibility(View.VISIBLE);
    }

    public void hideLoading() {
        btnDeleteUser.setEnabled(true);
        btnDeleteUser.setAlpha(1f);
        txtDeleteUserBtn.setText(R.string.btn_delete_user);
        progressBar.setVisibility(View.GONE);
    }

    private void displayWarningDeleteAccount() {

        AlertDialog.Builder builder = new AlertDialog.Builder(getActivity());
        builder.setTitle(R.string.dialog_title_delete_user);
        builder.setMessage(R.string.dialog_msg_delete_user);

        // Set up the buttons
        builder.setPositiveButton(R.string.btn_proceed, new DialogInterface.OnClickListener() {

            @Override
            public void onClick(DialogInterface dialog, int which) {
                dialog.dismiss();
                deleteUser();
            }
        });

        builder.setNegativeButton(R.string.btn_cancel, new DialogInterface.OnClickListener() {

            @Override
            public void onClick(DialogInterface dialog, int which) {
                dialog.dismiss();
            }
        });

        AlertDialog userDialog = builder.create();
        userDialog.show();
    }
}
