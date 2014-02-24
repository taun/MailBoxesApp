//
//  MBMimeData.h
//  MailBoxes
//
//  Created by Taun Chapman on 12/20/11.
//  Copyright (c) 2011 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MBMime;


/**
 *  Data to be used with MBMime classes
 *  Note there were two options for storing the data
 *
 *  # as raw data. Basically the same format as the data was receieved
 *    however this would mean every class were the data is used would need 
 *    to know how to decode the data.
 *  # save the data in a standard format. This was the chosen option.
 *    all of the data is stored either as utf-8 for strings or real native
 *    binary for binary based types such as images, audio, video, ...
 *
 *  @see MBMime
 */
@interface MBMimeData : NSManagedObject
/**
 *  The data decoded to either utf-8 string or binary data.
 */
@property (nonatomic, retain) NSData * decoded;
/**
 *  The raw ascii data.
 *  For space considerations, encoded is nulled once sucessfully decoded.
 */
@property (nonatomic, retain) NSString * encoded;
/**
 *  IANA encoding needed to decode the encoded ascii data.
 *
 *  @see MBMime.encoding
 */
@property (nonatomic, retain) NSString * encoding;
/**
 *  BOOL to indicate the encoded data was successfully decoded and stored as decoded.
 */
@property (nonatomic, retain) NSNumber * isDecoded;
/**
 *  Back reference to the parent mime.
 */
@property (nonatomic, retain) MBMime *mimeStructure;

@end
