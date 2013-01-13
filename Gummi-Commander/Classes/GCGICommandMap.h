//
// Created by Simon Schmid
//
// contact@sschmid.com
//

#import <Foundation/Foundation.h>
#import "GCCommandMap.h"

@class GDDispatcher;
@class GIInjector;

@interface GCGICommandMap : NSObject <GCCommandMap>
@property(nonatomic, strong) GDDispatcher *dispatcher;
@property(nonatomic, strong) GIInjector *injector;
@end