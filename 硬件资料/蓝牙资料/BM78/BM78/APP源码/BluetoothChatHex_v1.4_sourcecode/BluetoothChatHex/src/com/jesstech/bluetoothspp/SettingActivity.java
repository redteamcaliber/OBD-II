/*
 * Copyright (C) 2009 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.jesstech.bluetoothspp;

import com.jesstech.bluetoothspp.R;

import android.app.Activity;
import android.app.Dialog;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.Window;
import android.widget.Button;
import android.widget.CheckBox;
import android.widget.CompoundButton;
import android.widget.CompoundButton.OnCheckedChangeListener;
import android.widget.RadioButton;

/**
 * This Activity appears as a dialog. It lists any paired devices and
 * devices detected in the area after discovery. When a device is chosen
 * by the user, the MAC address of the device is sent back to the parent
 * Activity in the result Intent.
 */
public class SettingActivity extends Activity {
	public RadioButton radio_ascii;
	public RadioButton radio_hex;
	public CheckBox chk_loopback;
	public CheckBox chk_secure;
	public CheckBox chk_fix_channel;
	public boolean hex = false;
	
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        requestWindowFeature(Window.FEATURE_NO_TITLE);
        setContentView(R.layout.setting);
        
        radio_ascii = (RadioButton)findViewById(R.id.radio_mode_ascii);
        radio_hex = (RadioButton)findViewById(R.id.radio_mode_hex);
        chk_loopback = (CheckBox)findViewById(R.id.checkbox_loopback);
        chk_secure = (CheckBox)findViewById(R.id.checkbox_secure_connect);
        chk_fix_channel = (CheckBox)findViewById(R.id.checkbox_fix_channel);
        
        radio_ascii.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				hex = false;
				radio_hex.setChecked(false);
			}
        });
        
        radio_hex.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				hex = true;
				radio_ascii.setChecked(false);
			}
        });
        
        chk_loopback.setOnCheckedChangeListener(new OnCheckedChangeListener() {
			@Override
			public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
			}
        });
        
        chk_secure.setOnCheckedChangeListener(new OnCheckedChangeListener() {
			@Override
			public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
				chk_fix_channel.setEnabled(!isChecked);
			}
        });
        
        Button btn_save = (Button) findViewById(R.id.button_close);
        btn_save.setOnClickListener(new OnClickListener() {
            public void onClick(View v) {
                SharedPreferences settings = getSharedPreferences(Public.PREFS_NAME, 0);
                SharedPreferences.Editor editor = settings.edit();
                editor.putBoolean(Public.SETTING_SEND_MODE, hex);
                editor.putBoolean(Public.SETTING_LOOPBACK, chk_loopback.isChecked());
                editor.putBoolean(Public.SETTING_SECURE_CONNECT, chk_secure.isChecked());
                editor.putBoolean(Public.SETTING_FIX_CHANNEL, chk_fix_channel.isChecked());
            	editor.commit();
            	Public.b_hex = hex;
            	Public.b_loopback = chk_loopback.isChecked();
            	Public.b_secure = chk_secure.isChecked();
            	Public.b_fix_channel = chk_fix_channel.isChecked();
                finish();
            }
        });
    }
    
    @Override
	protected void onResume() {
		super.onResume();
        SharedPreferences settings = getSharedPreferences(Public.PREFS_NAME, 0);
        hex = settings.getBoolean(Public.SETTING_SEND_MODE, true);
    	chk_loopback.setChecked(settings.getBoolean(Public.SETTING_LOOPBACK, false));
    	chk_secure.setChecked(settings.getBoolean(Public.SETTING_SECURE_CONNECT, false));
    	chk_fix_channel.setChecked(settings.getBoolean(Public.SETTING_FIX_CHANNEL, false));
        
        radio_ascii.setChecked(!hex);
        radio_hex.setChecked(hex);
        chk_fix_channel.setEnabled(!chk_secure.isChecked());
	}
    
	@Override
    protected void onDestroy() {
        super.onDestroy();
    }
    
	
}
