//
//  PFMMainThreadMonitor.m
//  Pods
//
//  Created by luqyluqe on 3/12/17.
//
//

#import "PFMMainThreadMonitor.h"
#import "BSBacktraceLogger.h"
#import "PFMConsoleLogger.h"

@interface PFMMainThreadMonitor ()

@property (atomic,strong) dispatch_semaphore_t startSema;
@property (atomic,strong) dispatch_semaphore_t endSema;
@property (atomic,assign) BOOL timedOut;
@property (atomic,assign) CFAbsoluteTime startTime;
@property (atomic,assign) CFAbsoluteTime endTime;
@property (atomic,copy) NSString* callStack;

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
                self.startTime=CFAbsoluteTimeGetCurrent();
                if (self.startSema) {
                    dispatch_semaphore_signal(self.startSema);
                }
                break;
            }
            case kCFRunLoopBeforeWaiting:
            {
                self.endTime=CFAbsoluteTimeGetCurrent();
                if (self.callStack) {
                    NSString* border=@"================================================================================";
                    [self.logger log:[NSString stringWithFormat:@"\ntime cost : %f\n%@\n%@\n%@\n\n",self.endTime-self.startTime,border,self.callStack,border]];
                    self.callStack=nil;
                }
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
    
    [NSThread detachNewThreadSelector:@selector(monitorRoutine) toTarget:self withObject:nil];
}

-(void)monitorRoutine
{
    self.startSema=dispatch_semaphore_create(0);
    while (YES) {
        dispatch_semaphore_wait(self.startSema, DISPATCH_TIME_FOREVER);
        if (!self.endSema) {
            self.endSema=dispatch_semaphore_create(0);
        }
        long result=dispatch_semaphore_wait(self.endSema, dispatch_time(DISPATCH_TIME_NOW, self.timeout*NSEC_PER_SEC));
        self.timedOut=result!=0;
        if (self.timedOut) {
            self.callStack=[[BSBacktraceLogger bs_backtraceOfMainThread] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\n"]];
        }
    }
}

-(id<PFMLogging>)logger
{
    if (!_logger) {
        _logger=[[PFMConsoleLogger alloc] init];
    }
    return _logger;
}

@end
