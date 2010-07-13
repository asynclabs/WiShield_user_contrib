// ----------------------------------------------------------------------------
// -- AsyncLabs WiShield WiFi Scanning Sample
// ----------------------------------------------------------------------------


// Requires APP_SOCKAPP, APP_UDPAPP, UIP_DNS, UIP_DHCP and UIP_SCAN to be defined in apps-conf.h
//  APP_SOCKAPP - for the TCP sockets components of the sketch
//  APP_UDPAPP  - for the UDP/DNS components of the sketch
//  UIP_DNS     - for the DNS components of the sketch
//  UIP_DHCP    - for the DHCP components of the sketch
//  UIP_SCAN    - for the Access Point scanning components of the sketch


// ----------------------------------------------------------------------------
// -- WiFiScan state of affairs notes
// -- 
// -- WiFiScan is a conglomeration of APP_TYPES and UIP features; it is both a 
// --  TCP/socket app and a UPD app (at the same time). It utilizes the new
// --  UIP_DNS, UIP_DHCP and UIP_SCAN features to do some fun stuff.
// -- 
// -- WiFiScan's purpose in life is to do the following...
// --  1. Use UIP_SCAN to scan for access points
// --  2. Parses returned scan data for OPEN APs and returns the OPEN AP with
// --     the strongest RSSI.
// --  3. If suitable OPEN AP is returned connect with it
// --  4. If connection is made use UIP_DHCP to get DHCP addr info from gateway.
// --  5. Set the returned DHCP data into the uIP stack.
// --  6. Use UIP_DNS to lookup the IP address of my server.
// --  7. Phone home to my server with TCP data describing the open AP.
// --     I want to add GPS shield to enable sending lat/lon in the packet
// --  8. Disconnect
// --  9. GOTO 1
// -- 
// -- So its an OPEN AP sniffer that uses the OPEN APs that it finds to send a 
// --  descriptive packet home - the goal being to to provide 'real time' 
// --  location reporting from an Arduino/WiShield/GPS that just sits there 
// --  and does its job unnoticed. I have not looked recently but I believe
// --  Skyhook could be used to geographically locate the open APs as well.
// --
// -- The code is a bloody mess - but it works in a 'labratory setting'.
// --  I'll refactor the code.  Its still an experiment!
// --
// -- If you are going to play with this contact me for a user ID and you can 
// --  post to my server.  I have plans for presenting the data via web interface.
// --
// -- This app is an example of using a TCP app (APP_SOCKAPP) and UDP app (APP_UDPAPP) 
// --  together at the same time. UIP_DNS and UIP_DHCP need the UDP support and 
// --  the phoning home is done with a TCP packet. Most of the work getting this
// --  ready to submit was working out how to get all of the APP_TYPES to build
// --  succesfully with APP_UDPAPP which is required for DHCP/DNS.
// -- 
// -- And credit to spidermonkey04 who discovered the sought after UIP_SCAN
// --  functionality which made this all possible. Thanks!
// --
// ----------------------------------------------------------------------------


//#include <dataflash.h>
#include <WiShield.h>
extern "C" {
  #include "uip.h"
  #include "g2100.h"
}

#define FLASH_SLAVE_SELECT 7
#define WIFI_SLAVE_SELECT  10

//Sketch Phases or state
#define PHASEINIT          0
#define PHASESEARCH        1
#define PHASECONNECT       2
#define PHASEDHCP          3
#define PHASEDNS           4
#define PHASEDNSWAIT       5
#define PHASERUN           6
#define PHASECLEANUP       7

boolean newScanData;
U8 phase;
U8 bestRSSI = 0;
U8 bestIndex = 0;
//unsigned char mfg_id[4];
//unsigned int prevRssi = 0;
U8 tcpRetry;
U8 udpRetry;
U8 userID = 30;
unsigned int cleanupCount;
unsigned long time;
uip_ipaddr_t srvaddr;
tZGScanResult *scanResult;
tZGBssDesc *bssDesc;
char formatBuf[96];


// Wireless configuration parameters ----------------------------------------
//  All values are just a guess as DHCP and DNS will set all of them (hopefully)
//  Network addrs are defaulted to something that should work with an open/unconfigured
//  Linksys AP in case the DHCP and/or DNS queries fail.
unsigned char local_ip[]    = {192,168,1,33};  // IP address of WiShield
unsigned char gateway_ip[]  = {192,168,1,1};   // router or gateway IP address
unsigned char subnet_mask[] = {255,255,255,0}; // subnet mask for the local network
u16_t dns_ip[]              = {0,0,0,0};       // DNS server addr
char ssid[32];                                 // SSID, Max 32 bytes
U8 security_type            = 0;               // 0==open, 1==WEP, 2==WPA, 3==WPA2
U8 wireless_mode            = 1;               // 1==Infrastructure, 2==Ad-hoc
unsigned char ssid_len;
unsigned char security_passphrase_len;

// WPA/WPA2 passphrase
const prog_char security_passphrase[] PROGMEM = {"12345678"};	// max 64 characters

// WEP 128-bit keys
prog_uchar wep_keys[] PROGMEM = { 
   0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d,  // Key 0
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,  // Key 1
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,  // Key 2
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}; // Key 3
// End of wireless configuration parameters ----------------------------------------


void setup()
{
  Serial.begin(57600);
  phase = PHASEINIT;
/*
  pinMode(FLASH_SLAVE_SELECT,OUTPUT);
  digitalWrite(FLASH_SLAVE_SELECT,HIGH); //disable device
  pinMode(WIFI_SLAVE_SELECT,OUTPUT);
  digitalWrite(WIFI_SLAVE_SELECT,HIGH);

  dflash.init(7);
  zg_init();

  Serial.println("Done!");
  time = millis() + 5000;
  attachInterrupt(0, zg_isr, LOW);
  
  //---Print flash device mfg/dev ID
  memset(mfg_id, 0, 4);
  Serial.println("---Flash Mfg/Dev ID Data (should be 1F 26 0)---");
  dflash.read_id(mfg_id);
  Serial.print("  Mfg ID: ");
  Serial.println(mfg_id[0], HEX);
  Serial.print("  Dev ID: ");
  Serial.print(mfg_id[1], HEX);
  Serial.println(mfg_id[2], HEX);
*/
}

void loop()
{
  if(PHASEINIT == phase) {
     Serial.println("PHASEINIT");
     pinMode(WIFI_SLAVE_SELECT, OUTPUT);
     digitalWrite(WIFI_SLAVE_SELECT, HIGH);
     zg_init();
     attachInterrupt(0, zg_isr, LOW);
     time = millis();
     phase = PHASESEARCH;
     newScanData = false;
  }    
  if(PHASESEARCH == phase) {    
     if(millis() >= time) {
      Serial.println("PHASESEARCH");
      time = 10000 + millis(); // Scan every 10 sec
      newScanData = true;
      zg_scan_start();
    }
    if(true == newScanData && 0 != get_scan_cnt()) {
      newScanData = false;
      bestRSSI = 0;
      bestIndex = 0;
      scanResult = zg_scan_results();

      for(U8 k = 0; k < (u8)scanResult->numBssDesc; k++) {
        tZGBssDesc* pDesc = zg_scan_desc(k);
        Serial.print(" ");
        printDesc(pDesc);
       
        if(!(0x10 & pDesc->capInfo[0])) {
          if(bestRSSI < pDesc->rssi /* && 112 < pDesc->rssi */ ) {
            bestRSSI = pDesc->rssi;
            bestIndex = k;
          }
        }
      }  
    
      if(0 != bestRSSI) {
        Serial.print("*");
        tZGBssDesc* pDesc = zg_scan_desc(bestIndex);
        printDesc(pDesc);
        phase = PHASECONNECT;
        memset(ssid, 0, 32);
        memcpy(ssid, pDesc->ssid, pDesc->ssidLen);
        
        sprintf(formatBuf, "%d,%s,%02X,%02X,%02X,%02X,%02X,%02X,%02X,%02X,%2d,%d,47.629844,-122.038783",
          userID,
          ssid,
          pDesc->bssid[0], pDesc->bssid[1], pDesc->bssid[2], pDesc->bssid[3], pDesc->bssid[4], pDesc->bssid[5], 
          pDesc->capInfo[0],
          pDesc->capInfo[1],
          pDesc->channel,
          pDesc->rssi);

        bestRSSI = 0;
        bestIndex = 0;
      }
    }
    
    zg_drv_process();  
  }
  if(PHASECONNECT == phase) {
     Serial.println("PHASECONNECT");
     if(false == WiFi.init(15)) {
        phase = PHASEINIT;
        Serial.println("R1");
     }
     else {
        phase = PHASEDHCP;
        cleanupCount = 0;
        udpRetry = 0;
        //DHCP
        uip_dhcp_request();
     }
  }
  if(PHASEDNS == phase) {
     Serial.println("PHASEDNS");
     cleanupCount = 0;
     udpRetry = 0;
     //set up the DNS resolver
     uip_dns_conf(dns_ip);
     uip_dns_query("slacklab.org");
     phase = PHASEDNSWAIT;
  }
  if(PHASEDNSWAIT == phase || PHASEDNS == phase || PHASEDHCP == phase || PHASERUN == phase || PHASECLEANUP == phase) {
    
    if(PHASECLEANUP == phase && cleanupCount++ > 1000) {
      phase = PHASEINIT;
    }
    
    WiFi.run();
  }
}

void printDesc(void* desc)
{
  int i;
  
  tZGBssDesc* pDesc = (tZGBssDesc*)desc;

  if(0x10 & pDesc->capInfo[0]) {
    Serial.print("E ");
  }
  else {
    Serial.print("O ");
  }

  for(i = 0; i < pDesc->ssidLen; i++){
    Serial.print((unsigned char)pDesc->ssid[i]);
  }
  for(; i < 12; i++){
    Serial.print(" ");
  }
  
  sprintf(formatBuf, " bssid: %02X:%02X:%02X:%02X:%02X:%02X type: %d caps: %02X %02X ch: %2d rssi: %3d",
    pDesc->bssid[0], pDesc->bssid[1], pDesc->bssid[2], pDesc->bssid[3], pDesc->bssid[4], pDesc->bssid[5], 
    pDesc->bssType,
    pDesc->capInfo[0],
    pDesc->capInfo[1],
    pDesc->channel,
    pDesc->rssi,
    ZGSTOHS(pDesc->beaconPeriod));
  Serial.println(formatBuf);

  /*       
  for(i = 0; i < pDesc->numRates ; i++){
    Serial.print(pDesc->basicRateSet[i], DEC);
    Serial.print(",");
  }
  Serial.println("M");
  */
}


extern "C" {
   
   void udpapp_init(void)
   {
   }
   
   void udpapp_appcall(void)
   {
      if(PHASEDHCP == phase) {
         Serial.println("PHASEDHCP");
         uip_dhcp_run();

         if(20 < udpRetry++) {
            Serial.println("DHCP TIMEOUT FALLBACK");
            // Shut down DHCP
            uip_dhcp_shutdown();
            phase = PHASEDNS;
         }
      }

      if(PHASEDNSWAIT == phase) {
         Serial.println("PHASEDNS");
         if(uip_poll()) {
            uip_dns_run();
         }
         if(uip_newdata()) {
            uip_dns_newdata();
         }
         
         if(20 < udpRetry++) {
            Serial.println("DNS TIMEOUT FALLBACK");
            // Shutdown DNS
            uip_dns_shutdown();
            // Send TCP packet
            uip_ipaddr(srvaddr, 71,231,196,153);
            uip_connect(&srvaddr, HTONS(7995));
            tcpRetry = 0;
            phase = PHASERUN;         
            Serial.println("PHASERUN");
          }
      }
   }

   void dummy_app_appcall(void)
   {
   }
   
   /*---------------------------------------------------------------------------*/
   /*
    * The initialization function. We must explicitly call this function
    * from the system initialization code, some time after uip_init() is
    * called.
    */
   void socket_app_init(void)
   {
   }

   /*---------------------------------------------------------------------------*/
   /*
    * In socketapp.h we have defined the UIP_APPCALL macro to
    * socket_app_appcall so that this function is uIP's application
    * function. This function is called whenever an uIP event occurs
    * (e.g. when a new connection is established, new data arrives, sent
    * data is acknowledged, data needs to be retransmitted, etc.).
    */
   void socket_app_appcall(void)
   {
      if(uip_timedout()) {
         Serial.println("TIMEDOUT");
         phase = PHASECLEANUP;
         return;
      }
      if(uip_closed()) {
         Serial.println("CLOSED");
         phase = PHASECLEANUP;
         return;
      }
      if(uip_poll()) {
         //Serial.println("poll");
         if(2 < tcpRetry++) {
            Serial.println("R5");
            uip_close();
            phase = PHASECLEANUP;
         }
      }
      if(uip_aborted()) {
         Serial.println("abort");
         if(!uip_closed()) {
            Serial.println("try1");
            if(2 < tcpRetry++) {
               Serial.println("R6");
               uip_close();
               phase = PHASECLEANUP;
            }
            else {
               uip_connect(&srvaddr, HTONS(7995));
            }
         }
      }
      if(uip_connected()) {
         Serial.println("SENDING DATA");
         uip_send(formatBuf, strlen(formatBuf));
      }
      if(uip_acked()) {
         //Serial.println("acked");
         phase = PHASECLEANUP;
         uip_close();
      }
      if(uip_newdata()) {
         //Serial.println("newdata");
      }
      if(uip_rexmit()) {
         Serial.println("rexmit");
         if(2 < tcpRetry++) {
            Serial.println("R7");
            uip_close();
            phase = PHASECLEANUP;
         }
         else {
            uip_send(formatBuf, strlen(formatBuf));
         }
      }
   }
   
   void uip_dhcp_callback(const struct dhcp_state *s)
   {
      if(NULL != s) {
         
         uip_sethostaddr(s->ipaddr);
         uip_setdraddr(s->default_router);
         uip_setnetmask(s->netmask);
         
         local_ip[0] = uip_ipaddr1(s->ipaddr);
         local_ip[1] = uip_ipaddr2(s->ipaddr);
         local_ip[2] = uip_ipaddr3(s->ipaddr);
         local_ip[3] = uip_ipaddr4(s->ipaddr);
         gateway_ip[0] = uip_ipaddr1(s->default_router);
         gateway_ip[1] = uip_ipaddr2(s->default_router);
         gateway_ip[2] = uip_ipaddr3(s->default_router);
         gateway_ip[3] = uip_ipaddr4(s->default_router);
         subnet_mask[0] = uip_ipaddr1(s->netmask);
         subnet_mask[1] = uip_ipaddr2(s->netmask);
         subnet_mask[2] = uip_ipaddr3(s->netmask);
         subnet_mask[3] = uip_ipaddr4(s->netmask);
         dns_ip[0] = uip_ipaddr1(s->dnsaddr);
         dns_ip[1] = uip_ipaddr2(s->dnsaddr);
         dns_ip[2] = uip_ipaddr3(s->dnsaddr);
         dns_ip[3] = uip_ipaddr4(s->dnsaddr);
              
         Serial.print("DHCP IP     : "); 
         Serial.print(local_ip[0], DEC);
         Serial.print(".");
         Serial.print(local_ip[1], DEC);
         Serial.print(".");
         Serial.print(local_ip[2], DEC);
         Serial.print(".");
         Serial.println(local_ip[3], DEC);
         
         Serial.print("DHCP GATEWAY: "); 
         Serial.print(gateway_ip[0], DEC);
         Serial.print(".");
         Serial.print(gateway_ip[1], DEC);
         Serial.print(".");
         Serial.print(gateway_ip[2], DEC);
         Serial.print(".");
         Serial.println(gateway_ip[3], DEC);
         
         Serial.print("DHCP NETMASK: "); 
         Serial.print(subnet_mask[0], DEC);
         Serial.print(".");
         Serial.print(subnet_mask[1], DEC);
         Serial.print(".");
         Serial.print(subnet_mask[2], DEC);
         Serial.print(".");
         Serial.println(subnet_mask[3], DEC);
              
         Serial.print("DHCP DNS    : "); 
         Serial.print(dns_ip[0], DEC);
         Serial.print(".");
         Serial.print(dns_ip[1], DEC);
         Serial.print(".");
         Serial.print(dns_ip[2], DEC);
         Serial.print(".");
         Serial.println(dns_ip[3], DEC);
      }
      else {
         Serial.println("DHCP NULL FALLBACK");
      }

      // Shut down DHCP
      uip_dhcp_shutdown();
      
      phase = PHASEDNS;
   }

   void uip_dns_callback(char *name, u16_t *ipaddr)
   {   
      if(NULL != ipaddr) {
         uip_ipaddr_copy(srvaddr, ipaddr);
         Serial.print("SERVER ADDR : "); 
         Serial.print(uip_ipaddr1(srvaddr), DEC);
         Serial.print(".");
         Serial.print(uip_ipaddr2(srvaddr), DEC);
         Serial.print(".");
         Serial.print(uip_ipaddr3(srvaddr), DEC);
         Serial.print(".");
         Serial.println(uip_ipaddr4(srvaddr), DEC);
      }
      else {
         Serial.println("DNS NULL FALLBACK");
         //phase = PHASECLEANUP;
         uip_ipaddr(srvaddr, 71,231,196,153);
      }
      
      // Shutdown DNS
      uip_dns_shutdown();
      // Send TCP packet
      uip_connect(&srvaddr, HTONS(7995));
      tcpRetry = 0;
      phase = PHASERUN;         
      Serial.println("PHASERUN");
   }
 
   /*
   void printx(char* data)
   {
      Serial.println(data);
   }
   */
}
