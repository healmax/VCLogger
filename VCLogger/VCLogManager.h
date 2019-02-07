//
//  VCLogManager.h
//  VCLogger
//
//  Created by healmax healmax on 2019/2/5.
//  Copyright © 2019 com.healmax. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VCLogWritter.h"

NS_ASSUME_NONNULL_BEGIN

@interface VCLogManagerConfig : VCLogWritterConfig

@property (nonatomic, assign) NSUInteger flushToDiskPeriod;
@property (nonatomic, assign) NSUInteger minimunDataCountToSave;

+ (instancetype)defaultConfig;

@end

@interface VCLogManager : NSMutableArray

@property (nonatomic, strong, readonly) VCLogManagerConfig *config;

- (instancetype)initWithConfig:(VCLogManagerConfig *)config;

- (void)addLogsFromArray:(NSArray<NSDictionary *> *)logs;
- (void)addLog:(NSDictionary *)log;

- (void)setLogDidFinishArchivingBlock:(void (^)(NSArray<NSURL *> *fileURLs))block;

@end

NS_ASSUME_NONNULL_END
