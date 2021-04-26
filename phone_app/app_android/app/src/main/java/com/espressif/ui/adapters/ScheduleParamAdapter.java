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

public class ScheduleParamAdapter extends RecyclerView.Adapter<ScheduleParamAdapter.ScheduleParamViewHolder> {

    private final String TAG = ScheduleParamAdapter.class.getSimpleName();

    private Activity context;
    private Device device;
    private ArrayList<Param> params;
    private ScheduleActionAdapter parentAdapter;

    public ScheduleParamAdapter(Activity context, ScheduleActionAdapter parentAdapter, Device device, ArrayList<Param> params) {
        this.context = context;
        this.device = device;
        this.params = params;
        this.parentAdapter = parentAdapter;
    }

    @Override
    public ScheduleParamViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {

        // infalte the item Layout
        LayoutInflater layoutInflater = LayoutInflater.from(context);
        View v = layoutInflater.inflate(R.layout.item_schedule_param, parent, false);
        // set the view's size, margins, paddings and layout parameters
        ScheduleParamViewHolder vh = new ScheduleParamViewHolder(v); // pass the view to View Holder
        return vh;
    }

    @Override
    public void onBindViewHolder(@NonNull final ScheduleParamViewHolder scheduleParamVH, int position) {

        Param param = params.get(position);
        scheduleParamVH.cbParamSelect.setChecked(param.isSelected());

        scheduleParamVH.cbParamSelect.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {

            @Override
            public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {

                params.get(scheduleParamVH.getAdapterPosition()).setSelected(isChecked);
                params.set(scheduleParamVH.getAdapterPosition(), params.get(scheduleParamVH.getAdapterPosition()));

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

                    displaySlider(scheduleParamVH, param);
                } else {
                    displayLabel(scheduleParamVH, param, position);
                }
            }

        } else if (AppConstants.UI_TYPE_HUE_SLIDER.equalsIgnoreCase(param.getUiType())) {
            displayPalette(scheduleParamVH, param);
        } else if (AppConstants.UI_TYPE_TOGGLE.equalsIgnoreCase(param.getUiType())) {

            String dataType = param.getDataType();

            if (!TextUtils.isEmpty(dataType) && (dataType.equalsIgnoreCase("bool")
                    || dataType.equalsIgnoreCase("boolean"))) {

                displayToggle(scheduleParamVH, param);

            } else {
                displayLabel(scheduleParamVH, param, position);
            }

        } else if (AppConstants.UI_TYPE_TRIGGER.equalsIgnoreCase(param.getUiType())) {

            String dataType = param.getDataType();

            if (!TextUtils.isEmpty(dataType) && (dataType.equalsIgnoreCase("bool")
                    || dataType.equalsIgnoreCase("boolean"))) {

                displayTrigger(scheduleParamVH, param);

            } else {
                displayLabel(scheduleParamVH, param, position);
            }

        } else if (AppConstants.UI_TYPE_DROP_DOWN.equalsIgnoreCase(param.getUiType())) {

            String dataType = param.getDataType();

            if (!TextUtils.isEmpty(dataType) && (dataType.equalsIgnoreCase("string"))) {

                displaySpinner(scheduleParamVH, param, position);

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
                    displaySpinner(scheduleParamVH, param, position);
                } else {
                    if (spinnerValues.size() > 0) {
                        displaySpinner(scheduleParamVH, param, position);
                    } else {
                        displayLabel(scheduleParamVH, param, position);
                    }
                }
            } else {
                displayLabel(scheduleParamVH, param, position);
            }
        } else {
            displayLabel(scheduleParamVH, param, position);
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

    private void displayPalette(ScheduleParamViewHolder scheduleParamVH, final Param param) {
        scheduleParamVH.rlPalette.setVisibility(View.VISIBLE);
        scheduleParamVH.tvSliderName.setVisibility(View.GONE);
        scheduleParamVH.intSlider.setVisibility(View.GONE);
        scheduleParamVH.tvLabelPalette.setText(param.getName());
        scheduleParamVH.paletteBar.setColor((int) param.getValue());
        scheduleParamVH.paletteBar.setThumbCircleRadius(12);
        scheduleParamVH.paletteBar.setTrackMarkHeight(6);
        if (param.getProperties().contains(AppConstants.KEY_PROPERTY_WRITE)) {

            scheduleParamVH.paletteBar.setEnabled(true);
            scheduleParamVH.paletteBar.setListener(new PaletteBar.PaletteBarListener() {
                @Override
                public void onColorSelected(int colorHue) {
                    param.setValue(colorHue);
                }
            });
        }
    }

    private void displaySlider(final ScheduleParamViewHolder scheduleParamVH, final Param param) {

        scheduleParamVH.rlUiTypeSlider.setVisibility(View.VISIBLE);
        scheduleParamVH.rlUiTypeSwitch.setVisibility(View.GONE);
        scheduleParamVH.rlUiTypeLabel.setVisibility(View.GONE);
        scheduleParamVH.rlUiTypeDropDown.setVisibility(View.GONE);
        scheduleParamVH.rlUiTypeTrigger.setVisibility(View.GONE);

        double sliderValue = param.getValue();
        scheduleParamVH.tvSliderName.setText(param.getName());
        float max = param.getMaxBounds();
        float min = param.getMinBounds();
        String dataType = param.getDataType();

        if (dataType.equalsIgnoreCase("int") || dataType.equalsIgnoreCase("integer")) {

            scheduleParamVH.intSlider.setVisibility(View.VISIBLE);
            scheduleParamVH.floatSlider.setVisibility(View.GONE);

            scheduleParamVH.intSlider.setMax(max);
            scheduleParamVH.intSlider.setMin(min);
            scheduleParamVH.intSlider.setTickCount(2);

            if (sliderValue < min) {

                scheduleParamVH.intSlider.setProgress(min);

            } else if (sliderValue > max) {

                scheduleParamVH.intSlider.setProgress(max);

            } else {
                scheduleParamVH.intSlider.setProgress((int) sliderValue);
            }

            scheduleParamVH.intSlider.setOnSeekChangeListener(new OnSeekChangeListener() {

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

            scheduleParamVH.intSlider.setVisibility(View.GONE);
            scheduleParamVH.floatSlider.setVisibility(View.VISIBLE);

            scheduleParamVH.floatSlider.setMax(max);
            scheduleParamVH.floatSlider.setMin(min);
            scheduleParamVH.floatSlider.setTickCount(2);

            if (sliderValue < min) {

                scheduleParamVH.floatSlider.setProgress(min);

            } else if (sliderValue > max) {

                scheduleParamVH.floatSlider.setProgress(max);

            } else {
                scheduleParamVH.floatSlider.setProgress((float) sliderValue);
            }

            scheduleParamVH.floatSlider.setOnSeekChangeListener(new OnSeekChangeListener() {

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

    private void displayToggle(final ScheduleParamViewHolder scheduleParamVH, final Param param) {

        scheduleParamVH.rlUiTypeSlider.setVisibility(View.GONE);
        scheduleParamVH.rlUiTypeSwitch.setVisibility(View.VISIBLE);
        scheduleParamVH.rlUiTypeLabel.setVisibility(View.GONE);
        scheduleParamVH.rlUiTypeDropDown.setVisibility(View.GONE);
        scheduleParamVH.rlUiTypeTrigger.setVisibility(View.GONE);

        scheduleParamVH.tvSwitchName.setText(param.getName());
        scheduleParamVH.tvSwitchStatus.setVisibility(View.VISIBLE);

        if (param.getSwitchStatus()) {

            scheduleParamVH.tvSwitchStatus.setText(R.string.text_on);

        } else {
            scheduleParamVH.tvSwitchStatus.setText(R.string.text_off);
        }

        scheduleParamVH.toggleSwitch.setVisibility(View.VISIBLE);
        scheduleParamVH.toggleSwitch.setChecked(param.getSwitchStatus());
        scheduleParamVH.toggleSwitch.setEnabled(true);

        scheduleParamVH.toggleSwitch.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {

            @Override
            public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {

                if (isChecked) {

                    scheduleParamVH.tvSwitchStatus.setText(R.string.text_on);

                } else {
                    scheduleParamVH.tvSwitchStatus.setText(R.string.text_off);
                }
                param.setSwitchStatus(isChecked);
            }
        });
    }

    private void displayTrigger(final ScheduleParamViewHolder scheduleParamVH, final Param param) {

        scheduleParamVH.rlUiTypeSlider.setVisibility(View.GONE);
        scheduleParamVH.rlUiTypeSwitch.setVisibility(View.GONE);
        scheduleParamVH.rlUiTypeLabel.setVisibility(View.GONE);
        scheduleParamVH.rlUiTypeDropDown.setVisibility(View.GONE);
        scheduleParamVH.rlUiTypeTrigger.setVisibility(View.VISIBLE);
        scheduleParamVH.tvTriggerName.setText(param.getName());
    }

    private void displayLabel(final ScheduleParamViewHolder scheduleParamVH, final Param param, final int position) {

        scheduleParamVH.rlUiTypeSlider.setVisibility(View.GONE);
        scheduleParamVH.rlUiTypeSwitch.setVisibility(View.GONE);
        scheduleParamVH.rlUiTypeLabel.setVisibility(View.VISIBLE);
        scheduleParamVH.rlUiTypeDropDown.setVisibility(View.GONE);
        scheduleParamVH.rlUiTypeTrigger.setVisibility(View.GONE);

        scheduleParamVH.tvLabelName.setText(param.getName());
        scheduleParamVH.tvLabelValue.setText(param.getLabelValue());

        scheduleParamVH.btnEdit.setVisibility(View.VISIBLE);

        scheduleParamVH.btnEdit.setOnClickListener(new View.OnClickListener() {

            @Override
            public void onClick(View v) {
                askForNewValue(scheduleParamVH, param, position);
            }
        });
    }

    private void displaySpinner(final ScheduleParamViewHolder scheduleParamVH, final Param param, final int position) {

        scheduleParamVH.rlUiTypeSlider.setVisibility(View.GONE);
        scheduleParamVH.rlUiTypeSwitch.setVisibility(View.GONE);
        scheduleParamVH.rlUiTypeLabel.setVisibility(View.GONE);
        scheduleParamVH.rlPalette.setVisibility(View.GONE);
        scheduleParamVH.rlUiTypeDropDown.setVisibility(View.VISIBLE);
        scheduleParamVH.rlUiTypeTrigger.setVisibility(View.GONE);

        scheduleParamVH.tvSpinnerName.setText(param.getName());
        scheduleParamVH.spinner.setVisibility(View.VISIBLE);

        scheduleParamVH.spinner.setEnabled(false);
        scheduleParamVH.spinner.setOnItemSelectedListener(null);

        final String dataType = param.getDataType();

        if (!TextUtils.isEmpty(dataType) && (dataType.equalsIgnoreCase("string"))) {

            if (param.getValidStrings() != null && param.getValidStrings().size() > 0) {

                ArrayList<String> spinnerValues = new ArrayList<>();
                spinnerValues.addAll(param.getValidStrings());
                ArrayAdapter<String> dataAdapter = new ArrayAdapter<String>(context, android.R.layout.simple_spinner_item, spinnerValues);
                dataAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
                scheduleParamVH.spinner.setAdapter(dataAdapter);
                boolean isValueFound = false;
                String value = param.getLabelValue();

                for (int i = 0; i < param.getValidStrings().size(); i++) {

                    if (!TextUtils.isEmpty(value)) {

                        if (value.equals(param.getValidStrings().get(i))) {
                            isValueFound = true;
                            scheduleParamVH.spinner.setSelection(i, false);
                            scheduleParamVH.spinner.setTag(R.id.position, i);
                            break;
                        }
                    }
                }

                if (!isValueFound) {
                    spinnerValues.add(0, "");
                    scheduleParamVH.spinner.setSelection(0, false);
                    scheduleParamVH.spinner.setTag(R.id.position, 0);
                    dataAdapter.notifyDataSetChanged();
                    String strInvalidValue = "" + value + " (" + context.getString(R.string.invalid) + ")";
                    scheduleParamVH.tvSpinnerValue.setText(strInvalidValue);
                    scheduleParamVH.tvSpinnerValue.setVisibility(View.VISIBLE);
                } else {
                    scheduleParamVH.tvSpinnerValue.setVisibility(View.GONE);
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
                scheduleParamVH.spinner.setAdapter(dataAdapter);

                if (sliderValue < min) {

                    scheduleParamVH.spinner.setSelection(0);
                    scheduleParamVH.spinner.setTag(R.id.position, 0);

                } else if (sliderValue > max) {

                    int lastPosition = spinnerValues.size() - 1;
                    scheduleParamVH.spinner.setSelection(lastPosition);
                    scheduleParamVH.spinner.setTag(R.id.position, lastPosition);

                } else {

                    boolean isValueFound = false;
                    for (int i = 0; i < spinnerValues.size(); i++) {

                        String value = spinnerValues.get(i);
                        int intValue = Integer.parseInt(value);

                        if (sliderValue == intValue) {
                            isValueFound = true;
                            scheduleParamVH.spinner.setSelection(i, false);
                            scheduleParamVH.spinner.setTag(R.id.position, i);
                            break;
                        }
                    }

                    if (!isValueFound) {
                        spinnerValues.add(0, "");
                        scheduleParamVH.spinner.setSelection(0, false);
                        scheduleParamVH.spinner.setTag(R.id.position, 0);
                        dataAdapter.notifyDataSetChanged();
                        String strInvalidValue = "" + sliderValue + " (" + context.getString(R.string.invalid) + ")";
                        scheduleParamVH.tvSpinnerValue.setText(strInvalidValue);
                        scheduleParamVH.tvSpinnerValue.setVisibility(View.VISIBLE);
                    } else {
                        scheduleParamVH.tvSpinnerValue.setVisibility(View.GONE);
                    }
                }
            } else {
                // Displayed label for this condition.
            }
        }

        if (param.getProperties().contains(AppConstants.KEY_PROPERTY_WRITE)) {

            scheduleParamVH.spinner.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {

                @Override
                public void onItemSelected(AdapterView<?> parent, View view, final int pos, long id) {

                    Log.d(TAG, "Dropdown list item clicked position :  " + scheduleParamVH.spinner.getTag(R.id.position));

                    if ((int) scheduleParamVH.spinner.getTag(R.id.position) != pos) {

                        final String newValue = parent.getItemAtPosition(pos).toString();
                        scheduleParamVH.spinner.setTag(R.id.position, pos);

                        if (!TextUtils.isEmpty(dataType) && (dataType.equalsIgnoreCase("string"))) {

                            params.get(position).setLabelValue(newValue);
                            scheduleParamVH.tvSpinnerValue.setVisibility(View.GONE);

                        } else if (!TextUtils.isEmpty(dataType) && (dataType.equalsIgnoreCase("int")
                                || dataType.equalsIgnoreCase("integer"))) {

                            params.get(position).setValue(Integer.parseInt(newValue));
                            scheduleParamVH.tvSpinnerValue.setVisibility(View.GONE);
                        }
                    }
                }

                @Override
                public void onNothingSelected(AdapterView<?> parent) {
                }
            });
            scheduleParamVH.spinner.setEnabled(true);

        } else {
            scheduleParamVH.spinner.setOnItemSelectedListener(null);
        }
    }

    private void askForNewValue(final ScheduleParamViewHolder scheduleParamVH, final Param param, final int position) {

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

                                scheduleParamVH.tvLabelValue.setText("true");
                                params.get(position).setLabelValue("true");

                            } else {
                                scheduleParamVH.tvLabelValue.setText("false");
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

                    scheduleParamVH.btnEdit.setVisibility(View.VISIBLE);
                    scheduleParamVH.tvLabelValue.setText(value);
                    params.get(position).setLabelValue(value);

                } else if (dataType.equalsIgnoreCase("float")
                        || dataType.equalsIgnoreCase("double")) {

                    float newValue = Float.valueOf(value);
                    scheduleParamVH.btnEdit.setVisibility(View.VISIBLE);
                    scheduleParamVH.tvLabelValue.setText(value);
                    params.get(position).setLabelValue(value);

                } else {

                    scheduleParamVH.btnEdit.setVisibility(View.VISIBLE);
                    scheduleParamVH.tvLabelValue.setText(value);
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

    static class ScheduleParamViewHolder extends RecyclerView.ViewHolder {

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

        public ScheduleParamViewHolder(View itemView) {
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
