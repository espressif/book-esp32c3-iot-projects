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

package com.espressif.ui.adapters;

import android.content.Context;
import android.content.Intent;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.GridLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.espressif.AppConstants;
import com.espressif.rainmaker.R;
import com.espressif.ui.activities.NodeDetailsActivity;
import com.espressif.ui.models.EspNode;

import java.util.ArrayList;

public class NodeAdapter extends RecyclerView.Adapter<NodeAdapter.NodeViewHolder> {

    private Context context;
    private ArrayList<EspNode> nodedList;

    public NodeAdapter(Context context, ArrayList<EspNode> deviceList) {
        this.context = context;
        this.nodedList = deviceList;
    }

    @Override
    public NodeViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {

        LayoutInflater layoutInflater = LayoutInflater.from(context);
        View v = layoutInflater.inflate(R.layout.item_node, parent, false);
        NodeViewHolder vh = new NodeViewHolder(v);
        return vh;
    }

    @Override
    public void onBindViewHolder(@NonNull final NodeViewHolder myViewHolder, final int position) {

        final EspNode node = nodedList.get(position);
        myViewHolder.tvDeviceName.setText(node.getNodeName());

        GridLayoutManager linearLayoutManager = new GridLayoutManager(context, 2);
        myViewHolder.rvDevices.setLayoutManager(linearLayoutManager);
        EspDeviceAdapter adapter = new EspDeviceAdapter(context, node.getDevices());
        myViewHolder.rvDevices.setAdapter(adapter);

        myViewHolder.itemView.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                Intent intent = new Intent(context, NodeDetailsActivity.class);
                intent.putExtra(AppConstants.KEY_NODE_ID, node.getNodeId());
                context.startActivity(intent);
            }
        });

        myViewHolder.ivNodeInfo.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Intent intent = new Intent(context, NodeDetailsActivity.class);
                intent.putExtra(AppConstants.KEY_NODE_ID, node.getNodeId());
                context.startActivity(intent);
            }
        });
    }

    @Override
    public int getItemCount() {
        return nodedList.size();
    }

    public void updateList(ArrayList<EspNode> updatedNodeList) {
        nodedList = updatedNodeList;
        notifyDataSetChanged();
    }

    static class NodeViewHolder extends RecyclerView.ViewHolder {

        TextView tvDeviceName;
        ImageView ivDevice;
        RecyclerView rvDevices;
        ImageView ivNodeInfo;

        public NodeViewHolder(View itemView) {
            super(itemView);

            tvDeviceName = itemView.findViewById(R.id.tv_node_name);
            ivDevice = itemView.findViewById(R.id.iv_device);
            rvDevices = itemView.findViewById(R.id.rv_device_list);
            ivNodeInfo = itemView.findViewById(R.id.btn_info);
        }
    }
}
