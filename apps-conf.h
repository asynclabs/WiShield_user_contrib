
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

//Here we include the header file for the application(s) we use in our project.
//#define APP_WEBSERVER
//#define APP_WEBCLIENT
//#define APP_SOCKAPP
//#define APP_UDPAPP
#define APP_WISERVER

//#define UIP_DNS               //Add DNS capabilities - APP_UDPAPP must be defined!
//#define UIP_SCAN              //Add Access Point scan capabilities
#define MAX_TCP_CONNS       1 // Max TCP connections desired
#define MAX_TCP_LISTENPORTS 1 // Max TCP listening ports
#define MAX_UDP_CONNS       1 // Max UDP connections desired
// Don't play with UIP_CLOCK_DIV unless you know what you are doing!
#define UIP_CLOCK_DIV       2 // Referenced in stack.c; default 2

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

#ifdef UIP_DNS
#include "uip_dns.h"
#endif

#endif /*__APPS_CONF_H__*/
