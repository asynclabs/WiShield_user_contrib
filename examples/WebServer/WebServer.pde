/*
 * Web Server
 *
 * A simple web server example using the WiShield 1.0
 */

#include <WiShield.h>

// Wireless configuration parameters ----------------------------------------
unsigned char local_ip[]    = {10,0,9,44};   // IP address of WiShield
unsigned char gateway_ip[]  = {10,0,9,1};   // router or gateway IP address
unsigned char subnet_mask[] = {255,255,255,0}; // subnet mask for the local network
char ssid[]                 = {"NintendoDS"};   // max 32 bytes
unsigned char security_type = 0;               // 0 - open; 1 - WEP; 2 - WPA; 3 - WPA2

// WPA/WPA2 passphrase
const char PROGMEM security_passphrase[] PROGMEM = {"Etc1brew!"};	// max 64 characters

// WEP 128-bit keys
const unsigned char PROGMEM wep_keys[] PROGMEM = { 
	0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d,	// Key 0
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,	// Key 1
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,	// Key 2
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	// Key 3
};

// setup the wireless mode; infrastructure - connect to AP; adhoc - connect to another WiFi device
#define WIRELESS_MODE_INFRA	1
#define WIRELESS_MODE_ADHOC	2
unsigned char wireless_mode = WIRELESS_MODE_INFRA;
unsigned char ssid_len;
unsigned char security_passphrase_len;
// End of wireless configuration parameters ----------------------------------------


void setup()
{
	WiFi.init();
}

// This is the webpage that is served up by the webserver
const char PROGMEM webpage[] PROGMEM = {"HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n<center><h1>Hello World!! I am WiShield</h1><form method=\"get\" action=\"0\">Toggle LED:<input type=\"submit\" name=\"0\" value=\"LED1\"></input></form></center>"};

void loop()
{
	WiFi.run();
}
