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

package com.espressif.ui.models;

import android.os.Parcel;
import android.os.Parcelable;

import java.util.ArrayList;

public class SharingRequest implements Parcelable {

    private String reqId;
    private String reqStatus;
    private String userName;
    private String primaryUserName;
    private long reqTime;
    private ArrayList<String> nodeIds;
    private String metadata;

    public SharingRequest(String id) {
        reqId = id;
    }

    protected SharingRequest(Parcel in) {
        reqId = in.readString();
        reqStatus = in.readString();
        userName = in.readString();
        primaryUserName = in.readString();
        reqTime = in.readLong();
        nodeIds = in.createStringArrayList();
        metadata = in.readString();
    }

    public static final Creator<SharingRequest> CREATOR = new Creator<SharingRequest>() {
        @Override
        public SharingRequest createFromParcel(Parcel in) {
            return new SharingRequest(in);
        }

        @Override
        public SharingRequest[] newArray(int size) {
            return new SharingRequest[size];
        }
    };

    public String getReqId() {
        return reqId;
    }

    public void setReqId(String reqId) {
        this.reqId = reqId;
    }

    public String getReqStatus() {
        return reqStatus;
    }

    public void setReqStatus(String reqStatus) {
        this.reqStatus = reqStatus;
    }

    public String getUserName() {
        return userName;
    }

    public void setUserName(String userName) {
        this.userName = userName;
    }

    public String getPrimaryUserName() {
        return primaryUserName;
    }

    public void setPrimaryUserName(String primaryUserName) {
        this.primaryUserName = primaryUserName;
    }

    public long getReqTime() {
        return reqTime;
    }

    public void setReqTime(long reqTime) {
        this.reqTime = reqTime;
    }

    public ArrayList<String> getNodeIds() {
        return nodeIds;
    }

    public void setNodeIds(ArrayList<String> nodeIds) {
        this.nodeIds = nodeIds;
    }

    public String getMetadata() {
        return metadata;
    }

    public void setMetadata(String metadata) {
        this.metadata = metadata;
    }

    @Override
    public int describeContents() {
        return 0;
    }

    @Override
    public void writeToParcel(Parcel dest, int flags) {
        dest.writeString(reqId);
        dest.writeString(reqStatus);
        dest.writeString(userName);
        dest.writeString(primaryUserName);
        dest.writeLong(reqTime);
        dest.writeStringList(nodeIds);
        dest.writeString(metadata);
    }
}
