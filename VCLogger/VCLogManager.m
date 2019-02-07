//
//  VCLogManager.m
//  VCLogger
//
//  Created by healmax healmax on 2019/2/5.
//  Copyright © 2019 com.healmax. All rights reserved.
//

#import "VCLogManager.h"
#import "VCLogWritter.h"

@implementation VCLogManagerConfig

+ (instancetype)defaultConfig {
    VCLogManagerConfig *config = [[VCLogManagerConfig alloc] init];
    config.flushToDiskPeriod = 20;
    config.minimunDataCountToSave = 100;
    
    return config;
}

- (void)setFlushToDiskPeriod:(NSUInteger)flushToDiskPeriod {
    NSAssert(flushToDiskPeriod >= 10, @"flushToDiskPeriod must be >= 2");
    _flushToDiskPeriod = flushToDiskPeriod;
}

@end

@interface VCLogManager()<VCLogWritterDelegate>

@property (nonatomic, strong) NSTimer *flushTimer;
@property (nonatomic, strong, readwrite) VCLogManagerConfig *config;

@property (nonatomic, strong) NSMutableArray<NSDictionary *> *logs;
@property (nonatomic, strong) VCLogWritter *logWritter;

@property (nonatomic, copy) void(^logDidFinishArchiving)(NSArray<NSURL *> *fileURLs);

@end

@implementation VCLogManager

- (instancetype)init {
    if (self = [super init]) {
        [self commonInit];
    }
    
    return self;
}

- (instancetype)initWithConfig:(VCLogManagerConfig *)config {
    if (self = [super init]) {
        [self commonInit];
        _config = config;
    }
    
    return self;
}

#pragma mark - public

- (void)addLogsFromArray:(NSArray<NSDictionary *> *)logs {
    for (NSDictionary *dic in logs) {
        [self addLog:dic];
    }
}

- (void)addLog:(NSDictionary *)log {
    @synchronized (self.logs) {
        [self.logs addObject:log];
        [self writeDataIfNeeded];
    }
}

- (void)setLogDidFinishArchivingBlock:(void (^)(NSArray<NSURL *> *fileURLs))block {
    self.logDidFinishArchiving = block;
}

#pragma mark - VCLogWritterDelegate

- (void)logWritter:(VCLogWritter *)logWritter didArchiveWithFileURLs:(NSArray<NSURL *> *)fileURLs {
    self.logDidFinishArchiving(fileURLs);
}

#pragma maik - private

- (void)commonInit {
    _logs = [NSMutableArray new];
    _config = [VCLogManagerConfig defaultConfig];
    _flushTimer = [NSTimer scheduledTimerWithTimeInterval:self.config.flushToDiskPeriod repeats:YES block:^(NSTimer * _Nonnull timer) {
        [self.logWritter archiveFile];
    }];
}

- (void)writeDataIfNeeded {
    if (self.logs.count > self.config.minimunDataCountToSave) {
        @synchronized (self.logs) {
            [self.logWritter enqueueDataWithArray:[self.logs copy]];
            [self.logs removeAllObjects];
        }
    }
}

#pragma mark - accessor

- (VCLogWritter *)logWritter {
    if (!_logWritter) {
        _logWritter = [[VCLogWritter alloc] initWithConfig:self.config];
        _logWritter.delegate = self;
    }
    
    return _logWritter;
}

@end
