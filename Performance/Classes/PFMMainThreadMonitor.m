//
//  PFMMainThreadMonitor.m
//  Pods
//
//  Created by luqyluqe on 3/12/17.
//
//

#import "PFMMainThreadMonitor.h"
#import "BSBacktraceLogger.h"

@interface PFMMainThreadMonitor ()

@property (atomic,strong) dispatch_semaphore_t startSema;
@property (atomic,strong) dispatch_semaphore_t endSema;
@property (atomic,assign) BOOL timedOut;

@end

@implementation PFMMainThreadMonitor

+(instancetype)sharedMonitor
{
    static id instance=nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance=[[self alloc] init];
    });
    return instance;
}

-(instancetype)init
{
    if (self=[super init]) {
        self.timedOut=NO;
        self.timeout=0.1;
    }
    return self;
}

-(void)launch
{
    CFRunLoopObserverRef observer=CFRunLoopObserverCreateWithHandler(kCFAllocatorDefault, kCFRunLoopAllActivities, YES, 0, ^(CFRunLoopObserverRef observer, CFRunLoopActivity activity) {
        switch (activity) {
            case kCFRunLoopAfterWaiting:
            {
                if (self.startSema) {
                    dispatch_semaphore_signal(self.startSema);
                }
                break;
            }
            case kCFRunLoopBeforeSources:
            {
                break;
            }
            case kCFRunLoopBeforeWaiting:
            {
                if (self.timedOut) {
                    self.timedOut=NO;
                }else{
                    if (self.endSema) {
                        dispatch_semaphore_signal(self.endSema);
                    }
                }
                break;
            }
            default:
                break;
        }
    });
    CFRunLoopRef runLoop=CFRunLoopGetMain();
    CFRunLoopAddObserver(runLoop, observer, kCFRunLoopCommonModes);
    
    dispatch_queue_t monitorQueue=dispatch_queue_create("dispatch_queue_monitor", DISPATCH_QUEUE_SERIAL);
    dispatch_async(monitorQueue, ^{
        self.startSema=dispatch_semaphore_create(0);
        while (YES) {
            dispatch_semaphore_wait(self.startSema, DISPATCH_TIME_FOREVER);
            if (!self.endSema) {
                self.endSema=dispatch_semaphore_create(0);
            }
            long result=dispatch_semaphore_wait(self.endSema, dispatch_time(DISPATCH_TIME_NOW, self.timeout*NSEC_PER_SEC));
            self.timedOut=result!=0;
            if (self.timedOut) {
                NSString* callStack=[BSBacktraceLogger bs_backtraceOfMainThread];
                NSLog(@"%@",callStack);
            }
        }
    });
}

@end
