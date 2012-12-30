//
//  RFC2822Address.h
//  MailBoxes
//
//  Created by Taun Chapman on 10/3/11.
//  Copyright 2011 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 Resnick                     Standards Track                    [Page 16]
 RFC 2822                Internet Message Format               April 2001
 
 3.4. Address Specification
 Addresses occur in several message header fields to indicate senders
 and recipients of messages.  An address may either be an individual
 mailbox, or a group of mailboxes.
 
 address         =  mailbox / group
 mailbox         =  name-addr / addr-spec
 name-addr       =  [display-name] angle-addr
 angle-addr      =  [CFWS] "<" addr-spec ">" [CFWS] / obs-angle-addr
 group           =  display-name ":" [mailbox-list / CFWS] ";"
                    [CFWS]

 
 display-name    = phrase
 mailbox-list    = (mailbox *("," mailbox)) / obs-mbox-list
 address-list    = (address *("," address)) / obs-addr-list
 
  
 An addr-spec is a specific Internet identifier that contains a
 locally interpreted string followed by the at-sign character ("@",
 ASCII value 64) followed by an Internet domain.  The locally
 interpreted string is either a quoted-string or a dot-atom.  If the
 string can be represented as a dot-atom (that is, it contains no
 characters other than atext characters or "." surrounded by atext
 characters), then the dot-atom form SHOULD be used and the
 quoted-string form SHOULD NOT be used. Comments and folding white
 space SHOULD NOT be used around the "@" in the addr-spec.
 addr-spec          = local-part "@" domain
 local-part         =  dot-atom / quoted-string / obs-local-part
 domain             = dot-atom / domain-literal / obs-domain
 domain-literal     = [CFWS] "[" *([FWS] dcontent) [FWS] "]" [CFWS]
 dcontent           = dtext / quoted-pair
 dtext              = NO-WS-CTL /   ; Non white space controls
                    
                        %d33-90 /   ; The rest of the US-ASCII
                        %d94-126    ;  characters not including "[",
                                    ;  "]", or "\"
 
 
  
 The domain portion identifies the point to which the mail is
 delivered. In the dot-atom form, this is interpreted as an Internet
 domain name (either a host name or a mail exchanger name) as
 described in [STD3, STD13, STD14].  In the domain-literal form, the
 domain is interpreted as the literal Internet address of the
 particular host.  In both cases, how addressing is used and how
 messages are transported to a particular host is covered in the mail
 transport document [RFC2821].  These mechanisms are outside of the
 scope of this document.
 The local-part portion is a domain dependent string.  In addresses,
 it is simply interpreted on the particular host as a name of a
 particular mailbox.
 */

@interface RFC2822Address : NSObject

@end
