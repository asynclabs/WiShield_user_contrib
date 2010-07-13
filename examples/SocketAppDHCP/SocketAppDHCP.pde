/*
 * Socket App
 *
 * A simple socket application / DHCP example sketch for the WiShield
 * Sample python server script for this sketch to connect with at bottom of sketch
 *
 */
 
// Requires APP_SOCKAPP, APP_UDPAPP and UIP_DHCP to be defined in apps-conf.h
//  APP_SOCKAPP  - for the TCP sockets components of the sketch
//  APP_UDPAPP   - for the UDP/DNS components of the sketch
//  UIP_DHCP     - for the DHCP components of the sketch

#include <WiShield.h>
extern "C" {
   #include "uip.h"
}

// Wireless configuration parameters ----------------------------------------
unsigned char local_ip[]     = {192,168,1,2};   // IP address of WiShield
unsigned char gateway_ip[]   = {192,168,1,1};   // router or gateway IP address
unsigned char subnet_mask[]  = {255,255,255,0}; // subnet mask for the local network
char ssid[]                  = {"ASYNCLABS"};   // max 32 bytes
unsigned char security_type  = 0;               // 0 - open; 1 - WEP; 2 - WPA; 3 - WPA2
unsigned char  wireless_mode = 1;               // 1==Infrastructure, 2==Ad-hoc
unsigned char ssid_len;
unsigned char security_passphrase_len;

// WPA/WPA2 passphrase
const prog_char security_passphrase[] PROGMEM = {"12345678"};	// max 64 characters

// WEP 128-bit keys
prog_uchar wep_keys[] PROGMEM = { 
   0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, // Key 0
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // Key 1
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // Key 2
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00  // Key 3
};
// End of wireless configuration parameters ----------------------------------------


// global data
boolean connectAndSendTCP = false;
uip_ipaddr_t srvaddr;

void setup()
{
   // Enable Serial output
   Serial.begin(57600);

   WiFi.init();
   
   Serial.println("Start the DHCP query...");
   uip_dhcp_request();
}

void loop()
{
   if(true == connectAndSendTCP) {
      connectAndSendTCP = false;
      // Address of server to connect to
      uip_ipaddr(&srvaddr, 192,168,1,100);
      uip_connect(&srvaddr, HTONS(3333));
   }
   
   WiFi.run();
}

extern "C" {
   // Process UDP UIP_APPCALL events
   void udpapp_appcall(void)
   {
      uip_dhcp_run();
   }

   // DHCP query complete callback
   void uip_dhcp_callback(const struct dhcp_state *s)
   {
      if(NULL != s) {
         // Set the received IP addr data into the uIP stack
         uip_sethostaddr(s->ipaddr);
         uip_setdraddr(s->default_router);
         uip_setnetmask(s->netmask);
         
         // Print the received data - its quick and dirty but informative
         Serial.print("DHCP IP     : "); 
         Serial.print(uip_ipaddr1(s->ipaddr), DEC);
         Serial.print(".");
         Serial.print(uip_ipaddr2(s->ipaddr), DEC);
         Serial.print(".");
         Serial.print(uip_ipaddr3(s->ipaddr), DEC);
         Serial.print(".");
         Serial.println(uip_ipaddr4(s->ipaddr), DEC);
         
         Serial.print("DHCP GATEWAY: "); 
         Serial.print(uip_ipaddr1(s->default_router), DEC);
         Serial.print(".");
         Serial.print(uip_ipaddr2(s->default_router), DEC);
         Serial.print(".");
         Serial.print(uip_ipaddr3(s->default_router), DEC);
         Serial.print(".");
         Serial.println(uip_ipaddr4(s->default_router), DEC);
         
         Serial.print("DHCP NETMASK: "); 
         Serial.print(uip_ipaddr1(s->netmask), DEC);
         Serial.print(".");
         Serial.print(uip_ipaddr2(s->netmask), DEC);
         Serial.print(".");
         Serial.print(uip_ipaddr3(s->netmask), DEC);
         Serial.print(".");
         Serial.println(uip_ipaddr4(s->netmask), DEC);
              
         Serial.print("DHCP DNS    : "); 
         Serial.print(uip_ipaddr1(s->dnsaddr), DEC);
         Serial.print(".");
         Serial.print(uip_ipaddr2(s->dnsaddr), DEC);
         Serial.print(".");
         Serial.print(uip_ipaddr3(s->dnsaddr), DEC);
         Serial.print(".");
         Serial.println(uip_ipaddr4(s->dnsaddr), DEC);
      }
      else {
         Serial.println("DHCP NULL FALLBACK");
      }
      
      // Shut down DHCP
      uip_dhcp_shutdown();
      
      connectAndSendTCP = true;
   }


   char packet[] = "SocketAppDHCP";

   void socket_app_appcall(void)
   {
      if(uip_closed() || uip_timedout()) {
         Serial.println("SA: closed / timedout");
         uip_close();
         return;
      }
      if(uip_poll()) {
         Serial.println("SA: poll");
      }
      if(uip_aborted()) {
         Serial.println("SA: aborted");
      }
      if(uip_connected()) {
         Serial.println("SA: connected / send");
         uip_send(packet, strlen(packet));
      }
      if(uip_acked()) {
         Serial.println("SA: acked");
         uip_close();
      }
      if(uip_newdata()) {
         Serial.println("SA: newdata");
      }
      if(uip_rexmit()) {
         Serial.println("SA: rexmit");
         uip_send(packet, strlen(packet));
      }
   }

   // These uIP callbacks are unused for the purposes of this simple DHCP example
   // but they must exist.   
   void socket_app_init(void)
   {
   }

   void udpapp_init(void)
   {
   }

   void dummy_app_appcall(void)
   {
   }
}

/*

# -- Beginning of python server script

import socket

HOST = ''                 # Symbolic name meaning all available interfaces
PORT = 3333               # Arbitrary non-privileged port
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.bind((HOST, PORT))
s.listen(1)

try:
	while 1:
		conn, addr = s.accept()
		print 'Connected by', addr
		data = conn.recv(1024)
		if not data: 
			continue
		print data
		conn.close()
except:
	conn.close()

# -- End of python script

*/

