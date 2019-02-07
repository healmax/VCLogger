//
//  VCLogWritter.h
//  VCLogger
//
//  Created by healmax healmax on 2019/2/4.
//  Copyright © 2019 com.healmax. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class VCLogWritter;

@interface VCLogWritterConfig : NSObject

@property (nonatomic, assign) NSInteger fileMaximumSize;
@property (nonatomic, copy) NSString *directory;
@property (nonatomic, copy) NSString *separatorDataString;

+ (instancetype)defaultConfig;

@end

@protocol VCLogWritterDelegate <NSObject>

@optional
- (void)logWritter:(VCLogWritter *)logWritter didArchiveWithFileURLs:(NSArray<NSURL *> *)fileURLs;

@end

@interface VCLogWritter : NSObject

@property (nonatomic, strong, readonly) VCLogWritterConfig *config;
@property (nonatomic, weak) id<VCLogWritterDelegate> delegate;
@property (nonatomic, assign, readonly) unsigned long long fileByteSize;

- (instancetype)initWithConfig:(VCLogWritterConfig *)config;

- (void)enqueueDataWithDictionary:(NSDictionary *)dataDic;
- (void)enqueueDataWithArray:(NSArray<NSDictionary *> *)dataArray;
- (void)archiveFile;

@end

NS_ASSUME_NONNULL_END
