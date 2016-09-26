package com.jesstech.bluetoothspp;

import android.app.AlertDialog;
import android.content.Context;
import android.content.DialogInterface;

public class Public {
	public static boolean b_hex;         //16进制模式？
	public static boolean b_loopback;    //Loopback模式?
	public static boolean b_secure;      //secure
	public static boolean b_fix_channel; //fix_channel
	
	public static String PREFS_NAME = "BluetoothChatSetting";
	public static String SETTING_SEND_MODE      = "SETTING_SEND_MODE";
	public static String SETTING_LOOPBACK       = "SETTING_LOOPBACK";
	public static String SETTING_SECURE_CONNECT = "SETTING_SECURE_CONNECT";
	public static String SETTING_FIX_CHANNEL    = "SETTING_FIX_CHANNEL";
	
	//////////////////////////
    public static void ShowAlert(String title, String msg, Context context) {
	    new AlertDialog.Builder(context)
	    .setIcon(android.R.drawable.ic_dialog_alert)
	    .setTitle(title)
	    .setMessage(msg)
	    .setCancelable(false)
	    .setNegativeButton("OK", new DialogInterface.OnClickListener() {
            public void onClick(DialogInterface dialog, int id) {
                dialog.cancel();
            }
        })
	    .show();
    }
    
    public static void ShowInfo(String title, String msg, Context context) {
	    new AlertDialog.Builder(context)
	    .setIcon(android.R.drawable.ic_dialog_info)
	    .setTitle(title)
	    .setMessage(msg)
	    .setCancelable(false)
	    .setNegativeButton("OK", new DialogInterface.OnClickListener() {
            public void onClick(DialogInterface dialog, int id) {
                dialog.cancel();
            }
        })
	    .show();
    }
    
    public static boolean is_hex_char(String str) {
    	for (int i=0; i<str.length(); i++) {
    		char c = str.charAt(i);
    		
    		if (!((c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F'))) {
    			return false;
    		}
    	}
    	return true;
    }
    
}
