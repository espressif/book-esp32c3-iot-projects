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

import androidx.annotation.NonNull;
import androidx.room.ColumnInfo;
import androidx.room.Entity;
import androidx.room.Ignore;
import androidx.room.PrimaryKey;

import com.espressif.AppConstants;

import java.util.ArrayList;

@Entity(tableName = AppConstants.NODE_TABLE)
public class EspNode implements Parcelable {

    @PrimaryKey
    @NonNull
    private String nodeId;

    @Ignore
    private String userRole;

    @Ignore
    private String configVersion;

    @Ignore
    private String nodeName;

    @Ignore
    private String fwVersion;

    @Ignore
    private String nodeType;

    @Ignore
    private boolean isOnline;

    @Ignore
    private long timeStampOfStatus; // timestamp of connectivity status

    @Ignore
    private ArrayList<Device> devices;

    @Ignore
    private ArrayList<Param> attributes;

    @Ignore
    private ArrayList<Service> services;

    @Ignore
    private boolean isAvailableLocally;

    @Ignore
    private String ipAddress;

    @Ignore
    private int port;

    @ColumnInfo(name = "config_data")
    private String configData;

    @ColumnInfo(name = "param_data")
    private String paramData;

    @Ignore
    private boolean isSelected;

    @Ignore
    private ArrayList<String> primaryUsers;

    @Ignore
    private ArrayList<String> secondaryUsers;

    public EspNode() {
    }

    public EspNode(String id) {
        nodeId = id;
    }

    public EspNode(EspNode node) {

        nodeId = node.getNodeId();
        userRole = node.getUserRole();
        configVersion = node.getConfigVersion();
        nodeName = node.getNodeName();
        fwVersion = node.getFwVersion();
        nodeType = node.getNodeType();
        isOnline = node.isOnline();
        timeStampOfStatus = node.getTimeStampOfStatus();
        devices = node.getDevices();
        attributes = node.getAttributes();
        services = node.getServices();
        isAvailableLocally = node.isAvailableLocally();
        ipAddress = node.getIpAddress();
        port = node.getPort();
        configData = node.getConfigData();
        paramData = node.getParamData();
        isSelected = node.isSelected();
        primaryUsers = node.getPrimaryUsers();
        secondaryUsers = node.getSecondaryUsers();
    }

    public String getNodeId() {
        return nodeId;
    }

    public void setNodeId(String nodeId) {
        this.nodeId = nodeId;
    }

    public String getUserRole() {
        return userRole;
    }

    public void setUserRole(String userRole) {
        this.userRole = userRole;
    }

    public String getConfigVersion() {
        return configVersion;
    }

    public void setConfigVersion(String configVersion) {
        this.configVersion = configVersion;
    }

    public String getNodeName() {
        return nodeName;
    }

    public void setNodeName(String nodeName) {
        this.nodeName = nodeName;
    }

    public String getFwVersion() {
        return fwVersion;
    }

    public void setFwVersion(String fwVersion) {
        this.fwVersion = fwVersion;
    }

    public String getNodeType() {
        return nodeType;
    }

    public void setNodeType(String nodeType) {
        this.nodeType = nodeType;
    }

    public boolean isOnline() {
        return isOnline;
    }

    public void setOnline(boolean online) {
        isOnline = online;
    }

    public long getTimeStampOfStatus() {
        return timeStampOfStatus;
    }

    public void setTimeStampOfStatus(long timeStampOfStatus) {
        this.timeStampOfStatus = timeStampOfStatus;
    }

    public ArrayList<Device> getDevices() {
        return devices;
    }

    public void setDevices(ArrayList<Device> devices) {
        this.devices = devices;
    }

    public ArrayList<Param> getAttributes() {
        return attributes;
    }

    public void setAttributes(ArrayList<Param> attributes) {
        this.attributes = attributes;
    }

    public ArrayList<Service> getServices() {
        return services;
    }

    public void setServices(ArrayList<Service> services) {
        this.services = services;
    }

    public boolean isAvailableLocally() {
        return isAvailableLocally;
    }

    public void setAvailableLocally(boolean availableLocally) {
        isAvailableLocally = availableLocally;
    }

    public String getIpAddress() {
        return ipAddress;
    }

    public void setIpAddress(String ipAddress) {
        this.ipAddress = ipAddress;
    }

    public int getPort() {
        return port;
    }

    public void setPort(int port) {
        this.port = port;
    }

    public String getConfigData() {
        return configData;
    }

    public void setConfigData(String configData) {
        this.configData = configData;
    }

    public String getParamData() {
        return paramData;
    }

    public void setParamData(String paramData) {
        this.paramData = paramData;
    }

    public boolean isSelected() {
        return isSelected;
    }

    public void setSelected(boolean selected) {
        isSelected = selected;
    }

    public ArrayList<String> getPrimaryUsers() {
        if (primaryUsers == null) {
            primaryUsers = new ArrayList<>();
        }
        return primaryUsers;
    }

    public void setPrimaryUsers(ArrayList<String> primaryUsers) {
        this.primaryUsers = primaryUsers;
    }

    public ArrayList<String> getSecondaryUsers() {
        if (secondaryUsers == null) {
            secondaryUsers = new ArrayList<>();
        }
        return secondaryUsers;
    }

    public void setSecondaryUsers(ArrayList<String> secondaryUsers) {
        this.secondaryUsers = secondaryUsers;
    }

    protected EspNode(Parcel in) {

        nodeId = in.readString();
        userRole = in.readString();
        configVersion = in.readString();
        nodeName = in.readString();
        fwVersion = in.readString();
        nodeType = in.readString();
        isOnline = in.readByte() != 0;
        timeStampOfStatus = in.readLong();
        devices = in.createTypedArrayList(Device.CREATOR);
        attributes = in.createTypedArrayList(Param.CREATOR);
        services = in.createTypedArrayList(Service.CREATOR);
        isAvailableLocally = in.readByte() != 0;
        ipAddress = in.readString();
        port = in.readInt();
        configData = in.readString();
        paramData = in.readString();
        isSelected = in.readByte() != 0;
        primaryUsers = in.createStringArrayList();
        secondaryUsers = in.createStringArrayList();
    }

    public static final Creator<EspNode> CREATOR = new Creator<EspNode>() {
        @Override
        public EspNode createFromParcel(Parcel in) {
            return new EspNode(in);
        }

        @Override
        public EspNode[] newArray(int size) {
            return new EspNode[size];
        }
    };

    @Override
    public int describeContents() {
        return 0;
    }

    @Override
    public void writeToParcel(Parcel dest, int flags) {

        dest.writeString(nodeId);
        dest.writeString(userRole);
        dest.writeString(configVersion);
        dest.writeString(nodeName);
        dest.writeString(fwVersion);
        dest.writeString(nodeType);
        dest.writeByte((byte) (isOnline ? 1 : 0));
        dest.writeLong(timeStampOfStatus);
        dest.writeTypedList(devices);
        dest.writeTypedList(attributes);
        dest.writeTypedList(services);
        dest.writeByte((byte) (isAvailableLocally ? 1 : 0));
        dest.writeString(ipAddress);
        dest.writeInt(port);
        dest.writeString(configData);
        dest.writeString(paramData);
        dest.writeByte((byte) (isSelected ? 1 : 0));
        dest.writeStringList(primaryUsers);
        dest.writeStringList(secondaryUsers);
    }
}
