/**
 * \addtogroup resolv
 * @{
 */
/**
 * \file
 * DNS resolver code header file.
 * \author Adam Dunkels <adam@dunkels.com>
 */

/*
 * Copyright (c) 2002-2003, Adam Dunkels.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. The name of the author may not be used to endorse or promote
 *    products derived from this software without specific prior
 *    written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS
 * OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
 * GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * This file is part of the uIP TCP/IP stack.
 *
 * $Id: resolv.h,v 1.4 2006/06/11 21:46:37 adam Exp $
 *
 */
 
#if defined UIP_DNS && !defined __DNS_H__
#define __DNS_H__

#include "uipopt.h"

/**
 * Callback function which is called when a hostname is found.
 *
 * This function must be implemented by the module that uses the DNS
 * resolver. It is called when a hostname is found, or when a hostname
 * was not found.
 *
 * \param name A pointer to the name that was looked up.  \param
 * ipaddr A pointer to a 4-byte array containing the IP address of the
 * hostname, or NULL if the hostname could not be found.
 */
void uip_dns_callback(char *name, u16_t *ipaddr);

/* Functions. */
void uip_dns_conf(u16_t *dnsserver);
u16_t *uip_dns_getserver(void);
void uip_dns_init(void);
u16_t *uip_dns_lookup(char *name);
void uip_dns_query(char *name);
void uip_dns_shutdown();
void uip_dns_run(void);
void uip_dns_newdata(void);

#endif // defined UIP_DNS && !defined __DNS_H__

/** @} */

