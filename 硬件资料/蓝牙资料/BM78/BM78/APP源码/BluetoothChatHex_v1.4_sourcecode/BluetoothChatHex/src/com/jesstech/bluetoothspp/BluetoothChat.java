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
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.os.Handler;
import android.os.Message;
import android.util.Log;
import android.view.KeyEvent;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;
import android.view.View;
import android.view.Window;
import android.view.View.OnClickListener;
import android.view.inputmethod.EditorInfo;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ListView;
import android.widget.TextView;
import android.widget.Toast;

/**
 * This is the main Activity that displays the current chat session.
 */
public class BluetoothChat extends Activity {
    // Debugging
    private static final String TAG = "BluetoothChat";
    private static final boolean D = false;

    // Message types sent from the BluetoothChatService Handler
    public static final int MESSAGE_STATE_CHANGE = 1;
    public static final int MESSAGE_READ = 2;
    public static final int MESSAGE_WRITE = 3;
    public static final int MESSAGE_DEVICE_NAME = 4;
    public static final int MESSAGE_TOAST = 5;

    // Key names received from the BluetoothChatService Handler
    public static final String DEVICE_NAME = "device_name";
    public static final String TOAST = "toast";

    // Intent request codes
    private static final int REQUEST_CONNECT_DEVICE_SECURE = 1;
    private static final int REQUEST_CONNECT_DEVICE_INSECURE = 2;
    private static final int REQUEST_ENABLE_BT = 3;

    // Layout Views
    private TextView mTitle;
    private ListView mConversationView;
    private EditText mOutEditText;
    private Button mSendButton;

    // Name of the connected device
    private String mConnectedDeviceName = null;
    // Array adapter for the conversation thread
    private ArrayAdapter<String> mConversationArrayAdapter;
    // String buffer for outgoing messages
    private StringBuffer mOutStringBuffer;
    // Local Bluetooth adapter
    private BluetoothAdapter mBluetoothAdapter = null;
    // Member object for the chat services
    private BluetoothChatService mChatService = null;
    
    //new
    public int tx_byte;
    public int tx_packet;
    public int rx_byte;
    public int rx_packet;
    
    private TextView lbl_tx_byte;
    private TextView lbl_tx_packet;
    private TextView lbl_rx_byte;
    private TextView lbl_rx_packet;
    private Button   btn_reset;
    
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        if(D) Log.e(TAG, "+++ ON CREATE +++");
        
        // Set up the window layout
        requestWindowFeature(Window.FEATURE_CUSTOM_TITLE);
        setContentView(R.layout.main);
        getWindow().setFeatureInt(Window.FEATURE_CUSTOM_TITLE, R.layout.custom_title);
        
        // Set up the custom title
        mTitle = (TextView) findViewById(R.id.title_left_text);
        mTitle.setText(R.string.app_name);
        mTitle = (TextView) findViewById(R.id.title_right_text);
        
        // Get local Bluetooth adapter
        mBluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
        
        // If the adapter is null, then Bluetooth is not supported
        if (mBluetoothAdapter == null) {
            Toast.makeText(this, "Bluetooth is not available", Toast.LENGTH_LONG).show();
            finish();
            return;
        }
        
        // Initialize the array adapter for the conversation thread
        mConversationArrayAdapter = new ArrayAdapter<String>(this, R.layout.message);
        mConversationView = (ListView) findViewById(R.id.in);
        mConversationView.setAdapter(mConversationArrayAdapter);
        
        // Initialize the compose field with a listener for the return key
        mOutEditText = (EditText) findViewById(R.id.edit_text_out);
        //mOutEditText.setOnEditorActionListener(mWriteListener);
        
        // Initialize the send button with a listener that for click events
        mSendButton = (Button) findViewById(R.id.button_send);
        mSendButton.setOnClickListener(new OnClickListener() {
            public void onClick(View v) {
            	String str = mOutEditText.getText().toString(); 
	    		if (str.length() == 0) {
	    			Public.ShowAlert("Warning", "Please enter data!", BluetoothChat.this);
	    			return;
	    		}
	    		
	    		if (Public.b_hex) {
	    			int idx = 0;
	    			int count = str.length() / 3;
	    			if (str.length() % 3 != 0) {
	    				count++;
	    			}
	    			byte[] buf = new byte[count];
	    			
	    			for (int i=0; i<str.length(); i+=3) {
	    				int end = i+2;
	    				if (end > str.length()) {
	    					end = str.length();
	    				}
	    				String s = str.substring(i, end);
	    				if (!Public.is_hex_char(s)) {
	    					Public.ShowAlert("Error", "Wrong data format!\n\nCorrect format:\n30 39 9D AA FF\n30,39,9D,AA,FF", BluetoothChat.this);
	    					return;
	    				}
	    				if (idx >= count) {
	    					break;
	    				}
	    				buf[idx++] = (byte)Integer.parseInt(s, 16);
	    			}
	    			sendBinary(buf);
	    		} else {
		    		byte[] buf = new byte[str.length()];
		    		buf = str.getBytes();
		    		sendBinary(buf);
	    		}
            }
        });
        
        // Initialize the buffer for outgoing messages
        mOutStringBuffer = new StringBuffer("");
        
        //new
        lbl_tx_byte = (TextView)findViewById(R.id.lbl_tx_byte);
        lbl_tx_packet = (TextView)findViewById(R.id.lbl_tx_packet);
        lbl_rx_byte = (TextView)findViewById(R.id.lbl_rx_byte);
        lbl_rx_packet = (TextView)findViewById(R.id.lbl_rx_packet);
        btn_reset = (Button)findViewById(R.id.btn_reset);
        
        btn_reset.setOnClickListener(new OnClickListener() {
			@Override
			public void onClick(View v) {
				reset();
			}
        });
        reset();
        
        SharedPreferences settings = getSharedPreferences(Public.PREFS_NAME, 0);
		Public.b_hex = settings.getBoolean(Public.SETTING_SEND_MODE, true);
		Public.b_loopback = settings.getBoolean(Public.SETTING_LOOPBACK, false);
		Public.b_secure = settings.getBoolean(Public.SETTING_SECURE_CONNECT, false);
		Public.b_fix_channel = settings.getBoolean(Public.SETTING_FIX_CHANNEL, false);
    }
    
    @Override
    public void onStart() {
        super.onStart();
        if(D) Log.e(TAG, "++ ON START ++");

        // If BT is not on, request that it be enabled.
        // setupChat() will then be called during onActivityResult
        if (!mBluetoothAdapter.isEnabled()) {
        	
        	final boolean b_auto = true; //是否自动打开
        	
        	//提示用户打开----------------------
        	if (!b_auto) {
	            Intent enableIntent = new Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE);
	            startActivityForResult(enableIntent, REQUEST_ENABLE_BT);
        	}
        	
        	//自动打开，无需用户确认--------------
        	else {
	        	mBluetoothAdapter.enable();
	        	
	        	//wait
	        	while (!mBluetoothAdapter.isEnabled()) {
	        		try {
						Thread.sleep(100);
					} catch (InterruptedException e) {
						e.printStackTrace();
					}
	        	}
	        	
	        	setupChat();
        	}
        } else {
            if (mChatService == null) setupChat();
        }
    }
    
    public void reset() {
    	tx_byte = 0;
        tx_packet = 0;
        rx_byte = 0;
        rx_packet = 0;
        display();
    }
    
    public void display() {
        lbl_tx_byte.setText(String.format(getString(R.string.tx_bytes), tx_byte));
        lbl_tx_packet.setText(String.format(getString(R.string.tx_packets), tx_packet));
        lbl_rx_byte.setText(String.format(getString(R.string.rx_bytes), rx_byte));
        lbl_rx_packet.setText(String.format(getString(R.string.rx_packets), rx_packet));
    }
    
    @Override
    public synchronized void onResume() {
        super.onResume();
        if(D) Log.e(TAG, "+ ON RESUME +");
        
        // Performing this check in onResume() covers the case in which BT was
        // not enabled during onStart(), so we were paused to enable it...
        // onResume() will be called when ACTION_REQUEST_ENABLE activity returns.
        if (mChatService != null) {
            // Only if the state is STATE_NONE, do we know that we haven't started already
            if (mChatService.getState() == BluetoothChatService.STATE_NONE) {
            	// Start the Bluetooth chat services
            	mChatService.start();
            }
        }
        
        if (Public.b_hex) {
        	mSendButton.setText(getString(R.string.send_hex));
        } else {
        	mSendButton.setText(getString(R.string.send_ascii));
        }
    }
    
    private void setupChat() {
        Log.d(TAG, "setupChat()");
        
        // Initialize the BluetoothChatService to perform bluetooth connections
        mChatService = new BluetoothChatService(this, mHandler);
    }
    
    @Override
    public synchronized void onPause() {
        super.onPause();
        if(D) Log.e(TAG, "- ON PAUSE -");
    }

    @Override
    public void onStop() {
        super.onStop();
        if(D) Log.e(TAG, "-- ON STOP --");
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        // Stop the Bluetooth chat services
        if (mChatService != null) mChatService.stop();
        if(D) Log.e(TAG, "--- ON DESTROY ---");
    }

    private void ensureDiscoverable() {
        if(D) Log.d(TAG, "ensure discoverable");
        if (mBluetoothAdapter.getScanMode() !=
            BluetoothAdapter.SCAN_MODE_CONNECTABLE_DISCOVERABLE) {
            Intent discoverableIntent = new Intent(BluetoothAdapter.ACTION_REQUEST_DISCOVERABLE);
            discoverableIntent.putExtra(BluetoothAdapter.EXTRA_DISCOVERABLE_DURATION, 300);
            startActivity(discoverableIntent);
        }
    }

    /**
     * Sends a message.
     * @param message  A string of text to send.
     */
    private void sendMessage(String message) {
        // Check that we're actually connected before trying anything
        if (mChatService.getState() != BluetoothChatService.STATE_CONNECTED) {
            Toast.makeText(this, R.string.not_connected, Toast.LENGTH_SHORT).show();
            return;
        }
        
        // Check that there's actually something to send
        byte[] send = message.getBytes();
        mChatService.write(send);
    }
    
    private void sendBinary(byte[] buf) {
        // Check that we're actually connected before trying anything
        if (mChatService.getState() != BluetoothChatService.STATE_CONNECTED) {
            Toast.makeText(this, R.string.not_connected, Toast.LENGTH_SHORT).show();
            return;
        }
        
        mChatService.write(buf);
    }
    
    // The action listener for the EditText widget, to listen for the return key
    private TextView.OnEditorActionListener mWriteListener =
        new TextView.OnEditorActionListener() {
        public boolean onEditorAction(TextView view, int actionId, KeyEvent event) {
            // If the action is a key-up event on the return key, send the message
            if (actionId == EditorInfo.IME_NULL && event.getAction() == KeyEvent.ACTION_UP) {
                String message = view.getText().toString();
                sendMessage(message);
            }
            if(D) Log.i(TAG, "END onEditorAction");
            return true;
        }
    };
    
    // The Handler that gets information back from the BluetoothChatService
    private final Handler mHandler = new Handler() {
        @Override
        public void handleMessage(Message msg) {
            switch (msg.what) {
            case MESSAGE_STATE_CHANGE:
                if(D) Log.i(TAG, "MESSAGE_STATE_CHANGE: " + msg.arg1);
                switch (msg.arg1) {
                case BluetoothChatService.STATE_CONNECTED:
                    mTitle.setText(R.string.title_connected_to);
                    mTitle.append(mConnectedDeviceName);
                    mConversationArrayAdapter.clear();
                    break;
                case BluetoothChatService.STATE_CONNECTING:
                    mTitle.setText(R.string.title_connecting);
                    break;
                case BluetoothChatService.STATE_LISTEN:
                case BluetoothChatService.STATE_NONE:
                    mTitle.setText(R.string.title_not_connected);
                    break;
                }
                break;
            case MESSAGE_WRITE: {
                byte[] writeBuf = (byte[]) msg.obj;
                int len = msg.arg1;
                
                tx_packet++;
                tx_byte += len;
                display();
                
                if (Public.b_hex) {
                	StringBuilder str = new StringBuilder();
                    str.append("SEND: ");
                	
                    for (int i=0; i<len; i++) {
                    	str.append(String.format("%02X ", writeBuf[i]));
                    }
                    
                    mConversationArrayAdapter.add(str.toString());
                } else {
                    String writeMessage = new String(writeBuf);
                    mConversationArrayAdapter.add("SEND: " + writeMessage);
                }
                
                break;
            }
            case MESSAGE_READ: {
                byte[] readBuf = (byte[]) msg.obj;
            	int len = msg.arg1;
                
            	rx_packet++;
            	rx_byte += len;
            	display();
            	
                if (Public.b_hex) {
                    StringBuilder str = new StringBuilder();
                    str.append(mConnectedDeviceName+": ");
                    
                    for (int i=0; i<len; i++) {
                    	str.append(String.format("%02X ", readBuf[i]));
                    }
                    
                    mConversationArrayAdapter.add(str.toString());
                } else {
                	String readMessage = new String(readBuf, 0, len);
                	mConversationArrayAdapter.add(mConnectedDeviceName+": " + readMessage);
                }
                
                if (Public.b_loopback) {
                	byte[] buf = new byte[len];
                	for (int i=0; i<len; i++) {
                		buf[i] = readBuf[i];
                	}
                	
                	sendBinary(buf);
                }
                
                break;
            }
            case MESSAGE_DEVICE_NAME:
                // save the connected device's name
                mConnectedDeviceName = msg.getData().getString(DEVICE_NAME);
                Toast.makeText(getApplicationContext(), "Connected to "
                               + mConnectedDeviceName, Toast.LENGTH_SHORT).show();
                break;
            case MESSAGE_TOAST:
                Toast.makeText(getApplicationContext(), msg.getData().getString(TOAST),
                               Toast.LENGTH_SHORT).show();
                break;
            }
        }
    };
    
    public void onActivityResult(int requestCode, int resultCode, Intent data) {
        if(D) Log.d(TAG, "onActivityResult " + resultCode);
        switch (requestCode) {
        case REQUEST_CONNECT_DEVICE_SECURE:
            // When DeviceListActivity returns with a device to connect
            if (resultCode == Activity.RESULT_OK) {
                connectDevice(data, true);
            }
            break;
        case REQUEST_CONNECT_DEVICE_INSECURE:
            // When DeviceListActivity returns with a device to connect
            if (resultCode == Activity.RESULT_OK) {
                connectDevice(data, Public.b_secure);
            }
            break;
        case REQUEST_ENABLE_BT:
            // When the request to enable Bluetooth returns
            if (resultCode == Activity.RESULT_OK) {
                // Bluetooth is now enabled, so set up a chat session
                setupChat();
            } else {
                // User did not enable Bluetooth or an error occured
                Log.d(TAG, "BT not enabled");
                Toast.makeText(this, R.string.bt_not_enabled_leaving, Toast.LENGTH_SHORT).show();
                finish();
            }
        }
    }
    
    private void connectDevice(Intent data, boolean secure) {
        // Get the device MAC address
        String address = data.getExtras().getString(DeviceListActivity.EXTRA_DEVICE_ADDRESS);
        // Get the BLuetoothDevice object
        BluetoothDevice device = mBluetoothAdapter.getRemoteDevice(address);
        // Attempt to connect to the device
        mChatService.connect(device, secure);
    }
    
    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        MenuInflater inflater = getMenuInflater();
        inflater.inflate(R.menu.option_menu, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        Intent serverIntent = null;
        switch (item.getItemId()) {
        case R.id.insecure_connect_scan:
            // Launch the DeviceListActivity to see devices and do scan
            serverIntent = new Intent(this, DeviceListActivity.class);
            startActivityForResult(serverIntent, REQUEST_CONNECT_DEVICE_INSECURE);
            return true;
        case R.id.setting:
        	serverIntent = new Intent(this, SettingActivity.class);
            startActivity(serverIntent);
            return true;
        case R.id.clear:
        	mConversationArrayAdapter.clear();
        	mConversationArrayAdapter.notifyDataSetChanged();
        	return true;
        case R.id.reset_count:
        	reset();
        	return true;
        }
        return false;
    }
}
