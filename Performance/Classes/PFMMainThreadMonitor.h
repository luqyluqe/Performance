//
//  PFMMainThreadMonitor.h
//  Pods
//
//  Created by luqyluqe on 3/12/17.
//
//

#import "PFMLogging.h"

@interface PFMMainThreadMonitor : NSObject

@property (nonatomic,strong) id<PFMLogging> logger;

@property (nonatomic,assign) NSTimeInterval timeout;

+(instancetype)sharedMonitor;
+(instancetype)new NS_UNAVAILABLE;
-(instancetype)init NS_UNAVAILABLE;

-(void)launch;

@end
