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

import androidx.annotation.NonNull;
import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentManager;
import androidx.fragment.app.FragmentPagerAdapter;

import com.espressif.rainmaker.R;
import com.espressif.ui.fragments.DevicesFragment;
import com.espressif.ui.fragments.ScenesFragment;
import com.espressif.ui.fragments.SchedulesFragment;
import com.espressif.ui.fragments.UserProfileFragment;

import java.util.ArrayList;

public class HomeScreenPagerAdapter extends FragmentPagerAdapter {

    private Context context;
    private ArrayList<Fragment> fragmentList = new ArrayList<>();

    public HomeScreenPagerAdapter(FragmentManager manager, Context context) {
        super(manager);
        this.context = context;
    }

    @NonNull
    @Override
    public Fragment getItem(int position) {
        return fragmentList.get(position);
    }

    @Override
    public CharSequence getPageTitle(int position) {

        Fragment page = fragmentList.get(position);

        if (page instanceof DevicesFragment) {
            return context.getString(R.string.devices_title);
        } else if (page instanceof SchedulesFragment) {
            return context.getString(R.string.title_activity_schedules);
        } else if (page instanceof ScenesFragment) {
            return context.getString(R.string.title_activity_scenes);
        } else if (page instanceof UserProfileFragment) {
            return context.getString(R.string.tab_settings);
        }
        return "";
    }

    @Override
    public int getCount() {
        return fragmentList.size();
    }

    public int getItemPosition(String title) {

        for (int i = 0; i < fragmentList.size(); i++) {
            Fragment page = fragmentList.get(i);

            if (title.equals(context.getString(R.string.devices_title))
                    && page instanceof DevicesFragment) {
                return i;
            } else if (title.equals(context.getString(R.string.title_activity_schedules))
                    && page instanceof SchedulesFragment) {
                return i;
            } else if (title.equals(context.getString(R.string.title_activity_scenes))
                    && page instanceof ScenesFragment) {
                return i;
            } else if (title.equals(context.getString(R.string.tab_settings))
                    && page instanceof UserProfileFragment) {
                return i;
            }
        }
        return 0;
    }

    public void addFragment(Fragment fragment) {
        fragmentList.add(fragment);
    }
}
