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

public class Device implements Parcelable {

    private String nodeId;
    private String deviceName;
    private String userVisibleName;
    private String deviceType;
    private String primaryParamName;
    private ArrayList<Param> params;
    private boolean expanded;
    private int selectedState;

    public Device() {
    }

    public Device(Device device) {

        nodeId = device.getNodeId();
        deviceName = device.getDeviceName();
        userVisibleName = device.getUserVisibleName();
        deviceType = device.getDeviceType();
        primaryParamName = device.getPrimaryParamName();
        params = device.getParams();
        expanded = device.isExpanded();
        selectedState = device.getSelectedState();
    }

    public Device(String id) {
        nodeId = id;
    }

    public String getNodeId() {
        return nodeId;
    }

    public String getDeviceName() {
        return deviceName;
    }

    public void setDeviceName(String deviceName) {
        this.deviceName = deviceName;
    }

    public String getUserVisibleName() {
        return userVisibleName;
    }

    public void setUserVisibleName(String userVisibleName) {
        this.userVisibleName = userVisibleName;
    }

    public String getDeviceType() {
        return deviceType;
    }

    public void setDeviceType(String deviceType) {
        this.deviceType = deviceType;
    }

    public String getPrimaryParamName() {
        return primaryParamName;
    }

    public void setPrimaryParamName(String primaryParamName) {
        this.primaryParamName = primaryParamName;
    }

    public ArrayList<Param> getParams() {
        return params;
    }

    public void setParams(ArrayList<Param> params) {
        this.params = params;
    }

    public int getSelectedState() {
        return selectedState;
    }

    public void setSelectedState(int selectedState) {
        this.selectedState = selectedState;
    }

    protected Device(Parcel in) {

        nodeId = in.readString();
        deviceName = in.readString();
        userVisibleName = in.readString();
        deviceType = in.readString();
        primaryParamName = in.readString();
        params = in.createTypedArrayList(Param.CREATOR);
        expanded = in.readByte() != 0;
        selectedState = in.readInt();
    }

    public static final Creator<Device> CREATOR = new Creator<Device>() {
        @Override
        public Device createFromParcel(Parcel in) {
            return new Device(in);
        }

        @Override
        public Device[] newArray(int size) {
            return new Device[size];
        }
    };

    @Override
    public int describeContents() {
        return 0;
    }

    @Override
    public void writeToParcel(Parcel dest, int flags) {

        dest.writeString(nodeId);
        dest.writeString(deviceName);
        dest.writeString(userVisibleName);
        dest.writeString(deviceType);
        dest.writeString(primaryParamName);
        dest.writeTypedList(params);
        dest.writeByte((byte) (expanded ? 1 : 0));
        dest.writeInt(selectedState);
    }

    @Override
    public String toString() {
        return "EspDevice {" +
                "node id = '" + nodeId + '\'' +
                "name = '" + deviceName + '\'' +
                ", type ='" + deviceType + '\'' +
                '}';
    }

    public void setExpanded(boolean expanded) {
        this.expanded = expanded;
    }

    public boolean isExpanded() {
        return expanded;
    }
}
