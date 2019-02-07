//
//  ViewController.m
//  VCLogger
//
//  Created by healmax healmax on 2019/2/4.
//  Copyright © 2019 com.healmax. All rights reserved.
//

#import "ViewController.h"
#import "VCLogWritter.h"
#import "VCLogManager.h"

@interface ViewController ()<VCLogWritterDelegate>

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) VCLogManager *manager;

@property (nonatomic, strong) dispatch_queue_t processingQueue;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self commonInit];
}

#pragma mark - VCLogWritterDelegate

- (void)logWritter:(VCLogWritter *)logWritter didArchiveWithFileURLs:(NSArray<NSURL *> *)fileURLs {
    
}

#pragma mark - private

- (void)commonInit {
    self.manager = [[VCLogManager alloc] init];
    
    __weak typeof(self) weakSelf = self;
    [self.manager setLogDidFinishArchivingBlock:^(NSArray<NSURL *> * _Nonnull fileURLs) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        //you can upload the data to your server, after that delete thoes files.
        [strongSelf uploadLogWithFileURLs:fileURLs];
    }];

    [NSTimer scheduledTimerWithTimeInterval:0.01 repeats:YES block:^(NSTimer * _Nonnull timer) {
        [self pushData];
    }];
}

- (void)uploadLogWithFileURLs:(NSArray<NSURL *> *)fileURLs {
    NSString *separator = self.manager.config.separatorDataString;
    
    for (NSURL *fileURL in fileURLs) {
        NSData *data = [NSData dataWithContentsOfFile:fileURL.path];
        NSString *fileString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSArray<NSString *> *eachDataString = [fileString componentsSeparatedByString:separator];
        
        for (NSString *dataJSONString in eachDataString) {
            NSData *JSONData = [dataJSONString dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:JSONData options:NSJSONReadingMutableContainers error:nil];
            NSLog(@"%@", dic);
        }
        
        [[NSFileManager defaultManager] removeItemAtPath:fileURL.path error:nil];
    }
}

- (void)pushData {
    static int index = 0;
    index ++;
    NSDictionary *dic2 = @{@"id"         : @(index),
                           @"phone"      : @"886900871717",
                           @"address"    : @"1600 Pennsylvania Avenue, NW Washington, DC 20500"};
    
    [self.manager addLog:dic2];
}

@end
