/*
 * Socket App
 *
 * A simple socket application / DNS example for the WiShield
 */
 
// Requires APP_SOCKAPP, APP_UDPAPP and UIP_DNS to be defined in apps-conf.h
//  APP_SOCKAPP  - for the TCP sockets components of the sketch
//  APP_UDPAPP   - for the UDP/DNS components of the sketch
//  UIP_DNS      - for the DNS components of the sketch

#include <WiShield.h>
extern "C" {
   #include "uip.h"
}

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


// The resolved DNS address
uint8 dnsAddr[] = {0,0,0,0};

void setup()
{
   // Enable Serial output
   Serial.begin(57600);

   WiFi.init();
   
   Serial.println("Start the DNS query...");
   uip_dns_conf(dns_ip);
   uip_dns_query("www.asynclabs.com");
}

void loop()
{
   WiFi.run();
}

extern "C" {
   // Process UDP UIP_APPCALL events
   void udpapp_appcall(void)
   {
      if(uip_udp_conn->rport == HTONS(53)) {
         if(uip_poll()) {
            Serial.println("Servicing DNS query: udpapp_appcall() -> uip_dns_run()");
            uip_dns_run();
         }
         if(uip_newdata()) {
            Serial.println("Servicing DNS query: udpapp_appcall() -> uip_dns_newdata()");
            uip_dns_newdata();
         }
      }
   }

   // DNS resolver will call this function for either succesful or failed DNS lookup
   // uip_dns_query() call (above) starts the chain of events leading to this callback
   void uip_dns_callback(char *name, u16_t *ipaddr)
   {
      if(NULL != ipaddr) {
         // TODO: probably a better way to do this...
         dnsAddr[0] = uip_ipaddr1(ipaddr);
         dnsAddr[1] = uip_ipaddr2(ipaddr);
         dnsAddr[2] = uip_ipaddr3(ipaddr);
         dnsAddr[3] = uip_ipaddr4(ipaddr);
         Serial.print("DNS addr received: "); 
         Serial.print(dnsAddr[0], DEC);
         Serial.print(".");
         Serial.print(dnsAddr[1], DEC);
         Serial.print(".");
         Serial.print(dnsAddr[2], DEC);
         Serial.print(".");
         Serial.println(dnsAddr[3], DEC);
      }
      else {
         Serial.println("DNS query failed");
      }
      
       // Shutdown DNS
       uip_dns_shutdown();
   }

   // These uIP callbacks are unused for the purposes of this simple DNS example
   // but they must exist.   
   void socket_app_init(void)
   {
   }

   void socket_app_appcall(void)
   {
   }

   void udpapp_init(void)
   {
   }

   void dummy_app_appcall(void)
   {
   }
}
