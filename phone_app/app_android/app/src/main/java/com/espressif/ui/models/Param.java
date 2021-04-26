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

package com.espressif.ui.models;

import android.os.Parcel;
import android.os.Parcelable;

import java.util.ArrayList;

public class Param implements Parcelable {

    private String name;
    private String paramType;
    private String dataType;
    private String uiType;
    private ArrayList<String> properties;
    private int minBounds;
    private int maxBounds;
    private float stepCount;
    private double value;
    private boolean switchStatus;
    private String labelValue;
    private ArrayList<String> validStrings;
    private boolean isDynamicParam;
    private boolean isSelected;

    public Param(Param param) {

        name = param.getName();
        paramType = param.getParamType();
        dataType = param.getDataType();
        uiType = param.getUiType();
        properties = param.getProperties();
        minBounds = param.getMinBounds();
        maxBounds = param.getMaxBounds();
        stepCount = param.getStepCount();
        value = param.getValue();
        switchStatus = param.getSwitchStatus();
        labelValue = param.getLabelValue();
        validStrings = param.getValidStrings();
        isDynamicParam = param.isDynamicParam();
        isSelected = param.isSelected();
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getParamType() {
        return paramType;
    }

    public void setParamType(String paramType) {
        this.paramType = paramType;
    }

    public String getDataType() {
        return dataType;
    }

    public void setDataType(String dataType) {
        this.dataType = dataType;
    }

    public String getUiType() {
        return uiType;
    }

    public void setUiType(String uiType) {
        this.uiType = uiType;
    }

    public ArrayList<String> getProperties() {
        return properties;
    }

    public void setProperties(ArrayList<String> properties) {
        this.properties = properties;
    }

    public int getMinBounds() {
        return minBounds;
    }

    public void setMinBounds(int minBounds) {
        this.minBounds = minBounds;
    }

    public int getMaxBounds() {
        return maxBounds;
    }

    public void setMaxBounds(int maxBounds) {
        this.maxBounds = maxBounds;
    }

    public float getStepCount() {
        return stepCount;
    }

    public void setStepCount(float stepCount) {
        this.stepCount = stepCount;
    }

    public double getValue() {
        return value;
    }

    public void setValue(double value) {
        this.value = value;
    }

    public boolean getSwitchStatus() {
        return switchStatus;
    }

    public void setSwitchStatus(boolean switchStatus) {
        this.switchStatus = switchStatus;
    }

    public String getLabelValue() {
        return labelValue;
    }

    public void setLabelValue(String labelValue) {
        this.labelValue = labelValue;
    }

    public ArrayList<String> getValidStrings() {
        return validStrings;
    }

    public void setValidStrings(ArrayList<String> validStrings) {
        this.validStrings = validStrings;
    }

    public boolean isDynamicParam() {
        return isDynamicParam;
    }

    public void setDynamicParam(boolean dynamicParam) {
        isDynamicParam = dynamicParam;
    }

    public boolean isSelected() {
        return isSelected;
    }

    public void setSelected(boolean selected) {
        isSelected = selected;
    }

    public Param() {
    }

    protected Param(Parcel in) {
        name = in.readString();
        paramType = in.readString();
        dataType = in.readString();
        uiType = in.readString();
        properties = in.createStringArrayList();
        minBounds = in.readInt();
        maxBounds = in.readInt();
        stepCount = in.readFloat();
        value = in.readDouble();
        switchStatus = in.readByte() != 0;
        labelValue = in.readString();
        validStrings = in.createStringArrayList();
        isDynamicParam = in.readByte() != 0;
        isSelected = in.readByte() != 0;
    }

    public static final Creator<Param> CREATOR = new Creator<Param>() {
        @Override
        public Param createFromParcel(Parcel in) {
            return new Param(in);
        }

        @Override
        public Param[] newArray(int size) {
            return new Param[size];
        }
    };

    @Override
    public int describeContents() {
        return 0;
    }

    @Override
    public void writeToParcel(Parcel dest, int flags) {
        dest.writeString(name);
        dest.writeString(paramType);
        dest.writeString(dataType);
        dest.writeString(uiType);
        dest.writeStringList(properties);
        dest.writeInt(minBounds);
        dest.writeInt(maxBounds);
        dest.writeFloat(stepCount);
        dest.writeDouble(value);
        dest.writeByte((byte) (switchStatus ? 1 : 0));
        dest.writeString(labelValue);
        dest.writeStringList(validStrings);
        dest.writeByte((byte) (isDynamicParam ? 1 : 0));
        dest.writeByte((byte) (isSelected ? 1 : 0));
    }

    @Override
    public String toString() {
        return "Param {" +
                "name = '" + name + '\'' +
                ", dataType ='" + dataType + '\'' +
                ", uiType ='" + uiType + '\'' +
                '}';
    }
}
