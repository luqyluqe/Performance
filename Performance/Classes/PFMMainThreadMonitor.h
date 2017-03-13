//
//  PFMMainThreadMonitor.h
//  Pods
//
//  Created by luqyluqe on 3/12/17.
//
//

#import <Foundation/Foundation.h>

@interface PFMMainThreadMonitor : NSObject

@property (nonatomic,assign) NSTimeInterval timeout;

+(instancetype)sharedMonitor;
+(instancetype)new NS_UNAVAILABLE;
-(instancetype)init NS_UNAVAILABLE;

-(void)launch;

@end
