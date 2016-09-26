141
Name
Help;;help_end;;
ID
Address
This parameter is the Bluetooth address of the device.;;help_end;;
IDC_STATIC_BD_ADDRESS
Class of Device
The Class is the class of device/service field (CoD).
It is indicated using the 'Format Type field' within the CoD.
The value could be 0x040424(HS) or 0x001F00(Uncategorized);;help_end;;
IDC_STATIC_COD
Name Fragment
NameFragment is a local device name. If a remote device requires a local name, a local device replies the local device name;;help_end;;
IDC_STATIC_NAME_FRAGMENT
PIN Code
The App_Fix_PIN_Code  which is four byte ASCII code is a fixed PIN code of a local device.
The local device replies the PIN code using the App_Fix_PIN_Code when remote devices  send a PIN code request command.;;help_end;;
IDC_STATIC_PIN_CODE
UUID
This parameter is the Universally Unique Identifier of the device.;;help_end;;
IDC_STATIC_UUID
Specific Server Channel
Config specific server channel;;help_end;;
IDC_STATIC_SPECIFIC_SERVER_CHANNEL
HCI Baud Rate Index
The HCI Baud Rate Index is the baud rate index of the HCI UART.;;help_end;;
IDC_STATIC_HCI_BAUD_RATE_INDEX
H/W Flow Control (CTS)
Set this parameter to enable UART H/W flow control(CTS).
If MCU not support flow control, this parameter need be set as disable to disable this function.;;help_end;;
IDC_STATIC_CTS_RTS_FLOW_CONTROL
Check Rx Data Interval
Check UART RX Data Interval;;help_end;;
IDC_STATIC_CHECK_RX_DATA_INTERVAL
UART RX_IND
Enable / Disable UART RX IND ;;help_end;;
IDC_STATIC_UART_RX_IND
Segment UART Data
This parameter is used to set the segment of UART Data.;;help_end;;
IDC_STATIC_SEGMENT_UART_DATA
BT Operation Mode
Select the bluetooth single mode or dual mode;;help_end;;
IDC_STATIC_BT_OPERATION_MODE
Sniff Interval
RF Off interval under connected state, if want to save more power, this function be enabled is necessary.
The recommended value is 0x0320.
Example:
Sniff_Interval_Value = 0x0320, RF off interval is 0x0320*625us, when time is up to turn on RF.
if nothing r;;help_end;;
IDC_STATIC_SNIFF_INTERVAL
Enter Sniff Waiting Time
Enter Sniff mode waiting time, time duration start in data transmission finish.;;help_end;;
IDC_STATIC_ENTER_SNIFF_WAITING_TIME
Unsniff When Recieve Data From Host
Enable/Disable To leave sniff mode option when receiving data from host.;;help_end;;
IDC_STATIC_UNSNIFF_WHEN_RECIEVE_DATA_FROM_HOST
Unsniff When Recieve Data From Remote
Enable/Disable To leave sniff mode option when receiving data from remote.;;help_end;;
IDC_STATIC_UNSNIFF_WHEN_RECIEVE_DATA_FROM_REMOTE
QoS Setting
Ask shorter Polling Interval (12.5ms) to get higher throughput or responsed ACK time.;;help_end;;
IDC_STATIC_QOS_SHORT_POLL_INTERVAL
To Be Master
Ask to become the Master after link establish.;;help_end;;
IDC_STATIC_TO_BE_MASTER
Supervision Timeout
Ask to change "Supervision timeout"
It is available while BM77 is role master only.;;help_end;;
IDC_STATIC_SUPERVISION_TIMEOUT
Inquiry Scan Interval Value
The interval of inquiry_scan window reopen.;;help_end;;
IDC_STATIC_INQUIRY_SCAN_INTERVAL_VALUE
Inquiry Timeout Value
This parameter is used to set inquiry timeout value;;help_end;;
IDC_STATIC_INQUIRY_TIMEOUT_VALUE
Page Scan Interval Value
The interval of page_scan window reopen.;;help_end;;
IDC_STATIC_PAGE_SCAN_INTERVAL_VALUE
Page Timeout Value
The page interval for BM77 reconnect to device.;;help_end;;
IDC_STATIC_PAGE_TIMEOUT_VALUE
Pairing Method
Select pairing method;;help_end;;
IDC_STATIC_PAIRING_METHOD
Pass Key Entry Timeout
This parameter is used for Passkey Entry Timeout setting.;;help_end;;
IDC_STATIC_PASS_KEY_ENTRY_TIMEOUT
Bluetooth 3.0 Secure Simple Pairing (SSP)
Enable/Disable simple pairing function.;;help_end;;
IDC_STATIC_SIMPLE_PAIRING
Bluetooth 4.0 BLE Security
This parameter is uesd to set BLE Security.;;help_end;;
IDC_STATIC_BLE_SECURITY
Link Back Device Number
This parameter decides how many devices will be tried to link while it is power on.
It will be stop once the link is connected or link back timing is up.
The maximum is allowed to try 4 different devices.
0x00: disble link back funtion.;;help_end;;
IDC_STATIC_LINK_BACK_DEVICE_NUMBER
Link Loss Reconnection 
Local device shall auto reconnect to last remote device when link loss.;;help_end;;
IDC_STATIC_LINK_LOSS_RECONNECTION
Link Back Visibility
Decide the visibitlty of Bluetooth device under the Link Back Mode.
Disable: The device canot be connected or discovered by other Bluetooth masters.
It will connect the specific Bluetooth addresses listed in the Link Back Table. (Maximum 4 devices)
Connec;;help_end;;
IDC_STATIC_LINK_BACK_VISIBILITY
Link Back BLE Visibility
 Disable/Enable advertising under link back mode;;help_end;;
IDC_STATIC_LINK_BACK_BLE_VISIBILITY
Power On Link Back Times
The maximum times for which the device will retry to connect to a remote device when power-on and loop mode enabled.
0x00:disable link back function.;;help_end;;
IDC_STATIC_LINK_BACK_TIMES
Link Loss Link Back Times
The maximum times for which the device will retry to connect to a remote device when lose link.
0x00: function disabled.;;help_end;;
IDC_STATIC_LINK_LOSS_LINK_BACK_TIMES
Link Back Loop Times
Enter LinkBack mode when standby time is up, and increment the counter afterward.
If counter greater than  "Link_Back_Loop_Setting", device shall enter S2 mode.
0x00 : disable function
0x01~0xfe : enable function and as linkbcak times
0xff :enable functio;;help_end;;
IDC_STATIC_LINK_BACK_LOOP_SETTING
Power On Standby Time
The standby time duration after power on. device shall enter save power mode when time is up.
0x00~0xFE: Standby time parameters.
0xFF: Disable auto power_off function(enter S2 mode);;help_end;;
IDC_STATIC_POWER_ON_STANDBY_TIME
Disconnection Standby Time
The standby time duration after disconnection.
Device shall enter save power mode when time is up.
0x00~0xFE: Standby time parameters.
0xFF: Disable auto power_off function(enter S2 mode);;help_end;;
IDC_STATIC_REMOTE_DISCONNECT_STANDBY_TIME
Discoverable under Standby Mode
Discoverable under standby mode if set this parameter enable.;;help_end;;
IDC_STATIC_DISCOVERABLE_UNDER_ACCESS_STATE
Wakeup Externel MCU Wait Time
Waiting time duration to wake MCU up.;;help_end;;
IDC_STATIC_WAKEUP_EXTERNAL_MCU_WAIT_TIME
Max Uart Data Collection Size
BM57 received the UART data from MCU if data size more then this parameter, the collected data will be sent to remote side.;;help_end;;
IDC_STATIC_UART_DATA_MAX_COLLECTION_SIZE
Allow Into Low Power Mode Only In Standby
Just allow BM77 enter low power mode during Standby.
On the other hand, no need P0_7 for low power control if set as Enable.;;help_end;;
IDC_STATIC_ALLOW_INTO_LOW_POWER_MODE_IN_STANDBY
EEPROM Footprint
The 16 ASCII characters for the customers' version control code. The download tool can check by this code and reject to download the EEPROM if it's mismatch.;;help_end;;
IDC_STATIC_E2PROM_FOOTPRINT
Link Quality Detection
Enable/Disable link quality detection.
The RF_Tx_Power_Control_feature will be disabled if Enable this parameter.;;help_end;;
IDC_STATIC_LINK_QUALITY_DETECTION
RSSI Normal Threshold
This parameter is used to set RSSI normal threshole value;;help_end;;
IDC_STATIC_RSSI_NORMAL_THRESHOLD
RSSI Weak Threshold
This parameter is used to set RSSI weak threshole value;;help_end;;
IDC_STATIC_RSSI_WEAK_THRESHOLD
Battery Detection
Thie parameter is uesd to enable battery detection;;help_end;;
IDC_STATIC_BATTERY_DETECTION
Normal Battery Level
This parameter is defined a normal voltage value of a battery. When the voltage is lower than this value,the device will start low battery warring.;;help_end;;
IDC_STATIC_NORMAL_BATTERY_LEVEL
Low Battery Level
This parameter is defined a low voltage value of a battery. When the voltage is lower than this value, the device will shutdown.;;help_end;;
IDC_STATIC_LOW_BATTERY_LEVEL
Low Battery Into Power Down Time
This parameter is used to set the waiting time befor enter into power down if low battery happens.;;help_end;;
IDC_STATIC_LOW_BATTERY_INTO_POWER_DOWN_TIME
P00
Set the function mapping to the GPIO P0_0;;help_end;;
IDC_STATIC_P00
P05
Set the function mapping to the GPIO P0_5;;help_end;;
IDC_STATIC_P05
P17
Set the function mapping to the GPIO P1_7;;help_end;;
IDC_STATIC_P17
P31
Set the function mapping to the GPIO P3_1;;help_end;;
IDC_STATIC_P31
P32
Set the function mapping to the GPIO P3_2;;help_end;;
IDC_STATIC_P32
P33
Set the function mapping to the GPIO P3_3;;help_end;;
IDC_STATIC_P33
P34
Set the function mapping to the GPIO P3_4;;help_end;;
IDC_STATIC_P34
P37
Set the function mapping to the GPIO P3_7;;help_end;;
IDC_STATIC_P37
LE Connection Parameter Update Request
The LE Connection Setting will be assigned by Remote if select Disable.
It will sent update request if select Enable.;;help_end;;
IDC_STATIC_LE_CONNECTION_PARAMETER_UPDATE
Min LE Connection Interval
This parameter is used to set LE min connection interval;;help_end;;
IDC_STATIC_MIN_LE_CONNECTION_INTERVAL
Max LE Connection Interval
This parameter is used to set LE max connection interval;;help_end;;
IDC_STATIC_MAX_LE_CONNECTION_INTERVAL
LE Slave Latency
This parameter is used to set LE slave latency;;help_end;;
IDC_STATIC_LE_SLAVE_LATENCY
LE Supervision Timeout
This parameter is used to set LE supervision timeout ;;help_end;;
IDC_STATIC_LE_SUPERVISION_TIMEOUT
LE Linkback Times
The maximum times for which the device will retry to connect to a remote device when lose link.;;help_end;;
IDC_STATIC_LE_LINKBACK_TIMES
LE Fast Advertising Interval
This parameter is uesd to set LE fast advertising interval;;help_end;;
IDC_STATIC_LE_FAST_ADVERTISING_INTERVAL
LE Reduced Power Advertising Interval
This parameter is uesd to set LE reduced power advertising interval;;help_end;;
IDC_STATIC_LE_REDUCED_POWER_ADVERTISING
LE Fast Advertising Timeout
This parameter is uesd to set LE fast advertising timeout value;;help_end;;
IDC_STATIC_LE_FAST_ADVERTISING_TIMEOUT
Power On LE Reduced Power Advertising Timeout
This parameter is uesd to show Power On LE Reduced Power Advertising timeout value.
Power On LE Reduced Power Advertising timeout = Power on Standby Time - LE Fast Advertising Timeout.;;help_end;;
IDC_STATIC_POWER_ON_LE_REDUCED_POWER_ADVERTISING_TIMEOUT
Disconnection LE Reduced Power Advertising Timeout
This parameter is uesd to show Disconnection LE Reduced Power Advertising Timeout value.
Disconnection LE Reduced Power Advertising Timeout  = Disconnection Standby Time - LE Fast Advertising Timeout;;help_end;;
IDC_STATIC_DISCONNECTION_LE_REDUCED_POWER_ADVERTISING_TIMEOUT
Connected TX Power Level
This parameter is uesd to set Connected TX Power Level.;;help_end;;
IDC_STATIC_CONNECTED_TX_POWER_LEVEL
Advertising TX Power Level
This parameter is uesd to set Advertising TX Power Level.;;help_end;;
IDC_STATIC_ADVERTISING_TX_POWER_LEVEL
Transparent Service UUID Configuration
This parameter is used to enable the sepcific Transparent Service UUID Setting;;help_end;;
IDC_STATIC_UART_SERVICE_UUID_CONFIGURATION
Transparent Service UUID
This parameter is used to config the sepcific Transparent Service UUID;;help_end;;
IDC_STATIC_UART_SERVICE_UUID
Transparent TX UUID
This parameter is used to config the sepcific Transparent TX UUID;;help_end;;
IDC_STATIC_UART_TX_UUID
Transparent RX UUID
This parameter is used to config the sepcific Transparent RX UUID;;help_end;;
IDC_STATIC_UART_RX_UUID
Transparent TX Property
This parameter is used to config the property of sepcific TX characteristic;;help_end;;
IDC_STATIC_TRANSPARENT_TX_PROPERTY
Transparent RX Property
This parameter is used to config the property of sepcific RX characteristic;;help_end;;
IDC_STATIC_TRANSPARENT_RX_PROPERTY
Advertising Data Setting
This parameter is uesd to set advertising data.;;help_end;;
IDC_STATIC_ADVERTISING_DATA_SETTING
Scan Response Data Setting
This parameter is uesd to set scan response data;;help_end;;
IDC_STATIC_SCAN_RESPONSE_DATA_SETTING
Model Number
This parameter is uesd to config modle number characteristic of device information service.;;help_end;;
IDC_STATIC_MODEL_NUMBER
Serial Number
This parameter is uesd to config serial number characteristic of device information service.;;help_end;;
IDC_STATIC_SERIAL_NUMBER
Manufacture Name
This parameter is uesd to config manufacture name characteristic of device information service.;;help_end;;
IDC_STATIC_MANUFACTURE_NAME
Software Version
This parameter is uesd to config Software Version characteristic of device information service.;;help_end;;
IDC_STATIC_SOFTWARE_VERSION
SYSTEM ID
The System ID characteristic value;;help_end;;
IDC_STATIC_SYSTEM_ID
EIR Manufacture Data
This parameter is used to configure the Specific Manufacure Data in EIR;;help_end;;
IDC_STATIC_EIR_MANUFACTURE_DATA
Enable MFi Version Mapping to DIS
Enable MFi Firmware version and Hardware version Mapping to DIS.;;help_end;;
IDC_STATIC_ENABLE_MFI_VERSION_MAPPING_TO_DIS
Accessory Firmware Version
Please refer to the \"MFi Accessory Firmware specification\".;;help_end;;
IDC_STATIC_ACCESSORY_FIRMWARE_VERSION
Accessory Hardware Version
Please refer to the \"MFi Accessory Firmware specification\".;;help_end;;
IDC_STATIC_ACCESSORY_HARDWARE_VERSION
DIS UUID 1 Configulation
This parameter is used to enable/disable sepcific DIS UUID 1;;help_end;;
IDC_STATIC_DIS_UUID_1_CONFIGULATION
DIS UUID 1
This parameter is used to config sepcific DIS UUID 1;;help_end;;
IDC_STATIC_DIS_UUID_1
DIS UUID 1 Value
This parameter is used to config the value of sepcific DIS UUID 1;;help_end;;
IDC_STATIC_DIS_UUID_1_VALUE
DIS UUID 2 Configulation
This parameter is used to enable/disable sepcific DIS UUID 2;;help_end;;
IDC_STATIC_DIS_UUID_2_CONFIGULATION
DIS UUID 2
This parameter is used to config sepcific DIS UUID 2;;help_end;;
IDC_STATIC_DIS_UUID_2
DIS UUID 2 Value
This parameter is used to config the value of sepcific DIS UUID 2;;help_end;;
IDC_STATIC_DIS_UUID_2_VALUE
Regulatory Certification Data List Count
Defines the regulatory certification data list count;;help_end;;
IDC_STATIC_REGULATORY_CERTIFICATION_DATA_LIST_COUNT
Regulatory Certification Data List Length
Defines the regulatory certification data list length;;help_end;;
IDC_STATIC_REGULATORY_CERTIFICATION_DATA_LIST_LENGTH
Authorization Body
Code assigned by IEEE 11073-20601 identifying the authorizing the authorizing body;;help_end;;
IDC_STATIC_AUTHORIZATION_BODY
Authorization Body Structure Type
Identifies the data structure;;help_end;;
IDC_STATIC_AUTHORIZATION_BODY_STRUCT_TYPE
Authorization Body Data
Format defined by Authorizing Bode (Continua);;help_end;;
IDC_STATIC_AUTHORIZATION_BODY_DATA
Authorization Body
Code assigned by IEEE 11073-20601 identifying the authorizing the authorizing body;;help_end;;
IDC_STATIC_AUTHORIZATION_BODY
Authorization Body Structure Type
Identifies the data structure;;help_end;;
IDC_STATIC_AUTHORIZATION_BODY_STRUCT_TYPE
Authorization Body Data
Format defined by Authorizing Bode (Continua);;help_end;;
IDC_STATIC_AUTHORIZATION_BODY_DATA
Authorization Body
Code assigned by IEEE 11073-20601 identifying the authorizing the authorizing body;;help_end;;
IDC_STATIC_AUTHORIZATION_BODY
Authorization Body Structure Type
Identifies the data structure;;help_end;;
IDC_STATIC_AUTHORIZATION_BODY_STRUCT_TYPE
Authorization Body Data
Format defined by Authorizing Bode (Continua);;help_end;;
IDC_STATIC_AUTHORIZATION_BODY_DATA
Type
This is the LED display method.;;help_end;;
IDC_STATIC_LED_TYPE
On Duration
This the LED on time for flash.;;help_end;;
IDC_STATIC_LED_ON_TIME
Off Duration
This the LED off time for flash.;;help_end;;
IDC_STATIC_LED_OFF_TIME
Count
This is the number of the flash times for a round.;;help_end;;
IDC_STATIC_LED_COUNT
Interval
This is the time interval for a round.;;help_end;;
IDC_STATIC_LED_INTERVAL
Type
This is the LED display method.;;help_end;;
IDC_STATIC_LED_TYPE
On Duration
This the LED on time for flash.;;help_end;;
IDC_STATIC_LED_ON_TIME
Off Duration
This the LED off time for flash.;;help_end;;
IDC_STATIC_LED_OFF_TIME
Count
This is the number of the flash times for a round.;;help_end;;
IDC_STATIC_LED_COUNT
Interval
This is the time interval for a round.;;help_end;;
IDC_STATIC_LED_INTERVAL
Type
This is the LED display method.;;help_end;;
IDC_STATIC_LED_TYPE
On Duration
This the LED on time for flash.;;help_end;;
IDC_STATIC_LED_ON_TIME
Off Duration
This the LED off time for flash.;;help_end;;
IDC_STATIC_LED_OFF_TIME
Count
This is the number of the flash times for a round.;;help_end;;
IDC_STATIC_LED_COUNT
Interval
This is the time interval for a round.;;help_end;;
IDC_STATIC_LED_INTERVAL
Type
This is the LED display method.;;help_end;;
IDC_STATIC_LED_TYPE
On Duration
This the LED on time for flash.;;help_end;;
IDC_STATIC_LED_ON_TIME
Off Duration
This the LED off time for flash.;;help_end;;
IDC_STATIC_LED_OFF_TIME
Count
This is the number of the flash times for a round.;;help_end;;
IDC_STATIC_LED_COUNT
Interval
This is the time interval for a round.;;help_end;;
IDC_STATIC_LED_INTERVAL
Type
This is the LED display method.;;help_end;;
IDC_STATIC_LED_TYPE
On Duration
This the LED on time for flash.;;help_end;;
IDC_STATIC_LED_ON_TIME
Off Duration
This the LED off time for flash.;;help_end;;
IDC_STATIC_LED_OFF_TIME
Count
This is the number of the flash times for a round.;;help_end;;
IDC_STATIC_LED_COUNT
Interval
This parameter is uesd to set LED warning time interval if low battery happens;;help_end;;
IDC_STATIC_LOW_BATTERY_LED_INTERVAL
Type
This is the LED display method.;;help_end;;
IDC_STATIC_LED_TYPE
On Duration
This the LED on time for flash.;;help_end;;
IDC_STATIC_LED_ON_TIME
Off Duration
This the LED off time for flash.;;help_end;;
IDC_STATIC_LED_OFF_TIME
Count
This is the number of the flash times for a round.;;help_end;;
IDC_STATIC_LED_COUNT
Interval
This is the time interval for a round.;;help_end;;
IDC_STATIC_LED_INTERVAL
LED Brightness
LED brightness setting.;;help_end;;
IDC_STATIC_LED1_BRIGHTNESS
Service Name Fragment
Local SDP service name.;;help_end;;
IDC_STATIC_SERVICE_NAME_FRAGMENT
Service Name Length
Local SDP service name length.;;help_end;;
IDC_STATIC_SERVICE_NAME_LENGTH
Vendor ID
This is intended to uniquely identify the vendor of the device.;;help_end;;
IDC_STATIC_VENDOR_ID
Product ID
This is intended to distinguish between different products made by the vendor.;;help_end;;
IDC_STATIC_PRODUCT_ID
Product Version
This is intended to differentiate between versions of products with identical VendorIDs and ProductIDs;;help_end;;
IDC_STATIC_PRODUCT_VERSION
VID Source
This attribute designates which organization assigned the VendorID.;;help_end;;
IDC_STATIC_VID_SOURCE
