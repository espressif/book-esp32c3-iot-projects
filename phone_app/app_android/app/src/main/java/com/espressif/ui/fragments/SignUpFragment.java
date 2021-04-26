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

import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.text.Editable;
import android.text.SpannableString;
import android.text.Spanned;
import android.text.TextPaint;
import android.text.TextUtils;
import android.text.TextWatcher;
import android.text.method.LinkMovementMethod;
import android.text.style.ClickableSpan;
import android.view.KeyEvent;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.view.inputmethod.EditorInfo;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;

import androidx.appcompat.widget.AppCompatCheckBox;
import androidx.core.widget.ContentLoadingProgressBar;
import androidx.fragment.app.Fragment;

import com.espressif.AppConstants;
import com.espressif.cloudapi.ApiManager;
import com.espressif.cloudapi.ApiResponseListener;
import com.espressif.cloudapi.CloudException;
import com.espressif.rainmaker.BuildConfig;
import com.espressif.rainmaker.R;
import com.espressif.ui.Utils;
import com.espressif.ui.activities.MainActivity;
import com.espressif.ui.user_module.SignUpConfirmActivity;
import com.google.android.material.card.MaterialCardView;
import com.google.android.material.textfield.TextInputEditText;
import com.google.android.material.textfield.TextInputLayout;

public class SignUpFragment extends Fragment {

    private static final String TAG = SignUpFragment.class.getSimpleName();

    private EditText etEmail;
    private TextInputEditText etPassword;
    private TextInputEditText etConfirmPassword;
    private TextInputLayout layoutPassword;
    private TextInputLayout layoutConfirmPassword;
    private AppCompatCheckBox cbTermsCondition;
    private MaterialCardView btnRegister;
    private TextView txtRegisterBtn;
    private ImageView arrowImage;
    private ContentLoadingProgressBar progressBar;
    private TextView tvPolicy;

    private String email, password, confirmPassword;

    public SignUpFragment() {
        // Required empty public constructor
    }

    public static SignUpFragment newInstance() {
        return new SignUpFragment();
    }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {

        // Inflate the layout for this fragment
        View rootView = inflater.inflate(R.layout.fragment_signup, container, false);
        init(rootView);
        return rootView;
    }

    private View.OnClickListener registerBtnClickListener = new View.OnClickListener() {

        @Override
        public void onClick(View v) {
            doSignUp();
        }
    };

    private void doSignUp() {

        etEmail.setError(null);
        layoutPassword.setError(null);
        layoutConfirmPassword.setError(null);

        email = etEmail.getText().toString();
        if (TextUtils.isEmpty(email)) {

            etEmail.setError(getString(R.string.error_email_empty));
            return;

        } else if (!Utils.isValidEmail(email)) {

            etEmail.setError(getString(R.string.error_invalid_email));
            return;
        }

        password = etPassword.getText().toString();
        if (TextUtils.isEmpty(password)) {

            layoutPassword.setError(getString(R.string.error_password_empty));
            return;
        }

        confirmPassword = etConfirmPassword.getText().toString();
        if (TextUtils.isEmpty(confirmPassword)) {

            layoutConfirmPassword.setError(getString(R.string.error_confirm_password_empty));
            return;
        }

        if (!password.equals(confirmPassword)) {

            layoutConfirmPassword.setError(getString(R.string.error_password_not_matched));
            return;
        }

        if (!cbTermsCondition.isChecked()) {

            Toast.makeText(getActivity(), R.string.error_agree_terms_n_condition, Toast.LENGTH_SHORT).show();
            return;
        }

        showLoading();
        ApiManager apiManager = ApiManager.getInstance(getActivity());
        apiManager.createUser(email, password, new ApiResponseListener() {

            @Override
            public void onSuccess(Bundle data) {
                hideLoading();
                confirmSignUp(email, password);
            }

            @Override
            public void onResponseFailure(Exception exception) {
                hideLoading();
                if (exception instanceof CloudException) {
                    Utils.showAlertDialog(getActivity(), getString(R.string.dialog_title_sign_up_failed), exception.getMessage(), false);
                } else {
                    Utils.showAlertDialog(getActivity(), "", getString(R.string.dialog_title_sign_up_failed), false);
                }
            }

            @Override
            public void onNetworkFailure(Exception exception) {
                hideLoading();
                Utils.showAlertDialog(getActivity(), getString(R.string.dialog_title_no_network), getString(R.string.dialog_msg_no_network), false);
            }
        });
    }

    private void init(View view) {

        txtRegisterBtn = view.findViewById(R.id.text_btn);
        arrowImage = view.findViewById(R.id.iv_arrow);
        progressBar = view.findViewById(R.id.progress_indicator);
        tvPolicy = view.findViewById(R.id.tv_terms_condition);

        SpannableString stringForPolicy = new SpannableString(getString(R.string.read_terms_condition));

        ClickableSpan privacyPolicyClick = new ClickableSpan() {

            @Override
            public void onClick(View textView) {
                textView.invalidate();
                Intent openURL = new Intent(Intent.ACTION_VIEW, Uri.parse(BuildConfig.PRIVACY_URL));
                startActivity(openURL);
            }

            @Override
            public void updateDrawState(TextPaint ds) {
                super.updateDrawState(ds);
                ds.setColor(getResources().getColor(R.color.colorPrimary));
                ds.setUnderlineText(true);
            }
        };

        ClickableSpan termsOfUseClick = new ClickableSpan() {

            @Override
            public void onClick(View textView) {
                textView.invalidate();
                Intent openURL = new Intent(Intent.ACTION_VIEW, Uri.parse(BuildConfig.TERMS_URL));
                startActivity(openURL);
            }

            @Override
            public void updateDrawState(TextPaint ds) {
                super.updateDrawState(ds);
                ds.setColor(getResources().getColor(R.color.colorPrimary));
                ds.setUnderlineText(true);
            }
        };

        stringForPolicy.setSpan(privacyPolicyClick, 29, 43, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE);
        stringForPolicy.setSpan(termsOfUseClick, 48, 60, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE);

        tvPolicy.setText(stringForPolicy);
        tvPolicy.setMovementMethod(LinkMovementMethod.getInstance());

        // Email
        etEmail = view.findViewById(R.id.et_email);
        etEmail.addTextChangedListener(new TextWatcher() {

            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {
            }

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {
            }

            @Override
            public void afterTextChanged(Editable s) {
                if (s != null) {
                    email = s.toString();
                }
                enableRegisterButton();
            }
        });

        // Password
        layoutPassword = view.findViewById(R.id.layout_password);
        etPassword = view.findViewById(R.id.et_password);
        etPassword.addTextChangedListener(new TextWatcher() {

            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {
            }

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {
            }

            @Override
            public void afterTextChanged(Editable s) {
                if (s != null) {
                    password = s.toString();
                }
                enableRegisterButton();
            }
        });

        // Confirm Password
        layoutConfirmPassword = view.findViewById(R.id.layout_confirm_password);
        etConfirmPassword = view.findViewById(R.id.et_confirm_password);
        etConfirmPassword.addTextChangedListener(new TextWatcher() {

            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {
            }

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {
            }

            @Override
            public void afterTextChanged(Editable s) {
                if (s != null) {
                    confirmPassword = s.toString();
                }
                enableRegisterButton();
            }
        });

        cbTermsCondition = view.findViewById(R.id.checkbox_terms_condition);
        btnRegister = view.findViewById(R.id.btn_register);
        btnRegister.setOnClickListener(registerBtnClickListener);
        enableRegisterButton();

        etConfirmPassword.setOnEditorActionListener(new TextView.OnEditorActionListener() {

            @Override
            public boolean onEditorAction(TextView v, int actionId, KeyEvent event) {

                if (actionId == EditorInfo.IME_ACTION_GO) {

                    if (cbTermsCondition.isChecked()) {

                        doSignUp();

                    } else {
                        cbTermsCondition.setChecked(true);
                    }
                }
                return false;
            }
        });
    }

    private void showLoading() {
        btnRegister.setEnabled(false);
        btnRegister.setAlpha(0.5f);
        txtRegisterBtn.setText(R.string.btn_registering);
        progressBar.setVisibility(View.VISIBLE);
        arrowImage.setVisibility(View.GONE);
    }

    private void hideLoading() {
        btnRegister.setEnabled(true);
        btnRegister.setAlpha(1f);
        txtRegisterBtn.setText(R.string.btn_register);
        progressBar.setVisibility(View.GONE);
        arrowImage.setVisibility(View.VISIBLE);
    }

    private void enableRegisterButton() {

        if (TextUtils.isEmpty(email) || TextUtils.isEmpty(password) || TextUtils.isEmpty(confirmPassword)) {
            btnRegister.setEnabled(false);
            btnRegister.setAlpha(0.5f);
        } else {
            btnRegister.setEnabled(true);
            btnRegister.setAlpha(1f);
        }
    }

    private void confirmSignUp(String email, String password) {

        Intent intent = new Intent(getActivity(), SignUpConfirmActivity.class);
        intent.putExtra(AppConstants.KEY_USER_NAME, email);
        intent.putExtra(AppConstants.KEY_PASSWORD, password);
        getActivity().startActivityForResult(intent, MainActivity.SIGN_UP_CONFIRM_ACTIVITY_REQUEST);
    }
}
