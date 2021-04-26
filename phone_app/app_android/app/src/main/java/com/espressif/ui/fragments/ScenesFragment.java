// Copyright 2022 Espressif Systems (Shanghai) PTE LTD
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
import android.content.Intent;
import android.os.Bundle;
import android.os.Vibrator;
import android.text.TextUtils;
import android.util.Log;
import android.view.HapticFeedbackConstants;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.RelativeLayout;
import android.widget.TextView;

import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout;

import com.espressif.AppConstants;
import com.espressif.EspApplication;
import com.espressif.rainmaker.R;
import com.espressif.ui.activities.EspMainActivity;
import com.espressif.ui.activities.SceneDetailActivity;
import com.espressif.ui.adapters.SceneAdapter;
import com.espressif.ui.models.EspNode;
import com.espressif.ui.models.Scene;
import com.espressif.ui.models.Service;
import com.google.android.material.card.MaterialCardView;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.Map;

public class ScenesFragment extends Fragment {

    private static final String TAG = ScenesFragment.class.getSimpleName();

    private MaterialCardView btnAddScene;
    private TextView txtAddSceneBtn;
    private ImageView arrowImage;

    private RecyclerView recyclerView;
    private TextView tvNoScene, tvAddScene;
    private RelativeLayout rlNoScenes;
    private SwipeRefreshLayout swipeRefreshLayout;
    private ImageView ivNoScene;

    private EspApplication espApp;
    private SceneAdapter sceneAdapter;
    private ArrayList<Scene> scenes;

    public ScenesFragment() {
        // Required empty public constructor
    }

    public static ScenesFragment newInstance() {
        return new ScenesFragment();
    }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {

        // Inflate the layout for this fragment
        View root = inflater.inflate(R.layout.fragment_scenes, container, false);
        scenes = new ArrayList<>();
        espApp = (EspApplication) getActivity().getApplicationContext();
        init(root);
        tvNoScene.setVisibility(View.GONE);
        rlNoScenes.setVisibility(View.GONE);
        recyclerView.setVisibility(View.GONE);
        updateSceneUi();
        ((EspMainActivity) getActivity()).setUpdateListener(updateListener);
        return root;
    }

    @Override
    public void onResume() {
        super.onResume();
        updateSceneUi();
    }

    @Override
    public void onDestroy() {
        ((EspMainActivity) getActivity()).removeUpdateListener(updateListener);
        super.onDestroy();
    }

    EspMainActivity.UiUpdateListener updateListener = new EspMainActivity.UiUpdateListener() {

        @Override
        public void updateUi() {
            updateSceneUi();
        }
    };

    View.OnClickListener addSceneBtnClickListener = new View.OnClickListener() {

        @Override
        public void onClick(View v) {

            Vibrator vib = (Vibrator) getActivity().getSystemService(Context.VIBRATOR_SERVICE);
            vib.vibrate(HapticFeedbackConstants.VIRTUAL_KEY);
            goToAddSceneActivity();
        }
    };

    public void updateSceneList() {
        swipeRefreshLayout.setRefreshing(true);
        ((EspMainActivity) getActivity()).refreshDeviceList();
    }

    private void init(View view) {

        rlNoScenes = view.findViewById(R.id.rl_no_scene);
        tvNoScene = view.findViewById(R.id.tv_no_scene);
        tvAddScene = view.findViewById(R.id.tv_add_scene);
        ivNoScene = view.findViewById(R.id.iv_no_scene);
        recyclerView = view.findViewById(R.id.rv_scene_list);
        swipeRefreshLayout = view.findViewById(R.id.swipe_container);

        btnAddScene = view.findViewById(R.id.btn_add_scene);
        txtAddSceneBtn = btnAddScene.findViewById(R.id.text_btn);
        arrowImage = btnAddScene.findViewById(R.id.iv_arrow);
        txtAddSceneBtn.setText(R.string.btn_add_scene);
        btnAddScene.setVisibility(View.GONE);
        arrowImage.setVisibility(View.GONE);

        btnAddScene.setOnClickListener(addSceneBtnClickListener);

        // set a LinearLayoutManager with default orientation
        recyclerView.setLayoutManager(new LinearLayoutManager(getActivity())); // set LayoutManager to RecyclerView

        sceneAdapter = new SceneAdapter(getActivity(), this, scenes);
        recyclerView.setAdapter(sceneAdapter);

        swipeRefreshLayout.setOnRefreshListener(new SwipeRefreshLayout.OnRefreshListener() {

            @Override
            public void onRefresh() {
                ((EspMainActivity) getActivity()).refreshDeviceList();
            }
        });
    }

    private void updateSceneUi() {

        switch (espApp.getAppState()) {

            case NO_INTERNET:
            case GET_DATA_SUCCESS:
            case GET_DATA_FAILED:
                updateUi(false);
                break;

            case GETTING_DATA:
            case REFRESH_DATA:
                updateUi(true);
                break;
        }
    }

    private void updateUi(boolean isRefreshing) {

        scenes.clear();
        for (Map.Entry<String, Scene> entry : espApp.sceneMap.entrySet()) {

            String key = entry.getKey();
            Scene scene = entry.getValue();

            if (scene != null) {
                scenes.add(scene);
            }
        }

        Log.d(TAG, "Scenes size : " + scenes.size());

        // Sort scene list by alphabetically.
        Collections.sort(scenes, new Comparator<Scene>() {

            @Override
            public int compare(Scene s1, Scene s2) {
                String name1 = s1.getName();
                String name2 = s2.getName();
                return name1.compareTo(name2);
            }
        });

        if (scenes.size() > 0) {

            rlNoScenes.setVisibility(View.GONE);
            btnAddScene.setVisibility(View.GONE);
            recyclerView.setVisibility(View.VISIBLE);

        } else {

            boolean isSceneDevicesAvailable = false;
            for (Map.Entry<String, EspNode> entry : espApp.nodeMap.entrySet()) {

                EspNode node = entry.getValue();
                ArrayList<Service> services = node.getServices();

                if (node != null) {

                    for (int i = 0; i < services.size(); i++) {

                        Service s = services.get(i);
                        if (!TextUtils.isEmpty(s.getType()) && s.getType().equals(AppConstants.SERVICE_TYPE_SCENES)) {
                            isSceneDevicesAvailable = true;
                            break;
                        }
                    }
                }
            }

            if (isSceneDevicesAvailable) {
                tvNoScene.setText(R.string.no_scenes);
                btnAddScene.setVisibility(View.VISIBLE);
            } else {
                tvNoScene.setText(R.string.no_device_support_this_feature);
                btnAddScene.setVisibility(View.GONE);
            }

            rlNoScenes.setVisibility(View.VISIBLE);
            tvNoScene.setVisibility(View.VISIBLE);
            tvAddScene.setVisibility(View.GONE);
            ivNoScene.setVisibility(View.VISIBLE);
            recyclerView.setVisibility(View.GONE);
        }

        sceneAdapter.updateList(scenes);
        swipeRefreshLayout.setRefreshing(isRefreshing);
        ((EspMainActivity) getActivity()).updateActionBar();
    }

    private void goToAddSceneActivity() {

        Intent intent = new Intent(getActivity(), SceneDetailActivity.class);
        startActivity(intent);
    }
}
