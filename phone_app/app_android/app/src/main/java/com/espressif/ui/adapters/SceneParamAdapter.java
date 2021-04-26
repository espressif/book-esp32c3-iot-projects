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

package com.espressif.ui.adapters;

import android.app.Activity;
import android.content.DialogInterface;
import android.text.InputFilter;
import android.text.InputType;
import android.text.TextUtils;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.CompoundButton;
import android.widget.EditText;
import android.widget.RelativeLayout;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.widget.AppCompatCheckBox;
import androidx.appcompat.widget.SwitchCompat;
import androidx.recyclerview.widget.RecyclerView;

import com.aar.tapholdupbutton.TapHoldUpButton;
import com.espressif.AppConstants;
import com.espressif.rainmaker.R;
import com.espressif.ui.models.Device;
import com.espressif.ui.models.Param;
import com.espressif.ui.widgets.EspDropDown;
import com.espressif.ui.widgets.PaletteBar;
import com.warkiz.tickseekbar.OnSeekChangeListener;
import com.warkiz.tickseekbar.SeekParams;
import com.warkiz.tickseekbar.TickSeekBar;

import java.util.ArrayList;

public class SceneParamAdapter extends RecyclerView.Adapter<SceneParamAdapter.SceneParamViewHolder> {

    private final String TAG = SceneParamAdapter.class.getSimpleName();

    private Activity context;
    private Device device;
    private ArrayList<Param> params;
    private SceneActionAdapter parentAdapter;

    public SceneParamAdapter(Activity context, SceneActionAdapter parentAdapter, Device device, ArrayList<Param> params) {
        this.context = context;
        this.device = device;
        this.params = params;
        this.parentAdapter = parentAdapter;
    }

    @Override
    public SceneParamViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {

        // inflate the item Layout
        LayoutInflater layoutInflater = LayoutInflater.from(context);
        View v = layoutInflater.inflate(R.layout.item_schedule_param, parent, false);
        // set the view's size, margins, paddings and layout parameters
        SceneParamViewHolder vh = new SceneParamViewHolder(v); // pass the view to View Holder
        return vh;
    }

    @Override
    public void onBindViewHolder(@NonNull final SceneParamViewHolder sceneParamVH, int position) {

        Param param = params.get(position);
        sceneParamVH.cbParamSelect.setChecked(param.isSelected());

        sceneParamVH.cbParamSelect.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {

            @Override
            public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {

                params.get(sceneParamVH.getAdapterPosition()).setSelected(isChecked);
                params.set(sceneParamVH.getAdapterPosition(), params.get(sceneParamVH.getAdapterPosition()));

                boolean isSelected = false, isUnselected = false;
                for (int i = 0; i < params.size(); i++) {
                    if (params.get(i).isSelected()) {
                        isSelected = true;
                    } else {
                        isUnselected = true;
                    }
                }

                if (isSelected) {
                    if (isUnselected) {
                        device.setSelectedState(2);
                    } else {
                        device.setSelectedState(1);
                    }
                } else {
                    device.setSelectedState(0);
                }

                device.setParams(params);
                if (parentAdapter != null) {
                    parentAdapter.notifyDataSetChanged();
                }
            }
        });

        if (AppConstants.UI_TYPE_SLIDER.equalsIgnoreCase(param.getUiType())) {

            String dataType = param.getDataType();

            if (!TextUtils.isEmpty(dataType) && (dataType.equalsIgnoreCase("int")
                    || dataType.equalsIgnoreCase("integer")
                    || dataType.equalsIgnoreCase("float")
                    || dataType.equalsIgnoreCase("double"))) {

                int max = param.getMaxBounds();
                int min = param.getMinBounds();

                if ((min < max)) {

                    displaySlider(sceneParamVH, param);
                } else {
                    displayLabel(sceneParamVH, param, position);
                }
            }

        } else if (AppConstants.UI_TYPE_HUE_SLIDER.equalsIgnoreCase(param.getUiType())) {
            displayPalette(sceneParamVH, param);
        } else if (AppConstants.UI_TYPE_TOGGLE.equalsIgnoreCase(param.getUiType())) {

            String dataType = param.getDataType();

            if (!TextUtils.isEmpty(dataType) && (dataType.equalsIgnoreCase("bool")
                    || dataType.equalsIgnoreCase("boolean"))) {

                displayToggle(sceneParamVH, param);

            } else {
                displayLabel(sceneParamVH, param, position);
            }

        } else if (AppConstants.UI_TYPE_TRIGGER.equalsIgnoreCase(param.getUiType())) {

            String dataType = param.getDataType();

            if (!TextUtils.isEmpty(dataType) && (dataType.equalsIgnoreCase("bool")
                    || dataType.equalsIgnoreCase("boolean"))) {

                displayTrigger(sceneParamVH, param);

            } else {
                displayLabel(sceneParamVH, param, position);
            }

        } else if (AppConstants.UI_TYPE_DROP_DOWN.equalsIgnoreCase(param.getUiType())) {

            String dataType = param.getDataType();

            if (!TextUtils.isEmpty(dataType) && (dataType.equalsIgnoreCase("string"))) {

                displaySpinner(sceneParamVH, param, position);

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
                    displaySpinner(sceneParamVH, param, position);
                } else {
                    if (spinnerValues.size() > 0) {
                        displaySpinner(sceneParamVH, param, position);
                    } else {
                        displayLabel(sceneParamVH, param, position);
                    }
                }
            } else {
                displayLabel(sceneParamVH, param, position);
            }
        } else {
            displayLabel(sceneParamVH, param, position);
        }
    }

    @Override
    public int getItemCount() {
        return params.size();
    }

    public void removeItem(int position) {
        params.remove(position);
        // notify the item removed by position
        // to perform recycler view delete animations
        // NOTE: don't call notifyDataSetChanged()
        notifyItemRemoved(position);
    }

    private void displayPalette(SceneParamViewHolder sceneParamVH, final Param param) {
        sceneParamVH.rlPalette.setVisibility(View.VISIBLE);
        sceneParamVH.tvSliderName.setVisibility(View.GONE);
        sceneParamVH.intSlider.setVisibility(View.GONE);
        sceneParamVH.tvLabelPalette.setText(param.getName());
        sceneParamVH.paletteBar.setColor((int) param.getValue());
        sceneParamVH.paletteBar.setThumbCircleRadius(12);
        sceneParamVH.paletteBar.setTrackMarkHeight(6);
        if (param.getProperties().contains(AppConstants.KEY_PROPERTY_WRITE)) {

            sceneParamVH.paletteBar.setEnabled(true);
            sceneParamVH.paletteBar.setListener(new PaletteBar.PaletteBarListener() {
                @Override
                public void onColorSelected(int colorHue) {
                    param.setValue(colorHue);
                }
            });
        }
    }

    private void displaySlider(final SceneParamViewHolder sceneParamVH, final Param param) {

        sceneParamVH.rlUiTypeSlider.setVisibility(View.VISIBLE);
        sceneParamVH.rlUiTypeSwitch.setVisibility(View.GONE);
        sceneParamVH.rlUiTypeLabel.setVisibility(View.GONE);
        sceneParamVH.rlUiTypeDropDown.setVisibility(View.GONE);
        sceneParamVH.rlUiTypeTrigger.setVisibility(View.GONE);

        double sliderValue = param.getValue();
        sceneParamVH.tvSliderName.setText(param.getName());
        float max = param.getMaxBounds();
        float min = param.getMinBounds();
        String dataType = param.getDataType();

        if (dataType.equalsIgnoreCase("int") || dataType.equalsIgnoreCase("integer")) {

            sceneParamVH.intSlider.setVisibility(View.VISIBLE);
            sceneParamVH.floatSlider.setVisibility(View.GONE);

            sceneParamVH.intSlider.setMax(max);
            sceneParamVH.intSlider.setMin(min);
            sceneParamVH.intSlider.setTickCount(2);

            if (sliderValue < min) {

                sceneParamVH.intSlider.setProgress(min);

            } else if (sliderValue > max) {

                sceneParamVH.intSlider.setProgress(max);

            } else {
                sceneParamVH.intSlider.setProgress((int) sliderValue);
            }

            sceneParamVH.intSlider.setOnSeekChangeListener(new OnSeekChangeListener() {

                @Override
                public void onSeeking(SeekParams seekParams) {
                }

                @Override
                public void onStartTrackingTouch(TickSeekBar seekBar) {
                }

                @Override
                public void onStopTrackingTouch(TickSeekBar seekBar) {
                    int progress = seekBar.getProgress();
                    param.setValue(progress);
                }
            });

        } else {

            sceneParamVH.intSlider.setVisibility(View.GONE);
            sceneParamVH.floatSlider.setVisibility(View.VISIBLE);

            sceneParamVH.floatSlider.setMax(max);
            sceneParamVH.floatSlider.setMin(min);
            sceneParamVH.floatSlider.setTickCount(2);

            if (sliderValue < min) {

                sceneParamVH.floatSlider.setProgress(min);

            } else if (sliderValue > max) {

                sceneParamVH.floatSlider.setProgress(max);

            } else {
                sceneParamVH.floatSlider.setProgress((float) sliderValue);
            }

            sceneParamVH.floatSlider.setOnSeekChangeListener(new OnSeekChangeListener() {

                @Override
                public void onSeeking(SeekParams seekParams) {
                }

                @Override
                public void onStartTrackingTouch(TickSeekBar seekBar) {
                }

                @Override
                public void onStopTrackingTouch(TickSeekBar seekBar) {
                    float progress = seekBar.getProgressFloat();
                    param.setValue(progress);
                }
            });
        }
    }

    private void displayToggle(final SceneParamViewHolder sceneParamVH, final Param param) {

        sceneParamVH.rlUiTypeSlider.setVisibility(View.GONE);
        sceneParamVH.rlUiTypeSwitch.setVisibility(View.VISIBLE);
        sceneParamVH.rlUiTypeLabel.setVisibility(View.GONE);
        sceneParamVH.rlUiTypeDropDown.setVisibility(View.GONE);
        sceneParamVH.rlUiTypeTrigger.setVisibility(View.GONE);

        sceneParamVH.tvSwitchName.setText(param.getName());
        sceneParamVH.tvSwitchStatus.setVisibility(View.VISIBLE);

        if (param.getSwitchStatus()) {

            sceneParamVH.tvSwitchStatus.setText(R.string.text_on);

        } else {
            sceneParamVH.tvSwitchStatus.setText(R.string.text_off);
        }

        sceneParamVH.toggleSwitch.setVisibility(View.VISIBLE);
        sceneParamVH.toggleSwitch.setChecked(param.getSwitchStatus());
        sceneParamVH.toggleSwitch.setEnabled(true);

        sceneParamVH.toggleSwitch.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {

            @Override
            public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {

                if (isChecked) {

                    sceneParamVH.tvSwitchStatus.setText(R.string.text_on);

                } else {
                    sceneParamVH.tvSwitchStatus.setText(R.string.text_off);
                }
                param.setSwitchStatus(isChecked);
            }
        });
    }

    private void displayTrigger(final SceneParamViewHolder sceneParamVH, final Param param) {

        sceneParamVH.rlUiTypeSlider.setVisibility(View.GONE);
        sceneParamVH.rlUiTypeSwitch.setVisibility(View.GONE);
        sceneParamVH.rlUiTypeLabel.setVisibility(View.GONE);
        sceneParamVH.rlUiTypeDropDown.setVisibility(View.GONE);
        sceneParamVH.rlUiTypeTrigger.setVisibility(View.VISIBLE);
        sceneParamVH.tvTriggerName.setText(param.getName());
    }

    private void displayLabel(final SceneParamViewHolder sceneParamVH, final Param param, final int position) {

        sceneParamVH.rlUiTypeSlider.setVisibility(View.GONE);
        sceneParamVH.rlUiTypeSwitch.setVisibility(View.GONE);
        sceneParamVH.rlUiTypeLabel.setVisibility(View.VISIBLE);
        sceneParamVH.rlUiTypeDropDown.setVisibility(View.GONE);
        sceneParamVH.rlUiTypeTrigger.setVisibility(View.GONE);

        sceneParamVH.tvLabelName.setText(param.getName());
        sceneParamVH.tvLabelValue.setText(param.getLabelValue());

        sceneParamVH.btnEdit.setVisibility(View.VISIBLE);

        sceneParamVH.btnEdit.setOnClickListener(new View.OnClickListener() {

            @Override
            public void onClick(View v) {
                askForNewValue(sceneParamVH, param, position);
            }
        });
    }

    private void displaySpinner(final SceneParamViewHolder sceneParamVH, final Param param, final int position) {

        sceneParamVH.rlUiTypeSlider.setVisibility(View.GONE);
        sceneParamVH.rlUiTypeSwitch.setVisibility(View.GONE);
        sceneParamVH.rlUiTypeLabel.setVisibility(View.GONE);
        sceneParamVH.rlPalette.setVisibility(View.GONE);
        sceneParamVH.rlUiTypeDropDown.setVisibility(View.VISIBLE);
        sceneParamVH.rlUiTypeTrigger.setVisibility(View.GONE);

        sceneParamVH.tvSpinnerName.setText(param.getName());
        sceneParamVH.spinner.setVisibility(View.VISIBLE);

        sceneParamVH.spinner.setEnabled(false);
        sceneParamVH.spinner.setOnItemSelectedListener(null);

        final String dataType = param.getDataType();

        if (!TextUtils.isEmpty(dataType) && (dataType.equalsIgnoreCase("string"))) {

            if (param.getValidStrings() != null && param.getValidStrings().size() > 0) {

                ArrayList<String> spinnerValues = new ArrayList<>();
                spinnerValues.addAll(param.getValidStrings());
                ArrayAdapter<String> dataAdapter = new ArrayAdapter<String>(context, android.R.layout.simple_spinner_item, spinnerValues);
                dataAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
                sceneParamVH.spinner.setAdapter(dataAdapter);
                boolean isValueFound = false;
                String value = param.getLabelValue();

                for (int i = 0; i < param.getValidStrings().size(); i++) {

                    if (!TextUtils.isEmpty(value)) {

                        if (value.equals(param.getValidStrings().get(i))) {
                            isValueFound = true;
                            sceneParamVH.spinner.setSelection(i, false);
                            sceneParamVH.spinner.setTag(R.id.position, i);
                            break;
                        }
                    }
                }

                if (!isValueFound) {
                    spinnerValues.add(0, "");
                    sceneParamVH.spinner.setSelection(0, false);
                    sceneParamVH.spinner.setTag(R.id.position, 0);
                    dataAdapter.notifyDataSetChanged();
                    String strInvalidValue = "" + value + " (" + context.getString(R.string.invalid) + ")";
                    sceneParamVH.tvSpinnerValue.setText(strInvalidValue);
                    sceneParamVH.tvSpinnerValue.setVisibility(View.VISIBLE);
                } else {
                    sceneParamVH.tvSpinnerValue.setVisibility(View.GONE);
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
                sceneParamVH.spinner.setAdapter(dataAdapter);

                if (sliderValue < min) {

                    sceneParamVH.spinner.setSelection(0);
                    sceneParamVH.spinner.setTag(R.id.position, 0);

                } else if (sliderValue > max) {

                    int lastPosition = spinnerValues.size() - 1;
                    sceneParamVH.spinner.setSelection(lastPosition);
                    sceneParamVH.spinner.setTag(R.id.position, lastPosition);

                } else {

                    boolean isValueFound = false;
                    for (int i = 0; i < spinnerValues.size(); i++) {

                        String value = spinnerValues.get(i);
                        int intValue = Integer.parseInt(value);

                        if (sliderValue == intValue) {
                            isValueFound = true;
                            sceneParamVH.spinner.setSelection(i, false);
                            sceneParamVH.spinner.setTag(R.id.position, i);
                            break;
                        }
                    }

                    if (!isValueFound) {
                        spinnerValues.add(0, "");
                        sceneParamVH.spinner.setSelection(0, false);
                        sceneParamVH.spinner.setTag(R.id.position, 0);
                        dataAdapter.notifyDataSetChanged();
                        String strInvalidValue = "" + sliderValue + " (" + context.getString(R.string.invalid) + ")";
                        sceneParamVH.tvSpinnerValue.setText(strInvalidValue);
                        sceneParamVH.tvSpinnerValue.setVisibility(View.VISIBLE);
                    } else {
                        sceneParamVH.tvSpinnerValue.setVisibility(View.GONE);
                    }
                }
            } else {
                // Displayed label for this condition.
            }
        }

        if (param.getProperties().contains(AppConstants.KEY_PROPERTY_WRITE)) {

            sceneParamVH.spinner.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {

                @Override
                public void onItemSelected(AdapterView<?> parent, View view, final int pos, long id) {

                    Log.d(TAG, "Dropdown list item clicked position :  " + sceneParamVH.spinner.getTag(R.id.position));

                    if ((int) sceneParamVH.spinner.getTag(R.id.position) != pos) {

                        final String newValue = parent.getItemAtPosition(pos).toString();
                        sceneParamVH.spinner.setTag(R.id.position, pos);

                        if (!TextUtils.isEmpty(dataType) && (dataType.equalsIgnoreCase("string"))) {

                            params.get(position).setLabelValue(newValue);
                            sceneParamVH.tvSpinnerValue.setVisibility(View.GONE);

                        } else if (!TextUtils.isEmpty(dataType) && (dataType.equalsIgnoreCase("int")
                                || dataType.equalsIgnoreCase("integer"))) {

                            params.get(position).setValue(Integer.parseInt(newValue));
                            sceneParamVH.tvSpinnerValue.setVisibility(View.GONE);
                        }
                    }
                }

                @Override
                public void onNothingSelected(AdapterView<?> parent) {
                }
            });
            sceneParamVH.spinner.setEnabled(true);

        } else {
            sceneParamVH.spinner.setOnItemSelectedListener(null);
        }
    }

    private void askForNewValue(final SceneParamViewHolder sceneParamVH, final Param param, final int position) {

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

                if (dataType.equalsIgnoreCase("bool")
                        || dataType.equalsIgnoreCase("boolean")) {

                    if (!TextUtils.isEmpty(value)) {

                        if (value.equalsIgnoreCase("true") || value.equalsIgnoreCase("false")
                                || value.equalsIgnoreCase("0") || value.equalsIgnoreCase("1")) {

                            boolean isOn = false;

                            if (value.equalsIgnoreCase("true") || value.equalsIgnoreCase("1")) {
                                isOn = true;
                            }

                            if (isOn) {

                                sceneParamVH.tvLabelValue.setText("true");
                                params.get(position).setLabelValue("true");

                            } else {
                                sceneParamVH.tvLabelValue.setText("false");
                                params.get(position).setLabelValue("false");
                            }

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

                    sceneParamVH.btnEdit.setVisibility(View.VISIBLE);
                    sceneParamVH.tvLabelValue.setText(value);
                    params.get(position).setLabelValue(value);

                } else if (dataType.equalsIgnoreCase("float")
                        || dataType.equalsIgnoreCase("double")) {

                    float newValue = Float.valueOf(value);
                    sceneParamVH.btnEdit.setVisibility(View.VISIBLE);
                    sceneParamVH.tvLabelValue.setText(value);
                    params.get(position).setLabelValue(value);

                } else {

                    sceneParamVH.btnEdit.setVisibility(View.VISIBLE);
                    sceneParamVH.tvLabelValue.setText(value);
                    params.get(position).setLabelValue(value);
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

    static class SceneParamViewHolder extends RecyclerView.ViewHolder {

        // init the item view's
        TickSeekBar intSlider, floatSlider;
        SwitchCompat toggleSwitch;
        TextView tvSliderName, tvSwitchName, tvSwitchStatus, tvLabelName, tvLabelValue, tvLabelPalette,
                tvSpinnerName, tvSpinnerValue, tvTriggerName;
        RelativeLayout rlUiTypeSlider, rlUiTypeSwitch, rlUiTypeLabel, rlPalette, rlUiTypeDropDown, rlUiTypeTrigger;
        TextView btnEdit;
        AppCompatCheckBox cbParamSelect;
        PaletteBar paletteBar;
        EspDropDown spinner;
        TapHoldUpButton btnTrigger;

        public SceneParamViewHolder(View itemView) {
            super(itemView);

            // get the reference of item view's
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
            cbParamSelect = itemView.findViewById(R.id.cb_param_select);
            rlUiTypeSlider = itemView.findViewById(R.id.rl_card_slider);
            rlUiTypeSwitch = itemView.findViewById(R.id.rl_card_switch);
            rlUiTypeLabel = itemView.findViewById(R.id.rl_card_label);
            rlPalette = itemView.findViewById(R.id.rl_card_palette);
            rlUiTypeDropDown = itemView.findViewById(R.id.rl_card_drop_down);
            rlUiTypeTrigger = itemView.findViewById(R.id.rl_card_trigger);
            paletteBar = itemView.findViewById(R.id.rl_palette);
            spinner = itemView.findViewById(R.id.card_spinner);
            tvSpinnerValue.setVisibility(View.GONE);
            btnTrigger = itemView.findViewById(R.id.btn_trigger);
        }
    }
}
