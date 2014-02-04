/*
 * A simple sketch that uses WiServer to get the hourly weather data from LAX and prints
 * it via the Serial API
 */
 
// Requires APP_WISERVER, APP_UDPAPP and UIP_DNS to be defined in apps-conf.h
//  APP_WISERVER - for the WiServer components of the sketch
//  APP_UDPAPP   - for the UDP/DNS components of the sketch
//  UIP_DNS      - for the DNS components of the sketch

#include <WiServer.h>
extern "C" {
  #include "uip.h"
}

// Wireless configuration parameters ----------------------------------------
unsigned char local_ip[]    = {192,168,1,2};   // IP address of WiShield
unsigned char gateway_ip[]  = {192,168,1,1};   // router or gateway IP address
unsigned char subnet_mask[] = {255,255,255,0}; // subnet mask for the local network
u16_t dns_ip[]              = {192,168,1,1};   // DNS server addr
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


// Flag to know when the DNS query has completed
boolean dnsCalledBack = false;

// Function that prints data from the server
void printData(char* data, int len) {
  
  // Print the data returned by the server
  // Note that the data is not null-terminated, may be broken up into smaller packets, and 
  // includes the HTTP header. 
  while (len-- > 0) {
    Serial.print(*(data++));
  }
}


// Hardcoded IP Address for www.weather.gov
// If DNS lookup is succesful this address will be set in uip_dns_callback
// Otherwise use hardcoded working value...
// uint8 ip[] = {140,90,113,200};
uint8 ip[] = {71,231,196,153};

// A request that gets the latest METAR weather data for LAX
// GETrequest getWeather(ip, 80, "www.weather.gov", "/data/METAR/KLAX.1.txt");
GETrequest getWeather(ip, 80, "slacklab.org", "/WiShield.html");


void setup() {

  // Enable Serial output
  Serial.begin(57600);
  
  // TODO: going off into space here...   
  // Initialize WiServer (we'll pass NULL for the page serving function since we don't need to serve web pages) 
  WiServer.init(NULL);
  
  // Ask WiServer to generate log messages (optional)
  WiServer.enableVerboseMode(true);

  // Have the processData function called when data is returned by the server
  getWeather.setReturnFunc(printData);

  // Start the DNS query
  uip_dns_conf(dns_ip);
  //uip_dns_query("www.weather.gov");
  uip_dns_query("slacklab.org");
}

// Time (in millis) when the data should be retrieved 
long updateTime = 0;

void loop()
{
  // Check if it's time to get an update
  if (true == dnsCalledBack && millis() >= updateTime) {
    // Shutdown DNS
    uip_dns_shutdown();
    // Call WiServer to fetch a page
    getWeather.submit();    
    // Get another update one hour from now
    updateTime += 1000 * 60 * 60;
  }
  
  // Run WiServer
  WiServer.server_task();
 
  delay(10);
}

extern "C" {

   // Process UDP UIP_APPCALL events
   void udpapp_appcall(void)
   {
      if(uip_poll()) {
         uip_dns_run();
      }
      if(uip_newdata()) {
         uip_dns_newdata();
      }
   }

   // DNS resolver will call this function for either succesful or failed DNS lookup
   // uip_dns_query() call (above) starts the chain of events leading to this callback
   void uip_dns_callback(char *name, u16_t *ipaddr)
   {
      dnsCalledBack = true;
      
      if(NULL != ipaddr) {
         // TODO: probably a better way to do this...
         ip[0] = uip_ipaddr1(ipaddr);
         ip[1] = uip_ipaddr2(ipaddr);
         ip[2] = uip_ipaddr3(ipaddr);
         ip[3] = uip_ipaddr4(ipaddr);
         Serial.print("DNS ADDR RECEIVED: "); 
         Serial.print(ip[0], DEC);
         Serial.print(".");
         Serial.print(ip[1], DEC);
         Serial.print(".");
         Serial.print(ip[2], DEC);
         Serial.print(".");
         Serial.println(ip[3], DEC);
      }
      else {
         Serial.println("DNS NULL - FALLBACK TO DEFAULT IP ADDRESS");
      }
   }

   // Not needed for this example but must exist
   void udpapp_init(void)
   {
   }

   // Not needed for this example but must exist
   void dummy_app_appcall(void)
   {
   }
}

