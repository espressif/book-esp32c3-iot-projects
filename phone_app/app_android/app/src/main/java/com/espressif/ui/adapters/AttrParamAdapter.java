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

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.espressif.rainmaker.R;
import com.espressif.ui.models.Param;

import java.util.ArrayList;

public class AttrParamAdapter extends RecyclerView.Adapter<AttrParamAdapter.MyViewHolder> {

    private final String TAG = AttrParamAdapter.class.getSimpleName();

    private Context context;
    private ArrayList<Param> params;

    public AttrParamAdapter(Context context, String nodeId, String deviceName, ArrayList<Param> deviceList) {
        this.context = context;
        this.params = deviceList;
    }

    @Override
    public MyViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {

        // infalte the item Layout
        LayoutInflater layoutInflater = LayoutInflater.from(context);
        View v = layoutInflater.inflate(R.layout.item_attribute_param, parent, false);
        // set the view's size, margins, padding and layout parameters
        MyViewHolder vh = new MyViewHolder(v); // pass the view to View Holder
        return vh;
    }

    @Override
    public void onBindViewHolder(@NonNull final MyViewHolder myViewHolder, final int position) {

        final Param param = params.get(position);
        myViewHolder.tvAttrName.setText(param.getName());
        myViewHolder.tvAttrValue.setText(param.getLabelValue());
    }

    @Override
    public int getItemCount() {
        return params.size();
    }

    public void updateList(ArrayList<Param> updatedDeviceList) {
        params = updatedDeviceList;
        notifyDataSetChanged();
    }

    public class MyViewHolder extends RecyclerView.ViewHolder {

        // init the item view's
        TextView tvAttrName, tvAttrValue;

        public MyViewHolder(View itemView) {
            super(itemView);

            // get the reference of item view's
            tvAttrName = itemView.findViewById(R.id.tv_attr_name);
            tvAttrValue = itemView.findViewById(R.id.tv_attr_value);
        }
    }
}
