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

import android.app.Activity;
import android.content.DialogInterface;
import android.graphics.Color;
import android.os.Bundle;
import android.text.InputFilter;
import android.text.InputType;
import android.text.TextUtils;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.CompoundButton;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.RelativeLayout;
import android.widget.Spinner;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.widget.SwitchCompat;
import androidx.core.widget.ContentLoadingProgressBar;
import androidx.recyclerview.widget.RecyclerView;

import com.aar.tapholdupbutton.TapHoldUpButton;
import com.espressif.AppConstants;
import com.espressif.NetworkApiManager;
import com.espressif.cloudapi.ApiResponseListener;
import com.espressif.rainmaker.R;
import com.espressif.ui.activities.EspDeviceActivity;
import com.espressif.ui.models.Device;
import com.espressif.ui.models.Param;
import com.espressif.ui.widgets.EspDropDown;
import com.espressif.ui.widgets.PaletteBar;
import com.google.gson.JsonObject;
import com.larswerkman.holocolorpicker.ColorPicker;
import com.warkiz.tickseekbar.OnSeekChangeListener;
import com.warkiz.tickseekbar.SeekParams;
import com.warkiz.tickseekbar.TickSeekBar;

import java.util.ArrayList;
import java.util.Iterator;

public class ParamAdapter extends RecyclerView.Adapter<RecyclerView.ViewHolder> {

    private final String TAG = ParamAdapter.class.getSimpleName();

    private final int VIEW_TYPE_PARAM = 1;
    private final int VIEW_TYPE_PUSH_BTN_BIG = 2;
    private final int VIEW_TYPE_HUE = 3;

    private Activity context;
    private Device device;
    private ArrayList<Param> params;
    private NetworkApiManager networkApiManager;
    private String nodeId, deviceName;

    public ParamAdapter(Activity context, Device device, ArrayList<Param> paramList) {
        this.context = context;
        this.device = device;
        this.nodeId = device.getNodeId();
        this.deviceName = device.getDeviceName();
        networkApiManager = new NetworkApiManager(context.getApplicationContext());
        this.params = arrangeParamList(paramList);
    }

    @Override
    public RecyclerView.ViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {

        LayoutInflater layoutInflater = LayoutInflater.from(context);
        switch (viewType) {

            case VIEW_TYPE_PUSH_BTN_BIG:
                View switchView = layoutInflater.inflate(R.layout.item_param_switch, parent, false);
                return new SwitchViewHolder(switchView);

            case VIEW_TYPE_HUE:
                View hueView = layoutInflater.inflate(R.layout.item_param_hue, parent, false);
                return new HueViewHolder(hueView);

            case VIEW_TYPE_PARAM:
            default:
                View paramView = layoutInflater.inflate(R.layout.item_param, parent, false);
                return new ParamViewHolder(paramView);
        }
    }

    @Override
    public int getItemViewType(int position) {

        Param param = params.get(position);

        if (param != null) {

            String dataType = param.getDataType();

            if (AppConstants.UI_TYPE_HUE_CIRCLE.equalsIgnoreCase(param.getUiType())) {

                return VIEW_TYPE_HUE;

            } else if (AppConstants.UI_TYPE_PUSH_BTN_BIG.equalsIgnoreCase(param.getUiType())
                    && (!TextUtils.isEmpty(dataType) && (dataType.equalsIgnoreCase("bool") || dataType.equalsIgnoreCase("boolean")))) {

                return VIEW_TYPE_PUSH_BTN_BIG;
            }
        }
        return VIEW_TYPE_PARAM;
    }

    @Override
    public void onBindViewHolder(@NonNull final RecyclerView.ViewHolder holder, int position) {

        final Param param = params.get(position);

        if (holder.getItemViewType() == VIEW_TYPE_PARAM) {

            final ParamViewHolder paramViewHolder = (ParamViewHolder) holder;
            String dataType = param.getDataType();

            if (AppConstants.UI_TYPE_SLIDER.equalsIgnoreCase(param.getUiType())) {

                if (!TextUtils.isEmpty(dataType) && (dataType.equalsIgnoreCase("int")
                        || dataType.equalsIgnoreCase("integer")
                        || dataType.equalsIgnoreCase("float")
                        || dataType.equalsIgnoreCase("double"))) {

                    int max = param.getMaxBounds();
                    int min = param.getMinBounds();

                    if ((min < max)) {

                        displaySlider(paramViewHolder, param, position);
                    } else {
                        displayLabel(paramViewHolder, param, position);
                    }
                }
            } else if (AppConstants.UI_TYPE_HUE_SLIDER.equalsIgnoreCase(param.getUiType())) {

                displayPalette(paramViewHolder, param, position);

            } else if (AppConstants.UI_TYPE_TOGGLE.equalsIgnoreCase(param.getUiType())) {

                if (!TextUtils.isEmpty(dataType) && (dataType.equalsIgnoreCase("bool")
                        || dataType.equalsIgnoreCase("boolean"))) {

                    displayToggle(paramViewHolder, param);

                } else {
                    displayLabel(paramViewHolder, param, position);
                }

            } else if (AppConstants.UI_TYPE_TRIGGER.equalsIgnoreCase(param.getUiType())) {

                if (!TextUtils.isEmpty(dataType) && (dataType.equalsIgnoreCase("bool")
                        || dataType.equalsIgnoreCase("boolean"))) {

                    displayTrigger(paramViewHolder, param);

                } else {
                    displayLabel(paramViewHolder, param, position);
                }

            } else if (AppConstants.UI_TYPE_DROP_DOWN.equalsIgnoreCase(param.getUiType())) {

                if (!TextUtils.isEmpty(dataType) && (dataType.equalsIgnoreCase("string"))) {

                    displaySpinner(paramViewHolder, param, position);

                } else if (!TextUtils.isEmpty(dataType) && (dataType.equalsIgnoreCase("int")
                        || dataType.equalsIgnoreCase("integer"))) {

                    int max = param.getMaxBounds();
                    int min = param.getMinBounds();
                    int stepCount = (int) param.getStepCount();
                    if (stepCount == 0) {
                        stepCount = 1;
                    }
                    ArrayList<String> spinnerValues = new ArrayList<>();
                    for (int i = min; i <= max; i = i + stepCount) {
                        spinnerValues.add(String.valueOf(i));
                    }

                    if ((min < max)) {
                        displaySpinner(paramViewHolder, param, position);
                    } else {
                        if (spinnerValues.size() > 0) {
                            displaySpinner(paramViewHolder, param, position);
                        } else {
                            displayLabel(paramViewHolder, param, position);
                        }
                    }
                } else {
                    displayLabel(paramViewHolder, param, position);
                }
            } else {
                displayLabel(paramViewHolder, param, position);
            }
        } else if (holder.getItemViewType() == VIEW_TYPE_PUSH_BTN_BIG) {

            final SwitchViewHolder switchViewHolder = (SwitchViewHolder) holder;

            if (param.getSwitchStatus()) {
                switchViewHolder.ivSwitch.setImageResource(R.drawable.ic_switch_on);
            } else {
                switchViewHolder.ivSwitch.setImageResource(R.drawable.ic_switch_off);
            }

            if (param.getProperties().contains(AppConstants.KEY_PROPERTY_WRITE)) {

                if (((EspDeviceActivity) context).isNodeOnline()) {

                    switchViewHolder.ivSwitch.setAlpha(1f);
                    switchViewHolder.ivSwitch.setEnabled(true);

                    switchViewHolder.ivSwitch.setOnClickListener(new View.OnClickListener() {

                        @Override
                        public void onClick(View v) {
                            ((EspDeviceActivity) context).stopUpdateValueTask();
                            ((EspDeviceActivity) context).showParamUpdateLoading("Updating...");

                            JsonObject jsonParam = new JsonObject();
                            JsonObject body = new JsonObject();

                            jsonParam.addProperty(param.getName(), !param.getSwitchStatus());
                            body.add(deviceName, jsonParam);

                            networkApiManager.updateParamValue(nodeId, body, new ApiResponseListener() {

                                @Override
                                public void onSuccess(Bundle data) {
                                    param.setSwitchStatus(!param.getSwitchStatus());
                                    ((EspDeviceActivity) context).startUpdateValueTask();
                                    ((EspDeviceActivity) context).hideParamUpdateLoading();
                                    if (param.getSwitchStatus()) {
                                        switchViewHolder.ivSwitch.setImageResource(R.drawable.ic_switch_on);
                                    } else {
                                        switchViewHolder.ivSwitch.setImageResource(R.drawable.ic_switch_off);
                                    }
                                }

                                @Override
                                public void onResponseFailure(Exception exception) {
                                    ((EspDeviceActivity) context).startUpdateValueTask();
                                    ((EspDeviceActivity) context).hideParamUpdateLoading();
                                    if (param.getSwitchStatus()) {
                                        switchViewHolder.ivSwitch.setImageResource(R.drawable.ic_switch_on);
                                    } else {
                                        switchViewHolder.ivSwitch.setImageResource(R.drawable.ic_switch_off);
                                    }
                                }

                                @Override
                                public void onNetworkFailure(Exception exception) {
                                    ((EspDeviceActivity) context).startUpdateValueTask();
                                    ((EspDeviceActivity) context).hideParamUpdateLoading();
                                    if (param.getSwitchStatus()) {
                                        switchViewHolder.ivSwitch.setImageResource(R.drawable.ic_switch_on);
                                    } else {
                                        switchViewHolder.ivSwitch.setImageResource(R.drawable.ic_switch_off);
                                    }
                                }
                            });
                        }
                    });
                } else {
                    switchViewHolder.ivSwitch.setAlpha(0.5f);
                    switchViewHolder.ivSwitch.setEnabled(false);
                }
            } else {
                switchViewHolder.ivSwitch.setEnabled(false);
            }

        } else if (holder.getItemViewType() == VIEW_TYPE_HUE) {

            final HueViewHolder hueViewHolder = (HueViewHolder) holder;

            int hueColor = (int) param.getValue();

            float[] hsv = new float[3];
            hsv[0] = hueColor;
            hsv[1] = 10.0f;
            hsv[2] = 10.0f;

            Log.e(TAG, "hsv[0] : " + hsv[0]);
            int mCurrentIntColor = Color.HSVToColor(hsv);
            hueViewHolder.colorPickerView.setShowOldCenterColor(false);
            hueViewHolder.colorPickerView.setColor(mCurrentIntColor);

            if (param.getProperties().contains(AppConstants.KEY_PROPERTY_WRITE)) {

                if (((EspDeviceActivity) context).isNodeOnline()) {

                    hueViewHolder.colorPickerView.setAlpha(1f);
                    hueViewHolder.colorPickerView.setEnabled(true);

                    hueViewHolder.colorPickerView.setOnColorChangedListener(new ColorPicker.OnColorChangedListener() {

                        @Override
                        public void onColorChanged(int color) {
                            Log.e(TAG, "====================== onColorChanged : Stop updates");
                            ((EspDeviceActivity) context).stopUpdateValueTask();
                        }
                    });

                    hueViewHolder.colorPickerView.setOnColorSelectedListener(new ColorPicker.OnColorSelectedListener() {
                        @Override
                        public void onColorSelected(int color) {
                            Log.e(TAG, "====================== onColorSelected : " + color);
                            Log.e(TAG, "Color  : " + hueViewHolder.colorPickerView.getColor());
                            float[] newHsv = new float[3];
                            Color.colorToHSV(color, newHsv);
                            int hue = (int) newHsv[0];
                            Log.e(TAG, "New Hue color : " + hue);

                            JsonObject jsonParam = new JsonObject();
                            JsonObject body = new JsonObject();
                            jsonParam.addProperty(param.getName(), hue);
                            body.add(deviceName, jsonParam);

                            ((EspDeviceActivity) context).stopUpdateValueTask();
                            ((EspDeviceActivity) context).showParamUpdateLoading("Updating...");
                            Log.e(TAG, "Body : " + body.toString());

                            networkApiManager.updateParamValue(nodeId, body, new ApiResponseListener() {

                                @Override
                                public void onSuccess(Bundle data) {
                                    ((EspDeviceActivity) context).startUpdateValueTask();
                                    ((EspDeviceActivity) context).hideParamUpdateLoading();
                                }

                                @Override
                                public void onResponseFailure(Exception exception) {
                                    ((EspDeviceActivity) context).startUpdateValueTask();
                                    ((EspDeviceActivity) context).hideParamUpdateLoading();
                                }

                                @Override
                                public void onNetworkFailure(Exception exception) {
                                    ((EspDeviceActivity) context).startUpdateValueTask();
                                    ((EspDeviceActivity) context).hideParamUpdateLoading();
                                }
                            });
                        }
                    });
                } else {
                    hueViewHolder.colorPickerView.setAlpha(0.5f);
                    hueViewHolder.colorPickerView.setEnabled(false);
                    hueViewHolder.colorPickerView.setOnColorChangedListener(null);
                    hueViewHolder.colorPickerView.setOnColorChangedListener(null);
                }
            } else {
                hueViewHolder.colorPickerView.setEnabled(false);
                hueViewHolder.colorPickerView.setOnColorChangedListener(null);
                hueViewHolder.colorPickerView.setOnColorChangedListener(null);
            }
        }
    }

    @Override
    public int getItemCount() {
        return params.size();
    }

    public void updateList(ArrayList<Param> paramList) {

        this.params = arrangeParamList(paramList);
        notifyDataSetChanged();
    }

    private ArrayList<Param> arrangeParamList(ArrayList<Param> paramList) {

        int firstParamIndex = -1;
        for (int i = 0; i < paramList.size(); i++) {

            Param param = paramList.get(i);
            if (param != null && AppConstants.UI_TYPE_HUE_CIRCLE.equalsIgnoreCase(param.getUiType())) {
                firstParamIndex = i;
                break;
            }
        }

        if (firstParamIndex != -1) {
            Param paramToBeMoved = paramList.remove(firstParamIndex);
            paramList.add(0, paramToBeMoved);
        } else {

            for (int i = 0; i < paramList.size(); i++) {

                Param param = paramList.get(i);
                if (param != null) {
                    String dataType = param.getDataType();
                    if (AppConstants.UI_TYPE_PUSH_BTN_BIG.equalsIgnoreCase(param.getUiType())
                            && (!TextUtils.isEmpty(dataType) && (dataType.equalsIgnoreCase("bool") || dataType.equalsIgnoreCase("boolean")))) {
                        firstParamIndex = i;
                        break;
                    }
                }
            }

            if (firstParamIndex != -1) {
                Param paramToBeMoved = paramList.remove(firstParamIndex);
                paramList.add(0, paramToBeMoved);
            }
        }

        Iterator<Param> paramIterator = paramList.iterator();
        while (paramIterator.hasNext()) {
            Param p = paramIterator.next();
            if (p.getUiType() != null && p.getUiType().equals(AppConstants.UI_TYPE_HIDDEN)) {
                paramIterator.remove();
            }
        }
        return paramList;
    }

    private void displayPalette(ParamViewHolder paramViewHolder, final Param param, final int position) {

        paramViewHolder.rlUiTypeSlider.setVisibility(View.GONE);
        paramViewHolder.rlUiTypeSwitch.setVisibility(View.GONE);
        paramViewHolder.rlUiTypeLabel.setVisibility(View.GONE);
        paramViewHolder.rlPalette.setVisibility(View.VISIBLE);
        paramViewHolder.rlUiTypeDropDown.setVisibility(View.GONE);
        paramViewHolder.rlUiTypeTrigger.setVisibility(View.GONE);

        paramViewHolder.tvLabelPalette.setText(param.getName());
        paramViewHolder.paletteBar.setColor((int) param.getValue());
        paramViewHolder.paletteBar.setThumbCircleRadius(17);
        paramViewHolder.paletteBar.setTrackMarkHeight(10);
        if (param.getProperties().contains(AppConstants.KEY_PROPERTY_WRITE)) {

            if (((EspDeviceActivity) context).isNodeOnline()) {

                paramViewHolder.paletteBar.setEnabled(true);
                paramViewHolder.paletteBar.setListener(new PaletteBar.PaletteBarListener() {
                    @Override
                    public void onColorSelected(int colorInt) {

                        ((EspDeviceActivity) context).stopUpdateValueTask();
                        JsonObject jsonParam = new JsonObject();
                        JsonObject body = new JsonObject();

                        jsonParam.addProperty(param.getName(), colorInt);
                        body.add(deviceName, jsonParam);
                        networkApiManager.updateParamValue(nodeId, body, new ApiResponseListener() {

                            @Override
                            public void onSuccess(Bundle data) {
                                ((EspDeviceActivity) context).startUpdateValueTask();
                            }

                            @Override
                            public void onResponseFailure(Exception exception) {
                                ((EspDeviceActivity) context).startUpdateValueTask();
                            }

                            @Override
                            public void onNetworkFailure(Exception exception) {
                                ((EspDeviceActivity) context).startUpdateValueTask();
                            }
                        });
                    }
                });
            } else {
                paramViewHolder.paletteBar.setEnabled(false);
            }
        }
    }

    private void displaySlider(final ParamViewHolder paramViewHolder, final Param param, final int position) {

        paramViewHolder.rlUiTypeSlider.setVisibility(View.VISIBLE);
        paramViewHolder.rlUiTypeSwitch.setVisibility(View.GONE);
        paramViewHolder.rlUiTypeLabel.setVisibility(View.GONE);
        paramViewHolder.rlPalette.setVisibility(View.GONE);
        paramViewHolder.rlUiTypeDropDown.setVisibility(View.GONE);
        paramViewHolder.rlUiTypeTrigger.setVisibility(View.GONE);

        double sliderValue = param.getValue();
        paramViewHolder.tvSliderName.setText(param.getName());
        float max = param.getMaxBounds();
        float min = param.getMinBounds();
        String dataType = param.getDataType();

        if (AppConstants.PARAM_TYPE_CCT.equals(param.getParamType())) {

            paramViewHolder.ivSliderStart.setImageResource(R.drawable.ic_cct_low);
            paramViewHolder.ivSliderEnd.setImageResource(R.drawable.ic_cct_high);
            paramViewHolder.ivSliderStart.setVisibility(View.VISIBLE);
            paramViewHolder.ivSliderEnd.setVisibility(View.VISIBLE);

        } else if (AppConstants.PARAM_TYPE_BRIGHTNESS.equals(param.getParamType())) {

            paramViewHolder.ivSliderStart.setImageResource(R.drawable.ic_brightness_low);
            paramViewHolder.ivSliderEnd.setImageResource(R.drawable.ic_brightness_high);
            paramViewHolder.ivSliderStart.setVisibility(View.VISIBLE);
            paramViewHolder.ivSliderEnd.setVisibility(View.VISIBLE);

        } else if (AppConstants.PARAM_TYPE_SATURATION.equals(param.getParamType())) {

            paramViewHolder.ivSliderStart.setImageResource(R.drawable.ic_saturation_low);
            paramViewHolder.ivSliderEnd.setImageResource(R.drawable.ic_saturation_high);
            paramViewHolder.ivSliderStart.setVisibility(View.VISIBLE);
            paramViewHolder.ivSliderEnd.setVisibility(View.VISIBLE);

        } else {
            paramViewHolder.ivSliderStart.setVisibility(View.GONE);
            paramViewHolder.ivSliderEnd.setVisibility(View.GONE);
        }

        if (dataType.equalsIgnoreCase("int") || dataType.equalsIgnoreCase("integer")) {

            paramViewHolder.intSlider.setVisibility(View.VISIBLE);
            paramViewHolder.floatSlider.setVisibility(View.GONE);

            paramViewHolder.intSlider.setMax(max);
            paramViewHolder.intSlider.setMin(min);
            paramViewHolder.intSlider.setTickCount(2);

            if (sliderValue < min) {

                paramViewHolder.intSlider.setProgress(min);

            } else if (sliderValue > max) {

                paramViewHolder.intSlider.setProgress(max);

            } else {
                paramViewHolder.intSlider.setProgress((int) sliderValue);
            }

            if (param.getProperties().contains(AppConstants.KEY_PROPERTY_WRITE)) {

                if (((EspDeviceActivity) context).isNodeOnline()) {

                    paramViewHolder.intSlider.setEnabled(true);

                    paramViewHolder.intSlider.setOnSeekChangeListener(new OnSeekChangeListener() {

                        @Override
                        public void onSeeking(SeekParams seekParams) {
                        }

                        @Override
                        public void onStartTrackingTouch(TickSeekBar seekBar) {
                            ((EspDeviceActivity) context).stopUpdateValueTask();
                        }

                        @Override
                        public void onStopTrackingTouch(TickSeekBar seekBar) {

                            int progress = seekBar.getProgress();
                            int finalProgress = progress;

                            JsonObject jsonParam = new JsonObject();
                            JsonObject body = new JsonObject();

                            jsonParam.addProperty(param.getName(), finalProgress);
                            body.add(deviceName, jsonParam);

                            networkApiManager.updateParamValue(nodeId, body, new ApiResponseListener() {

                                @Override
                                public void onSuccess(Bundle data) {
                                    ((EspDeviceActivity) context).startUpdateValueTask();
                                }

                                @Override
                                public void onResponseFailure(Exception exception) {
                                    ((EspDeviceActivity) context).startUpdateValueTask();
                                }

                                @Override
                                public void onNetworkFailure(Exception exception) {
                                    ((EspDeviceActivity) context).startUpdateValueTask();
                                }
                            });
                        }
                    });

                } else {

                    paramViewHolder.intSlider.setEnabled(false);
                }

            } else {

                paramViewHolder.intSlider.setOnTouchListener(new View.OnTouchListener() {
                    @Override
                    public boolean onTouch(View v, MotionEvent event) {
                        return true;
                    }
                });
            }
        } else {

            paramViewHolder.intSlider.setVisibility(View.GONE);
            paramViewHolder.floatSlider.setVisibility(View.VISIBLE);

            paramViewHolder.floatSlider.setMax(max);
            paramViewHolder.floatSlider.setMin(min);
            paramViewHolder.floatSlider.setTickCount(2);

            if (sliderValue < min) {

                paramViewHolder.floatSlider.setProgress(min);

            } else if (sliderValue > max) {

                paramViewHolder.floatSlider.setProgress(max);

            } else {
                paramViewHolder.floatSlider.setProgress((float) sliderValue);
            }

            if (param.getProperties().contains(AppConstants.KEY_PROPERTY_WRITE)) {

                if (((EspDeviceActivity) context).isNodeOnline()) {

                    paramViewHolder.floatSlider.setEnabled(true);

                    paramViewHolder.floatSlider.setOnSeekChangeListener(new OnSeekChangeListener() {

                        @Override
                        public void onSeeking(SeekParams seekParams) {
                        }

                        @Override
                        public void onStartTrackingTouch(TickSeekBar seekBar) {
                            ((EspDeviceActivity) context).stopUpdateValueTask();
                        }

                        @Override
                        public void onStopTrackingTouch(TickSeekBar seekBar) {

                            float progress = seekBar.getProgressFloat();
                            float finalProgress = progress;

                            JsonObject jsonParam = new JsonObject();
                            JsonObject body = new JsonObject();

                            jsonParam.addProperty(param.getName(), finalProgress);
                            body.add(deviceName, jsonParam);

                            networkApiManager.updateParamValue(nodeId, body, new ApiResponseListener() {

                                @Override
                                public void onSuccess(Bundle data) {
                                    ((EspDeviceActivity) context).startUpdateValueTask();
                                }

                                @Override
                                public void onResponseFailure(Exception exception) {
                                    ((EspDeviceActivity) context).startUpdateValueTask();
                                }

                                @Override
                                public void onNetworkFailure(Exception exception) {
                                    ((EspDeviceActivity) context).startUpdateValueTask();
                                }
                            });
                        }
                    });

                } else {
                    paramViewHolder.floatSlider.setEnabled(false);
                }

            } else {

                paramViewHolder.floatSlider.setOnTouchListener(new View.OnTouchListener() {
                    @Override
                    public boolean onTouch(View v, MotionEvent event) {
                        return true;
                    }
                });
            }
        }
    }

    private void displayToggle(final ParamViewHolder paramViewHolder, final Param param) {

        paramViewHolder.rlUiTypeSlider.setVisibility(View.GONE);
        paramViewHolder.rlUiTypeSwitch.setVisibility(View.VISIBLE);
        paramViewHolder.rlUiTypeLabel.setVisibility(View.GONE);
        paramViewHolder.rlPalette.setVisibility(View.GONE);
        paramViewHolder.rlUiTypeDropDown.setVisibility(View.GONE);
        paramViewHolder.rlUiTypeTrigger.setVisibility(View.GONE);

        paramViewHolder.tvSwitchName.setText(param.getName());
        paramViewHolder.tvSwitchStatus.setVisibility(View.VISIBLE);

        if (param.getSwitchStatus()) {

            paramViewHolder.tvSwitchStatus.setText(R.string.text_on);

        } else {
            paramViewHolder.tvSwitchStatus.setText(R.string.text_off);
        }

        if (param.getProperties().contains(AppConstants.KEY_PROPERTY_WRITE)) {

            paramViewHolder.toggleSwitch.setVisibility(View.VISIBLE);
            paramViewHolder.toggleSwitch.setOnCheckedChangeListener(null);
            paramViewHolder.toggleSwitch.setChecked(param.getSwitchStatus());

            if (((EspDeviceActivity) context).isNodeOnline()) {

                paramViewHolder.toggleSwitch.setEnabled(true);

                paramViewHolder.toggleSwitch.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {

                    @Override
                    public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {

                        ((EspDeviceActivity) context).stopUpdateValueTask();

                        if (isChecked) {

                            paramViewHolder.tvSwitchStatus.setText(R.string.text_on);

                        } else {
                            paramViewHolder.tvSwitchStatus.setText(R.string.text_off);
                        }

                        JsonObject jsonParam = new JsonObject();
                        JsonObject body = new JsonObject();

                        jsonParam.addProperty(param.getName(), isChecked);
                        body.add(deviceName, jsonParam);

                        networkApiManager.updateParamValue(nodeId, body, new ApiResponseListener() {

                            @Override
                            public void onSuccess(Bundle data) {
                                ((EspDeviceActivity) context).startUpdateValueTask();
                            }

                            @Override
                            public void onResponseFailure(Exception exception) {
                                ((EspDeviceActivity) context).startUpdateValueTask();
                            }

                            @Override
                            public void onNetworkFailure(Exception exception) {
                                ((EspDeviceActivity) context).startUpdateValueTask();
                            }
                        });
                    }
                });

            } else {
                paramViewHolder.toggleSwitch.setEnabled(false);
            }

        } else {

            paramViewHolder.toggleSwitch.setVisibility(View.GONE);
        }
    }

    private void displayTrigger(final ParamViewHolder paramViewHolder, final Param param) {

        paramViewHolder.rlUiTypeSlider.setVisibility(View.GONE);
        paramViewHolder.rlUiTypeSwitch.setVisibility(View.GONE);
        paramViewHolder.rlUiTypeLabel.setVisibility(View.GONE);
        paramViewHolder.rlPalette.setVisibility(View.GONE);
        paramViewHolder.rlUiTypeDropDown.setVisibility(View.GONE);
        paramViewHolder.rlUiTypeTrigger.setVisibility(View.VISIBLE);

        paramViewHolder.tvTriggerName.setText(param.getName());

        if (param.getProperties().contains(AppConstants.KEY_PROPERTY_WRITE)) {

            if (((EspDeviceActivity) context).isNodeOnline()) {

                paramViewHolder.btnTrigger.setAlpha(1f);
                paramViewHolder.btnTrigger.setEnabled(true);
                paramViewHolder.btnTrigger.setClickable(true);
                paramViewHolder.btnTrigger.enableLongHold(true);
                paramViewHolder.btnTrigger.setOnButtonClickListener(new TapHoldUpButton.OnButtonClickListener() {

                    @Override
                    public void onLongHoldStart(View v) {
                    }

                    @Override
                    public void onLongHoldEnd(View v) {
                        ((EspDeviceActivity) context).stopUpdateValueTask();
                        JsonObject jsonParam = new JsonObject();
                        JsonObject body = new JsonObject();

                        jsonParam.addProperty(param.getName(), true);
                        body.add(deviceName, jsonParam);

                        networkApiManager.updateParamValue(nodeId, body, new ApiResponseListener() {

                            @Override
                            public void onSuccess(Bundle data) {
                                ((EspDeviceActivity) context).startUpdateValueTask();
                            }

                            @Override
                            public void onResponseFailure(Exception exception) {
                                ((EspDeviceActivity) context).startUpdateValueTask();
                            }

                            @Override
                            public void onNetworkFailure(Exception exception) {
                                ((EspDeviceActivity) context).startUpdateValueTask();
                            }
                        });
                    }

                    @Override
                    public void onClick(View v) {
                        ((EspDeviceActivity) context).stopUpdateValueTask();
                        JsonObject jsonParam = new JsonObject();
                        JsonObject body = new JsonObject();

                        jsonParam.addProperty(param.getName(), true);
                        body.add(deviceName, jsonParam);

                        networkApiManager.updateParamValue(nodeId, body, new ApiResponseListener() {

                            @Override
                            public void onSuccess(Bundle data) {
                                ((EspDeviceActivity) context).startUpdateValueTask();
                            }

                            @Override
                            public void onResponseFailure(Exception exception) {
                                ((EspDeviceActivity) context).startUpdateValueTask();
                            }

                            @Override
                            public void onNetworkFailure(Exception exception) {
                                ((EspDeviceActivity) context).startUpdateValueTask();
                            }
                        });
                    }
                });

            } else {
                paramViewHolder.btnTrigger.setAlpha(0.3f);
                paramViewHolder.btnTrigger.setEnabled(false);
                paramViewHolder.btnTrigger.setClickable(false);
                paramViewHolder.btnTrigger.enableLongHold(false);
                paramViewHolder.btnTrigger.setOnButtonClickListener(null);
            }

        } else {
            paramViewHolder.btnTrigger.setVisibility(View.GONE);
        }
    }

    private void displayLabel(final ParamViewHolder paramViewHolder, final Param param, final int position) {

        paramViewHolder.rlUiTypeSlider.setVisibility(View.GONE);
        paramViewHolder.rlUiTypeSwitch.setVisibility(View.GONE);
        paramViewHolder.rlUiTypeLabel.setVisibility(View.VISIBLE);
        paramViewHolder.rlPalette.setVisibility(View.GONE);
        paramViewHolder.rlUiTypeDropDown.setVisibility(View.GONE);
        paramViewHolder.rlUiTypeTrigger.setVisibility(View.GONE);

        paramViewHolder.tvLabelName.setText(param.getName());
        paramViewHolder.tvLabelValue.setText(param.getLabelValue());

        if (param.getProperties().contains(AppConstants.KEY_PROPERTY_WRITE) && ((EspDeviceActivity) context).isNodeOnline()) {

            paramViewHolder.btnEdit.setVisibility(View.VISIBLE);

            paramViewHolder.btnEdit.setOnClickListener(new View.OnClickListener() {

                @Override
                public void onClick(View v) {
                    askForNewValue(paramViewHolder, param, position);
                }
            });

        } else {

            paramViewHolder.btnEdit.setVisibility(View.GONE);
        }
    }

    private void displaySpinner(final ParamViewHolder paramViewHolder, final Param param, final int position) {

        paramViewHolder.rlUiTypeSlider.setVisibility(View.GONE);
        paramViewHolder.rlUiTypeSwitch.setVisibility(View.GONE);
        paramViewHolder.rlUiTypeLabel.setVisibility(View.GONE);
        paramViewHolder.rlPalette.setVisibility(View.GONE);
        paramViewHolder.rlUiTypeDropDown.setVisibility(View.VISIBLE);

        paramViewHolder.tvSpinnerName.setText(param.getName());
        paramViewHolder.spinner.setVisibility(View.VISIBLE);

        paramViewHolder.spinner.setEnabled(false);
        paramViewHolder.spinner.setOnItemSelectedListener(null);

        final String dataType = param.getDataType();

        if (!TextUtils.isEmpty(dataType) && (dataType.equalsIgnoreCase("string"))) {

            if (param.getValidStrings() != null && param.getValidStrings().size() > 0) {

                ArrayList<String> spinnerValues = new ArrayList<>();
                spinnerValues.addAll(param.getValidStrings());
                ArrayAdapter<String> dataAdapter = new ArrayAdapter<String>(context, android.R.layout.simple_spinner_item, spinnerValues);
                dataAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
                paramViewHolder.spinner.setAdapter(dataAdapter);
                boolean isValueFound = false;
                String value = param.getLabelValue();

                for (int i = 0; i < param.getValidStrings().size(); i++) {

                    if (!TextUtils.isEmpty(value)) {

                        if (value.equals(param.getValidStrings().get(i))) {
                            isValueFound = true;
                            paramViewHolder.spinner.setSelection(i, false);
                            paramViewHolder.spinner.setTag(R.id.position, i);
                            break;
                        }
                    }
                }

                if (!isValueFound) {
                    spinnerValues.add(0, "");
                    paramViewHolder.spinner.setSelection(0, false);
                    paramViewHolder.spinner.setTag(R.id.position, 0);
                    dataAdapter.notifyDataSetChanged();
                    String strInvalidValue = "" + value + " (" + context.getString(R.string.invalid) + ")";
                    paramViewHolder.tvSpinnerValue.setText(strInvalidValue);
                    paramViewHolder.tvSpinnerValue.setVisibility(View.VISIBLE);
                } else {
                    paramViewHolder.tvSpinnerValue.setVisibility(View.GONE);
                }
            }
        } else if (!TextUtils.isEmpty(dataType) && (dataType.equalsIgnoreCase("int")
                || dataType.equalsIgnoreCase("integer"))) {

            int sliderValue = (int) param.getValue();
            int max = param.getMaxBounds();
            int min = param.getMinBounds();
            int stepCount = (int) param.getStepCount();
            if (stepCount == 0) {
                stepCount = 1;
            }

            ArrayList<String> spinnerValues = new ArrayList<>();
            for (int i = min; i <= max; i = i + stepCount) {
                spinnerValues.add(String.valueOf(i));
            }

            if (spinnerValues.size() > 0) {

                ArrayAdapter<String> dataAdapter = new ArrayAdapter<String>(context, android.R.layout.simple_spinner_item, spinnerValues);
                dataAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
                paramViewHolder.spinner.setAdapter(dataAdapter);

                if (sliderValue < min) {

                    paramViewHolder.spinner.setSelection(0);
                    paramViewHolder.spinner.setTag(R.id.position, 0);

                } else if (sliderValue > max) {

                    int lastPosition = spinnerValues.size() - 1;
                    paramViewHolder.spinner.setSelection(lastPosition);
                    paramViewHolder.spinner.setTag(R.id.position, lastPosition);

                } else {

                    boolean isValueFound = false;
                    for (int i = 0; i < spinnerValues.size(); i++) {

                        String value = spinnerValues.get(i);
                        int intValue = Integer.parseInt(value);

                        if (sliderValue == intValue) {
                            isValueFound = true;
                            paramViewHolder.spinner.setSelection(i, false);
                            paramViewHolder.spinner.setTag(R.id.position, i);
                            break;
                        }
                    }

                    if (!isValueFound) {
                        spinnerValues.add(0, "");
                        paramViewHolder.spinner.setSelection(0, false);
                        paramViewHolder.spinner.setTag(R.id.position, 0);
                        dataAdapter.notifyDataSetChanged();
                        String strInvalidValue = "" + sliderValue + " (" + context.getString(R.string.invalid) + ")";
                        paramViewHolder.tvSpinnerValue.setText(strInvalidValue);
                        paramViewHolder.tvSpinnerValue.setVisibility(View.VISIBLE);
                    } else {
                        paramViewHolder.tvSpinnerValue.setVisibility(View.GONE);
                    }
                }
            } else {
                // Displayed label for this condition.
            }
        }

        if (param.getProperties().contains(AppConstants.KEY_PROPERTY_WRITE) && ((EspDeviceActivity) context).isNodeOnline()) {

            paramViewHolder.spinner.setSpinnerEventsListener(new EspDropDown.OnSpinnerEventsListener() {

                @Override
                public void onSpinnerOpened(Spinner spin) {
                    ((EspDeviceActivity) context).stopUpdateValueTask();
                }

                @Override
                public void onSpinnerClosed(Spinner spin) {
                    ((EspDeviceActivity) context).startUpdateValueTask();
                }
            });

            paramViewHolder.spinner.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {

                @Override
                public void onItemSelected(AdapterView<?> parent, View view, final int pos, long id) {

                    Log.d(TAG, "Dropdown list item clicked position :  " + paramViewHolder.spinner.getTag(R.id.position));

                    if ((int) paramViewHolder.spinner.getTag(R.id.position) != pos) {

                        final String newValue = parent.getItemAtPosition(pos).toString();
                        paramViewHolder.spinner.setVisibility(View.GONE);
                        paramViewHolder.progressBarSpinner.setVisibility(View.VISIBLE);

                        ((EspDeviceActivity) context).stopUpdateValueTask();

                        JsonObject jsonParam = new JsonObject();
                        JsonObject body = new JsonObject();

                        if (!TextUtils.isEmpty(dataType) && (dataType.equalsIgnoreCase("string"))) {

                            jsonParam.addProperty(param.getName(), newValue);

                        } else if (!TextUtils.isEmpty(dataType) && (dataType.equalsIgnoreCase("int")
                                || dataType.equalsIgnoreCase("integer"))) {

                            jsonParam.addProperty(param.getName(), Integer.parseInt(newValue));
                        }
                        body.add(deviceName, jsonParam);

                        networkApiManager.updateParamValue(nodeId, body, new ApiResponseListener() {

                            @Override
                            public void onSuccess(Bundle data) {

                                context.runOnUiThread(new Runnable() {
                                    @Override
                                    public void run() {

                                        paramViewHolder.progressBarSpinner.setVisibility(View.GONE);
                                        paramViewHolder.spinner.setVisibility(View.VISIBLE);
                                        paramViewHolder.spinner.setTag(R.id.position, pos);

                                        if (!TextUtils.isEmpty(dataType) && (dataType.equalsIgnoreCase("string"))) {

                                            params.get(position).setLabelValue(newValue);
                                            paramViewHolder.tvSpinnerValue.setVisibility(View.GONE);

                                        } else if (!TextUtils.isEmpty(dataType) && (dataType.equalsIgnoreCase("int")
                                                || dataType.equalsIgnoreCase("integer"))) {

                                            params.get(position).setValue(Integer.parseInt(newValue));
                                            paramViewHolder.tvSpinnerValue.setVisibility(View.GONE);
                                        }

                                        ((EspDeviceActivity) context).startUpdateValueTask();
                                    }
                                });
                            }

                            @Override
                            public void onResponseFailure(Exception exception) {

                                context.runOnUiThread(new Runnable() {
                                    @Override
                                    public void run() {
                                        paramViewHolder.progressBarSpinner.setVisibility(View.GONE);
                                        paramViewHolder.spinner.setVisibility(View.VISIBLE);
                                        ((EspDeviceActivity) context).startUpdateValueTask();
                                    }
                                });
                            }

                            @Override
                            public void onNetworkFailure(Exception exception) {

                                context.runOnUiThread(new Runnable() {
                                    @Override
                                    public void run() {
                                        paramViewHolder.progressBarSpinner.setVisibility(View.GONE);
                                        paramViewHolder.spinner.setVisibility(View.VISIBLE);
                                        ((EspDeviceActivity) context).startUpdateValueTask();
                                    }
                                });
                            }
                        });
                    }
                }

                @Override
                public void onNothingSelected(AdapterView<?> parent) {
                }
            });
            paramViewHolder.spinner.setEnabled(true);

        } else {
            paramViewHolder.spinner.setOnItemSelectedListener(null);
        }
    }

    private void askForNewValue(final ParamViewHolder paramViewHolder, final Param param, final int position) {

        final AlertDialog.Builder builder = new AlertDialog.Builder(context);
        LayoutInflater inflater = context.getLayoutInflater();
        final View dialogView = inflater.inflate(R.layout.dialog_attribute, null);
        builder.setView(dialogView);

        final EditText etAttribute = dialogView.findViewById(R.id.et_attr_value);

        if (!TextUtils.isEmpty(param.getDataType())) {

            String dataType = param.getDataType();

            if (dataType.equalsIgnoreCase("int")
                    || dataType.equalsIgnoreCase("integer")) {

                etAttribute.setInputType(InputType.TYPE_CLASS_NUMBER);

            } else if (dataType.equalsIgnoreCase("float")
                    || dataType.equalsIgnoreCase("double")) {

                etAttribute.setInputType(InputType.TYPE_CLASS_NUMBER | InputType.TYPE_NUMBER_FLAG_DECIMAL);

            } else if (dataType.equalsIgnoreCase("string")) {

                etAttribute.setInputType(InputType.TYPE_CLASS_TEXT);

                if (param.getParamType() != null && param.getParamType().equals(AppConstants.PARAM_TYPE_NAME)) {
                    etAttribute.setFilters(new InputFilter[]{new InputFilter.LengthFilter(32)});
                }
            }
        }

        if (!TextUtils.isEmpty(param.getLabelValue())) {
            etAttribute.setText(param.getLabelValue());
            etAttribute.setSelection(etAttribute.getText().length());
            etAttribute.requestFocus();
        }

        builder.setPositiveButton(R.string.btn_ok, new DialogInterface.OnClickListener() {

            @Override
            public void onClick(DialogInterface dialog, int which) {

                String dataType = param.getDataType();
                final String value = etAttribute.getText().toString();

                if (params.get(position).getParamType() != null && params.get(position).getParamType().equals(AppConstants.PARAM_TYPE_NAME)) {

                    if (TextUtils.isEmpty(value)) {
                        Toast.makeText(context, context.getString(R.string.error_device_name_empty), Toast.LENGTH_SHORT).show();
                        return;
                    }
                }

                ((EspDeviceActivity) context).stopUpdateValueTask();

                JsonObject jsonParam = new JsonObject();
                JsonObject body = new JsonObject();

                if (dataType.equalsIgnoreCase("bool")
                        || dataType.equalsIgnoreCase("boolean")) {

                    if (!TextUtils.isEmpty(value)) {

                        if (value.equalsIgnoreCase("true") || value.equalsIgnoreCase("false")
                                || value.equalsIgnoreCase("0") || value.equalsIgnoreCase("1")) {

                            boolean isOn = false;

                            if (value.equalsIgnoreCase("true") || value.equalsIgnoreCase("1")) {
                                isOn = true;
                            }

                            paramViewHolder.btnEdit.setVisibility(View.GONE);
                            paramViewHolder.progressBar.setVisibility(View.VISIBLE);

                            jsonParam.addProperty(param.getName(), isOn);
                            body.add(deviceName, jsonParam);

                            final boolean finalIsOn = isOn;
                            networkApiManager.updateParamValue(nodeId, body, new ApiResponseListener() {

                                @Override
                                public void onSuccess(Bundle data) {

                                    context.runOnUiThread(new Runnable() {

                                        @Override
                                        public void run() {

                                            paramViewHolder.btnEdit.setVisibility(View.VISIBLE);
                                            paramViewHolder.progressBar.setVisibility(View.GONE);

                                            if (finalIsOn) {

                                                paramViewHolder.tvLabelValue.setText("true");
                                                params.get(position).setLabelValue("true");

                                            } else {
                                                paramViewHolder.tvLabelValue.setText("false");
                                                params.get(position).setLabelValue("false");
                                            }
                                            ((EspDeviceActivity) context).startUpdateValueTask();
                                        }
                                    });
                                }

                                @Override
                                public void onResponseFailure(Exception exception) {

                                    context.runOnUiThread(new Runnable() {

                                        @Override
                                        public void run() {

                                            paramViewHolder.btnEdit.setVisibility(View.VISIBLE);
                                            paramViewHolder.progressBar.setVisibility(View.GONE);
                                            paramViewHolder.tvLabelValue.setText(param.getLabelValue());
                                            ((EspDeviceActivity) context).startUpdateValueTask();
                                        }
                                    });
                                }

                                @Override
                                public void onNetworkFailure(Exception exception) {

                                    context.runOnUiThread(new Runnable() {

                                        @Override
                                        public void run() {

                                            paramViewHolder.btnEdit.setVisibility(View.VISIBLE);
                                            paramViewHolder.progressBar.setVisibility(View.GONE);
                                            paramViewHolder.tvLabelValue.setText(param.getLabelValue());
                                            ((EspDeviceActivity) context).startUpdateValueTask();
                                        }
                                    });
                                }
                            });

                        } else {

                            dialog.dismiss();
                            Toast.makeText(context, R.string.enter_valid_value, Toast.LENGTH_SHORT).show();
                        }
                    } else {

                        dialog.dismiss();
                        Toast.makeText(context, R.string.enter_valid_value, Toast.LENGTH_SHORT).show();
                    }

                } else if (dataType.equalsIgnoreCase("int")
                        || dataType.equalsIgnoreCase("integer")) {

                    int newValue = Integer.valueOf(value);
                    jsonParam.addProperty(param.getName(), newValue);
                    body.add(deviceName, jsonParam);

                    networkApiManager.updateParamValue(nodeId, body, new ApiResponseListener() {

                        @Override
                        public void onSuccess(Bundle data) {

                            context.runOnUiThread(new Runnable() {

                                @Override
                                public void run() {
                                    paramViewHolder.btnEdit.setVisibility(View.VISIBLE);
                                    paramViewHolder.progressBar.setVisibility(View.GONE);
                                    paramViewHolder.tvLabelValue.setText(value);
                                    params.get(position).setLabelValue(value);
                                    ((EspDeviceActivity) context).startUpdateValueTask();
                                }
                            });
                        }

                        @Override
                        public void onResponseFailure(Exception exception) {

                            context.runOnUiThread(new Runnable() {

                                @Override
                                public void run() {
                                    paramViewHolder.btnEdit.setVisibility(View.VISIBLE);
                                    paramViewHolder.progressBar.setVisibility(View.GONE);
                                    paramViewHolder.tvLabelValue.setText(param.getLabelValue());
                                    ((EspDeviceActivity) context).startUpdateValueTask();
                                }
                            });
                        }

                        @Override
                        public void onNetworkFailure(Exception exception) {

                            context.runOnUiThread(new Runnable() {

                                @Override
                                public void run() {
                                    paramViewHolder.btnEdit.setVisibility(View.VISIBLE);
                                    paramViewHolder.progressBar.setVisibility(View.GONE);
                                    paramViewHolder.tvLabelValue.setText(param.getLabelValue());
                                    ((EspDeviceActivity) context).startUpdateValueTask();
                                }
                            });
                        }
                    });

                } else if (dataType.equalsIgnoreCase("float")
                        || dataType.equalsIgnoreCase("double")) {

                    float newValue = Float.valueOf(value);
                    jsonParam.addProperty(param.getName(), newValue);
                    body.add(deviceName, jsonParam);

                    networkApiManager.updateParamValue(nodeId, body, new ApiResponseListener() {

                        @Override
                        public void onSuccess(Bundle data) {

                            context.runOnUiThread(new Runnable() {

                                @Override
                                public void run() {
                                    paramViewHolder.btnEdit.setVisibility(View.VISIBLE);
                                    paramViewHolder.progressBar.setVisibility(View.GONE);
                                    paramViewHolder.tvLabelValue.setText(value);
                                    params.get(position).setLabelValue(value);
                                    ((EspDeviceActivity) context).startUpdateValueTask();
                                }
                            });
                        }

                        @Override
                        public void onResponseFailure(Exception exception) {

                            context.runOnUiThread(new Runnable() {

                                @Override
                                public void run() {
                                    paramViewHolder.btnEdit.setVisibility(View.VISIBLE);
                                    paramViewHolder.progressBar.setVisibility(View.GONE);
                                    paramViewHolder.tvLabelValue.setText(param.getLabelValue());
                                    ((EspDeviceActivity) context).startUpdateValueTask();
                                }
                            });
                        }

                        @Override
                        public void onNetworkFailure(Exception exception) {

                            context.runOnUiThread(new Runnable() {

                                @Override
                                public void run() {
                                    paramViewHolder.btnEdit.setVisibility(View.VISIBLE);
                                    paramViewHolder.progressBar.setVisibility(View.GONE);
                                    paramViewHolder.tvLabelValue.setText(param.getLabelValue());
                                    ((EspDeviceActivity) context).startUpdateValueTask();
                                }
                            });
                        }
                    });

                } else {

                    jsonParam.addProperty(param.getName(), value);
                    body.add(deviceName, jsonParam);

                    networkApiManager.updateParamValue(nodeId, body, new ApiResponseListener() {

                        @Override
                        public void onSuccess(Bundle data) {

                            context.runOnUiThread(new Runnable() {

                                @Override
                                public void run() {

                                    paramViewHolder.btnEdit.setVisibility(View.VISIBLE);
                                    paramViewHolder.progressBar.setVisibility(View.GONE);
                                    paramViewHolder.tvLabelValue.setText(value);
                                    params.get(position).setLabelValue(value);

                                    if (params.get(position).getParamType() != null && params.get(position).getParamType().equals(AppConstants.PARAM_TYPE_NAME)) {
                                        ((EspDeviceActivity) context).updateDeviceNameInTitle(value);
                                    }
                                    ((EspDeviceActivity) context).startUpdateValueTask();
                                }
                            });
                        }

                        @Override
                        public void onResponseFailure(Exception exception) {

                            context.runOnUiThread(new Runnable() {

                                @Override
                                public void run() {
                                    paramViewHolder.btnEdit.setVisibility(View.VISIBLE);
                                    paramViewHolder.progressBar.setVisibility(View.GONE);
                                    paramViewHolder.tvLabelValue.setText(param.getLabelValue());
                                    ((EspDeviceActivity) context).startUpdateValueTask();
                                }
                            });
                        }

                        @Override
                        public void onNetworkFailure(Exception exception) {

                            context.runOnUiThread(new Runnable() {

                                @Override
                                public void run() {
                                    paramViewHolder.btnEdit.setVisibility(View.VISIBLE);
                                    paramViewHolder.progressBar.setVisibility(View.GONE);
                                    paramViewHolder.tvLabelValue.setText(param.getLabelValue());
                                    ((EspDeviceActivity) context).startUpdateValueTask();
                                }
                            });
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

    static class ParamViewHolder extends RecyclerView.ViewHolder {

        ImageView ivSliderStart, ivSliderEnd;
        TickSeekBar intSlider, floatSlider;
        SwitchCompat toggleSwitch;
        TextView tvSliderName, tvSwitchName, tvSwitchStatus, tvLabelName, tvLabelValue, tvLabelPalette,
                tvSpinnerName, tvSpinnerValue, tvTriggerName;
        RelativeLayout rlUiTypeSlider, rlUiTypeSwitch, rlUiTypeLabel, rlPalette, rlUiTypeDropDown, rlUiTypeTrigger;
        TextView btnEdit;
        ContentLoadingProgressBar progressBar, progressBarSpinner;
        PaletteBar paletteBar;
        EspDropDown spinner;
        TapHoldUpButton btnTrigger;

        public ParamViewHolder(View itemView) {
            super(itemView);

            ivSliderStart = itemView.findViewById(R.id.iv_slider_start);
            ivSliderEnd = itemView.findViewById(R.id.iv_slider_end);
            intSlider = itemView.findViewById(R.id.card_int_slider);
            floatSlider = itemView.findViewById(R.id.card_float_slider);
            toggleSwitch = itemView.findViewById(R.id.card_switch);
            tvSliderName = itemView.findViewById(R.id.slider_name);
            tvSwitchName = itemView.findViewById(R.id.switch_name);
            tvSwitchStatus = itemView.findViewById(R.id.tv_switch_status);
            tvLabelName = itemView.findViewById(R.id.tv_label_name);
            tvLabelValue = itemView.findViewById(R.id.tv_label_value);
            tvLabelPalette = itemView.findViewById(R.id.palette_name);
            tvSpinnerName = itemView.findViewById(R.id.tv_spinner_name);
            tvSpinnerValue = itemView.findViewById(R.id.tv_spinner_value);
            tvTriggerName = itemView.findViewById(R.id.tv_trigger_name);
            btnEdit = itemView.findViewById(R.id.btn_edit);
            progressBar = itemView.findViewById(R.id.progress_indicator);
            progressBarSpinner = itemView.findViewById(R.id.progress_indicator_spinner);
            rlUiTypeSlider = itemView.findViewById(R.id.rl_card_slider);
            rlUiTypeSwitch = itemView.findViewById(R.id.rl_card_switch);
            rlUiTypeLabel = itemView.findViewById(R.id.rl_card_label);
            rlPalette = itemView.findViewById(R.id.rl_card_palette);
            rlUiTypeDropDown = itemView.findViewById(R.id.rl_card_drop_down);
            rlUiTypeTrigger = itemView.findViewById(R.id.rl_card_trigger);
            paletteBar = itemView.findViewById(R.id.rl_palette);
            spinner = itemView.findViewById(R.id.card_spinner);
            btnTrigger = itemView.findViewById(R.id.btn_trigger);
        }
    }

    static class HueViewHolder extends RecyclerView.ViewHolder {

        ColorPicker colorPickerView;

        public HueViewHolder(View itemView) {
            super(itemView);
            colorPickerView = itemView.findViewById(R.id.hue_color_picker);
        }
    }

    static class SwitchViewHolder extends RecyclerView.ViewHolder {

        ImageView ivSwitch;

        public SwitchViewHolder(View itemView) {
            super(itemView);
            ivSwitch = itemView.findViewById(R.id.iv_switch);
        }
    }
}
