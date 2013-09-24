//
//  RFC2822RawMessageHeader.h
//  MailBoxes
//
//  Created by Taun Chapman on 10/3/11.
//  Copyright 2011 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 Class for parsing a raw rfc2822 message header.
 
 > Resnick                     Standards Track                    [Page 16]
 RFC 2822                Internet Message Format               April 2001
 
 > Header fields are lines composed of a field name, followed by a colon
 (":"), followed by a field body, and terminated by CRLF.  A field
 name MUST be composed of printable US-ASCII characters (i.e.,
 characters that have values between 33 and 126, inclusive), except
 colon.  A field body may be composed of any US-ASCII characters,
 except for CR and LF.  However, a field body may contain CRLF when
 used in header "folding" and  "unfolding".
 
 > The space (SP, ASCII value 32) and horizontal tab (HTAB, ASCII value 9) characters
 (together known as the white space characters, WSP), and those WSP
 characters are subject to header "folding" and "unfolding"
 
     FWS    = ([*WSP CRLF] 1*WSP) /   ; Folding white space obs-FWS
     CFWS   = *([FWS] comment) (([FWS] comment) / FWS)
 
 
 ### 3.4. Address Specification
 
 > Addresses occur in several message header fields to indicate senders
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
 
 ### Sample Header
 
        * 2246 FETCH (FLAGS (\Seen) BODY[HEADER] {3102}
        Delivered-To: taunpc@gmail.com
        Received: by 10.229.39.207 with SMTP id h15cs115485qce; Wed, 10 Aug 2011
         20:15:58 -0700 (PDT)
         
        Return-Path: <dexterity-development+bncCMK17OfJDhDsko3yBBoEEn4GUA@googlegroups.com>
         
        Received-SPF: pass (google.com: domain of
         dexterity-development+bncCMK17OfJDhDsko3yBBoEEn4GUA@googlegroups.com
         designates 10.216.70.71 as permitted sender) client-ip=10.216.70.71;

        Authentication-Results: mr.google.com; spf=pass (google.com: domain of
         dexterity-development+bncCMK17OfJDhDsko3yBBoEEn4GUA@googlegroups.com
         designates 10.216.70.71 as permitted sender)
         smtp.mail=dexterity-development+bncCMK17OfJDhDsko3yBBoEEn4GUA@googlegroups.com;
         dkim=pass
         header.i=dexterity-development+bncCMK17OfJDhDsko3yBBoEEn4GUA@googlegroups.com
         
        Received: from mr.google.com ([10.216.70.71]) by 10.216.70.71 with SMTP id
         o49mr2537649wed.2.1313032556726 (num_hops = 1); Wed, 10 Aug 2011 20:15:56
         -0700 (PDT)
         
        DKIM-Signature: v=1; a=rsa-sha256; c=relaxed/relaxed; d=googlegroups.com;
         s=beta; h=x-beenthere:mime-version:to:from:subject:message-id:date
         :x-original-sender:reply-to:precedence:mailing-list:list-id
         :x-google-group-id:list-post:list-help:list-archive:sender
         :list-unsubscribe:content-type;
         bh=m1ttKikWoVsb4VBFamqSCDADPb3wULQW49rXKytFhbA=;
         b=J2DoxOxRmhQ9t9h2WH2dMG72u9iIew8328Z5OzGuCDYggUxywQGuQmQ/fcQFIoF9uu
         UIdGaf4cOZdplyt9RRdNH2O6eaYzZxhDUhnDBSsM3L4tnwefdGSS/Sa+/F1PQkv4uy0q
         zNQ53y8gt2QCB6XW/vMinQlBrSPv5QhvIqPlc=
         
        Received: by 10.216.70.71 with SMTP id o49mr2537649wed.2.1313032556724; Wed,
         10 Aug 2011 20:15:56 -0700 (PDT)
         
        X-BeenThere: dexterity-development@googlegroups.com
         
        Received: by 10.227.134.5 with SMTP id h5ls5543451wbt.2.gmail; Wed, 10 Aug
         2011 20:15:56 -0700 (PDT)
         
        Received: by 10.216.230.38 with SMTP id i38mr9989weq.3.1313032555825; Wed, 10
         Aug 2011 20:15:55 -0700 (PDT)
         
        MIME-Version: 1.0
         
        To: Digest Recipients <dexterity-development+digest@googlegroups.com>
         
        From: dexterity-development+noreply@googlegroups.com
         
        Subject: Digest for dexterity-development@googlegroups.com - 2 Messages in 2
         Topics
         
        Message-ID: <20cf301fbf3b11859604aa32377b@google.com>
         
        Date: Thu, 11 Aug 2011 03:15:55 +0000
         
        X-Original-Sender: dexterity-development@googlegroups.com
         
        Reply-To: dexterity-development@googlegroups.com
         
        Precedence: list
         
        Mailing-list: list dexterity-development@googlegroups.com; contact
         dexterity-development+owners@googlegroups.com
         
        List-ID: <dexterity-development.googlegroups.com>
         
        X-Google-Group-Id: 500849908418
         
        List-Post: <http://groups.google.com/group/dexterity-development/post?hl=en_US>,
         <mailto:dexterity-development@googlegroups.com>
         
        List-Help: <http://groups.google.com/support/?hl=en_US>,
         <mailto:dexterity-development+help@googlegroups.com>
         
        List-Archive: <http://groups.google.com/group/dexterity-development?hl=en_US>
         
        Sender: dexterity-development@googlegroups.com
         
        List-Unsubscribe: <http://groups.google.com/group/dexterity-development/subscribe?hl=en_US>,
         <mailto:dexterity-development+unsubscribe@googlegroups.com>
         
        Content-Type: multipart/alternative; boundary=0016367f94b4b30060474d22062

        )
 
 Unfold lines
 Use regex to extract main components such as subject, from, ....
 Parse addresses
 
 */
@interface RFC2822RawMessageHeader : NSObject

/*!
 Save the raw header. 
 Should this be NSData?
 Should this be a copy?
 */
@property(strong, nonatomic, readonly) NSString             *unfolded;
@property(strong, nonatomic, readonly) NSMutableDictionary  *fields;

-(id) initWithString: (NSString *) rawString;

-(NSString *) _unfold: (NSString *) rawString;
-(void) _identifyFields;

@end
