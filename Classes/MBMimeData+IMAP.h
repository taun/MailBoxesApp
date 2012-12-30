//
//  MBMimeData+IMAP.h
//  MailBoxes
//
//  Created by Taun Chapman on 12/20/11.
//  Copyright (c) 2011 MOEDAE LLC. All rights reserved.
//

#import "MBMimeData.h"

@interface MBMimeData (IMAP)


/*!
 Decode mime encode data
 
 Converts encoded data to decoded data
 Erases encoded data
 sets isDecoded flag
 
 */
-(BOOL) decode;

@end
