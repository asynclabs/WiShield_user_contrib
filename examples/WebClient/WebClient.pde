/*
 * Web Client
 *
 * A simple web client example using the WiShield 1.0
 */

#include <WiShield.h>

// Wireless configuration parameters ----------------------------------------
unsigned char local_ip[]    = {192,168,1,2};   // IP address of WiShield
unsigned char gateway_ip[]  = {192,168,1,1};   // router or gateway IP address
unsigned char subnet_mask[] = {255,255,255,0}; // subnet mask for the local network
char ssid[]                 = {"ASYNCLABS"};   // max 32 bytes

unsigned char security_type = 0;	// 0 - open; 1 - WEP; 2 - WPA; 3 - WPA2; 4 - WPA Precalc; 5 - WPA2 Precalc

// Depending on your security_type, uncomment the appropriate type of security_data
// 0 - None (open)
const prog_char security_data[] PROGMEM = {};

// 1 - WEP 
// UIP_WEP_KEY_LEN. 5 bytes for 64-bit key, 13 bytes for 128-bit key
// Only supply the appropriate key, do not specify 4 keys and then try to specify which to use
//const prog_char security_data[] PROGMEM = { 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, };

// 2, 3 - WPA/WPA2 Passphrase
// 8 to 63 characters which will be used to generate the 32 byte calculated key
// Expect the g2100 to take 30 seconds to calculate the key from a passphrase
//const prog_char security_data[] PROGMEM = {"12345678"};

// 4, 5 - WPA/WPA2 Precalc
// The 32 byte precalculate WPA/WPA2 key. This can be calculated in advance to save boot time
// http://jorisvr.nl/wpapsk.html
//const prog_char security_data[] PROGMEM = {
//    0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f, 
//    0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1f, 0x1f,
//};

// setup the wireless mode
// WIRELESS_MODE_INFRA - connect to AP
// WIRELESS_MODE_ADHOC - connect to another WiFi device
unsigned char wireless_mode = WIRELESS_MODE_INFRA;
// End of wireless configuration parameters ----------------------------------------


void setup()
{
	WiFi.init();
}

unsigned char loop_cnt = 0;

// The stack does not have support for DNS and therefore cannot resolve
// host names. It needs actual IP addresses of the servers. This info
// can be obtained by executing, for example, $ ping twitter.com on
// a terminal on your PC
//char google_ip[] = {74,125,67,100};	// Google
char twitter_ip[] = {128,121,146,100};	// Twitter

// This string can be used to send a request to Twitter.com to update your status
// It will need a valid Authorization string which can be derived from your
// Twitter.com username and password using Base64 algorithm
// See, http://en.wikipedia.org/wiki/Basic_access_authentication
// You need to replace <-!!-Authorization String-!!-> with a valid string before
// using this sample sketch.
// The Content-Length variable should equal the length of the data string
// In the example below, "Content-Length: 21" corresponds to "status=Ready to sleep"
const prog_char twitter[] PROGMEM = {"POST /statuses/update.xml HTTP/1.1\r\nAuthorization: Basic <-!!-Authorization String-!!->\r\nUser-Agent: uIP/1.0\r\nHost: twitter.com\r\nContent-Length: 21\r\nContent-Type: application/x-www-form-urlencoded\r\n\r\nstatus=Ready to sleep"};

void loop()
{
	// if this is the first iteration
	// send the request
	if (loop_cnt == 0) {
		webclient_get(twitter_ip, 80, "/");
		loop_cnt = 1;
	}
	
	WiFi.run();
}
