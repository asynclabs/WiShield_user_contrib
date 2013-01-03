
/******************************************************************************

  Filename:		apps-conf.h
  Description:	Web application configuration file

 ******************************************************************************

  TCP/IP stack and driver for the WiShield 1.0 wireless devices

  Copyright(c) 2009 Async Labs Inc. All rights reserved.

  This program is free software; you can redistribute it and/or modify it
  under the terms of version 2 of the GNU General Public License as
  published by the Free Software Foundation.

  This program is distributed in the hope that it will be useful, but WITHOUT
  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
  more details.

  You should have received a copy of the GNU General Public License along with
  this program; if not, write to the Free Software Foundation, Inc., 59
  Temple Place - Suite 330, Boston, MA  02111-1307, USA.

  Contact Information:
  <asynclabs@asynclabs.com>

   Author               Date        Comment
  ---------------------------------------------------------------
   AsyncLabs			05/29/2009	Initial port

 *****************************************************************************/

#ifndef __APPS_CONF_H__
#define __APPS_CONF_H__

// ----------------------------------------------------------------------------
// -- Begin uIP/WiShield stack configuration settings

//
// Application type defines; uncomment to enable APP_TYPES
//   APP_UDPAPP is used for UDP only apps as well as DNS and DHCP apps; if your app will use
//   DNS and/or DHCP then your APP_TYPE (e.g. APP_WISERVER) AND APP_UDPAPP must be defined 
//   (uncommented). Currently only APP_UDPAPP may be defined at the same time as any other APP_TYPE
//
//#define APP_WEBSERVER
//#define APP_WEBCLIENT
//#define APP_SOCKAPP
//#define APP_UDPAPP
#define APP_WISERVER

//
// Add on features; uncomment to enable additional functionality
//
//#define UIP_DNS                  // Add DNS capabilities - APP_UDPAPP must be defined!
//#define UIP_DHCP                 // Add DHCP capabilities - APP_UDPAPP must be defined!
//#define UIP_SCAN                 // Add Access Point scan capabilities

//
// Commonly accessed WiServer settings 
//
#define WISERVER_GET_STRING_MAX 64 // Length of buffer which holds URL/GET passed to WiServer
                                   // SimpleServer sendMyPage() page serving function

//
// Commonly accessed uIP stack settings 
//
#define UIP_WEP_KEY_LEN         13 // WEP Key length: 5 bytes (64-bit WEP); 13 bytes (128-bit WEP)
#define UIP_WEP_KEY_DEFAULT      0 // Default WEP key ID: Key 0, 1, 2, 3
#define MAX_TCP_CONNS            2 // Max TCP connections desired
#define MAX_TCP_LISTENPORTS      2 // Max TCP listening ports
#define MAX_UDP_CONNS            1 // Max UDP connections desired
// Don't play with UIP_CLOCK_DIV unless you know what you are doing!
#define UIP_CLOCK_DIV            2 // Referenced in stack.c; default 2

// -- End uIP/WiShield stack configuration settings
// ----------------------------------------------------------------------------


#ifdef APP_WEBSERVER
#include "webserver.h"
#endif

#ifdef APP_WEBCLIENT
#include "webclient.h"
#endif

#ifdef APP_SOCKAPP
#include "socketapp.h"
#endif

#ifdef APP_UDPAPP
#include "udpapp.h"
#define UIP_UDP_ENABLED 1
#else
#define UIP_UDP_ENABLED 0
#endif

#ifdef APP_WISERVER
#include "server.h"
#endif

#ifdef UIP_DHCP
#include "uip_dhcp.h"
#endif

#ifdef UIP_DNS
#include "uip_dns.h"
#endif

#endif /*__APPS_CONF_H__*/
