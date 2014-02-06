//
//  MBPluginsManager.m
//  MailBoxes
//
//  Created by Taun Chapman on 02/05/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBPluginsManager.h"

#import <MoedaeMailPluginsBase/MoedaeMailPluginsBase.h>


NSString *ext = @"bundle";


@interface MBPluginsManager ()

@property (nonatomic,strong) NSMutableDictionary     *typeToClassMappings;

-(NSUInteger) loadPlugins;

@end


@implementation MBPluginsManager

+(instancetype) manager {
    
    static MBPluginsManager* sharedManager = nil;
    
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        sharedManager = [[self class] new];
    });
    
    return sharedManager;
}

- (instancetype) init {
    
    self = [super init];
    if (self) {
        [self loadPlugins];
    }
    return self;
}

-(NSUInteger) loadPlugins {
    
    NSBundle *appBundle = [NSBundle mainBundle];
    NSString* plugInsPath = [appBundle builtInPlugInsPath];
    
    NSArray* bundlePaths = [appBundle pathsForResourcesOfType:@"mmmimeviewerplugin"
                                         inDirectory:@"../PlugIns"];
    
    if ((bundlePaths.count >0) && (self.typeToClassMappings == nil)) {
        // only create the mapping if necessary
        _typeToClassMappings = [NSMutableDictionary new];
    }
    
    for (id fullPath in bundlePaths) {
        Class principalClass;
        
        NSBundle* bundle = [NSBundle bundleWithPath:fullPath];
        principalClass = [bundle principalClass];
        
        if ([principalClass isSubclassOfClass: [MoedaeMailPluginsBase class]]) {
            NSString* mimeType = [[principalClass type] uppercaseString];
            NSString* mimeSubtype = [[principalClass subtype] uppercaseString];
            
            NSString* classKey = [NSString stringWithFormat:@"%@%@", mimeType, mimeSubtype];
            if ((classKey != nil) && (classKey.length > 0)) {
                [self.typeToClassMappings setObject: principalClass forKey: classKey];
            }
        }
    }
    return  self.typeToClassMappings.count;
}

-(Class) classForMimeType: (NSString*) type subtype: (NSString*) subtype {
    Class pluginClass;
    
    if ((self.typeToClassMappings!=nil) && ([self.typeToClassMappings count] > 0)) {
        NSString* typeSubtypeUpper = [NSString stringWithFormat: @"%@%@",[type uppercaseString], [subtype uppercaseString]];
        pluginClass = [self.typeToClassMappings objectForKey: typeSubtypeUpper];
        
        // double check it is the right class, was also checked before adding to mappings
        if (![pluginClass isSubclassOfClass: [MoedaeMailPluginsBase class]]) {
            pluginClass = nil;
        }
   }
    return pluginClass;
}

//-(id) instanceForMimeViewerTypeSubtype:(NSString *)typeSubtype {
//    id pluginInstance;
//    
//    Class pluginClass = [self classForMimeTypeSubtype: typeSubtype];
//    if ([pluginClass isSubclassOfClass: [MoedaeMailPluginsBase class]]) {
//        pluginInstance = [pluginClass new];
//    }
//    return pluginInstance;
//}
@end
