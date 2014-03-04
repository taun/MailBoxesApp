//
//  MBEncodedString.h
//  MailBoxes
//
//  Created by Taun Chapman on 02/11/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 An object for passing an NSString with an associated NSStringEncoding.
 Used by the MIME valueTransformers to transform 7 bit ascii strings to their proper 16 bit representations.
 
 @param string the string

 @param encoding the charset encoding from the MIME data
 */
@interface MBEncodedString : NSObject <NSCopying>

@property (nonatomic,strong) NSString*          string;
@property (nonatomic,assign) NSStringEncoding   encoding;

+(instancetype) encodedString: (NSString*) string encoding: (NSStringEncoding) encoding;
-(instancetype) initWithString: (NSString*) string encoding: (NSStringEncoding) encoding;

-(NSData*) asData;
-(NSData*) asUTF8Data;

@end
