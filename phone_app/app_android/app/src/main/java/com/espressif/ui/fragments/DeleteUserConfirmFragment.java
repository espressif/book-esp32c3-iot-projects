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
import android.text.TextUtils;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.EditText;
import android.widget.TextView;

import androidx.appcompat.app.AlertDialog;
import androidx.core.widget.ContentLoadingProgressBar;
import androidx.fragment.app.Fragment;

import com.espressif.rainmaker.R;
import com.espressif.ui.user_module.DeleteUserActivity;
import com.google.android.material.card.MaterialCardView;

public class DeleteUserConfirmFragment extends Fragment {

    private EditText etVerificationCode;
    private MaterialCardView btnConfirmDelete;
    private TextView txtConfirmDeleteBtn;
    private ContentLoadingProgressBar progressBar;

    public DeleteUserConfirmFragment() {
        // Required empty public constructor
    }

    public static DeleteUserConfirmFragment newInstance() {
        return new DeleteUserConfirmFragment();
    }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        // Inflate the layout for this fragment
        View rootView = inflater.inflate(R.layout.fragment_delete_user_confirm, container, false);
        init(rootView);
        return rootView;
    }

    private View.OnClickListener deleteBtnClickListener = new View.OnClickListener() {

        @Override
        public void onClick(View v) {
            if (!isCodeEmpty()) {
                confirmDeleteAccount();
            }
        }
    };

    private void init(View view) {

        etVerificationCode = view.findViewById(R.id.et_verification_code);
        btnConfirmDelete = view.findViewById(R.id.btn_delete_account_confirm);
        txtConfirmDeleteBtn = view.findViewById(R.id.text_btn);
        progressBar = view.findViewById(R.id.progress_indicator);

        txtConfirmDeleteBtn.setText(R.string.btn_confirm);
        btnConfirmDelete.setOnClickListener(deleteBtnClickListener);
    }

    private boolean isCodeEmpty() {
        String verCode = etVerificationCode.getText().toString();
        if (TextUtils.isEmpty(verCode)) {
            etVerificationCode.setError(getString(R.string.error_verification_code_empty));
            return true;
        }
        return false;
    }

    private void deleteAccount() {

        String verCode = etVerificationCode.getText().toString();
        if (!TextUtils.isEmpty(verCode)) {
            showLoading();
            ((DeleteUserActivity) getActivity()).confirmDeleteAccount(verCode);
        }
    }

    private void showLoading() {
        btnConfirmDelete.setEnabled(false);
        btnConfirmDelete.setAlpha(0.5f);
        txtConfirmDeleteBtn.setText(R.string.btn_deleting_user);
        progressBar.setVisibility(View.VISIBLE);
    }

    public void hideLoading() {
        btnConfirmDelete.setEnabled(true);
        btnConfirmDelete.setAlpha(1f);
        txtConfirmDeleteBtn.setText(R.string.btn_delete_user_confirm);
        progressBar.setVisibility(View.GONE);
    }

    private void confirmDeleteAccount() {

        AlertDialog.Builder builder = new AlertDialog.Builder(getActivity());
        builder.setTitle(R.string.dialog_msg_confirmation);

        // Set up the buttons
        builder.setPositiveButton(R.string.btn_yes, new DialogInterface.OnClickListener() {

            @Override
            public void onClick(DialogInterface dialog, int which) {
                dialog.dismiss();
                deleteAccount();
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
