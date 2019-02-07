//
//  VCLogWritter.m
//  VCLogger
//
//  Created by healmax healmax on 2019/2/4.
//  Copyright © 2019 com.healmax. All rights reserved.
//

#import "VCLogWritter.h"
#import "NSMutableArray+VCQueueAdditions.h"

@implementation VCLogWritterConfig

+ (instancetype)defaultConfig {
    return  [[VCLogWritterConfig alloc] init];
}

- (instancetype)init {
    if (self = [super init]) {
        self.fileMaximumSize = 1024 * 1024;
        self.directory = @"VCLog";
        self.separatorDataString = @"\n";
    }
    
    return self;
}

@end

@interface VCLogWritter()

@property (nonatomic, strong, readwrite) VCLogWritterConfig *config;

@property (nonatomic, strong) NSFileHandle *fileHandle;
@property (nonatomic, copy) NSString *filePath;

@property (nonatomic, strong) NSMutableArray *logWritterQueue;
@property (nonatomic, strong) NSLock *lock;

#if OS_OBJECT_USE_OBJC
@property (nonatomic, strong) dispatch_queue_t diskIOQueue;
#else
@property (nonatomic, assign) dispatch_queue_t diskIOQueue;
#endif


@end

@implementation VCLogWritter

- (instancetype)init {
    if (self = [super init]) {
        [self commonInit];
    }
    
    return self;
}

- (instancetype)initWithConfig:(VCLogWritterConfig *)config {
    if (self = [super init]) {
        NSAssert(config.directory.length > 0, @"directory can't be empty or nil");
        [self commonInit];
        _config = config;
    }
    
    return self;
}

#pragma mark - public

- (void)enqueueDataWithDictionary:(NSDictionary *)dataDic {
    dispatch_async(self.diskIOQueue, ^{
        [self.lock lock];
        [self.logWritterQueue enqueue:dataDic];
        [self.lock unlock];
        
        if (self.hasNextData) {
            [self recordNextData];
        }
    });
}

- (void)enqueueDataWithArray:(NSArray<NSDictionary *> *)dataArray{
    dispatch_async(self.diskIOQueue, ^{
        [self.lock lock];
        [self.logWritterQueue addObjectsFromArray:dataArray];
        [self.lock unlock];
        
        if (self.hasNextData) {
            [self recordNextData];
        }
    });
}

- (void)archiveFile {
    if (self.fileByteSize == 0) {
        NSLog(@"File size is Zero. Don't need to archive");
        return;
    }
    
    NSURL *archiveFileURL = [NSURL fileURLWithPath:self.filePath];
    [self.fileHandle closeFile];
    self.fileHandle = nil;
    self.filePath = nil;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(logWritter:didArchiveWithFileURLs:)]) {
            [self.delegate logWritter:self didArchiveWithFileURLs:@[archiveFileURL]];
        }
    });
}

#pragma mark - private

- (void)commonInit {
    NSString *diskIOQueueName = [NSString stringWithFormat:@"com.healmax.diskIOQueue.logWritter"];
    dispatch_queue_attr_t queueAttributes = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_BACKGROUND, 0);
    self.diskIOQueue = dispatch_queue_create([diskIOQueueName UTF8String], queueAttributes);
    self.logWritterQueue = [NSMutableArray new];
    self.lock = [[NSLock alloc] init];
    self.config = [VCLogWritterConfig defaultConfig];
}

- (void)recordNextData {
    if (!self.hasNextData) {
        return;
    }
    
    [self.lock lock];
    NSDictionary *dic = [self.logWritterQueue dequeue];
    [self.lock unlock];
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:dic options:0 error:nil];
    NSData *separator = [self.config.separatorDataString dataUsingEncoding:NSUTF8StringEncoding];
    
    NSMutableData *result = [NSMutableData new];
    
    if (self.fileHandle.offsetInFile != 0) {
        [result appendData:separator];
    }
    
    [result appendData:data];
    
    if (data) {
        [self saveData:[result copy]];
    }
}

- (void)saveData:(NSData *)data {
    [self.fileHandle seekToEndOfFile];
    [self.fileHandle writeData:data];
    [self.fileHandle synchronizeFile];
    [self archiveFileIfNeeded];
    [self recordNextData];
}

- (NSString *)createFilePath {
    NSTimeInterval timeInterval = ceil([[NSDate date] timeIntervalSince1970]);
    NSString *filePath = [self.directoryPath stringByAppendingPathComponent:@(timeInterval).stringValue];
    
    [[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
    return filePath;
}

- (NSArray<NSURL *> *)fetchAllLogFileURLs {
    NSArray * fileURLs =
        [[NSFileManager defaultManager] contentsOfDirectoryAtURL:[NSURL fileURLWithPath:self.directoryPath]
                                      includingPropertiesForKeys:@[]
                                                         options:NSDirectoryEnumerationSkipsHiddenFiles
                                                           error:nil];
    
    return fileURLs;
}

- (void)archiveFileIfNeeded {
    if (self.fileByteSize > self.config.fileMaximumSize) {
        [self archiveFile];
    }
}

#pragma mark - accessor

- (NSFileHandle *)fileHandle {
    if (!_fileHandle) {
        _fileHandle = [NSFileHandle fileHandleForWritingAtPath:self.filePath];
    }
    
    return _fileHandle;
}

- (NSString *)directoryPath {
    NSString *rootPath = NSTemporaryDirectory();
    NSString *directoryPath = [rootPath stringByAppendingPathComponent:self.config.directory];
    if (![[NSFileManager defaultManager] fileExistsAtPath:directoryPath]) {
        NSError *error;
        BOOL isExist = [[NSFileManager defaultManager] createDirectoryAtPath:directoryPath withIntermediateDirectories:YES attributes:nil error:&error];
        
        if (!isExist || error) {
            NSLog(@"VCLogWritter Create Directory Fail");
        }
    }
    
    return directoryPath;
}

- (NSString *)filePath {
    [self.lock lock];
    if (!_filePath) {
        _filePath = [self createFilePath];
    }
    [self.lock unlock];
    
    return _filePath;
}

- (BOOL)hasNextData {
    @synchronized (self.logWritterQueue) {
        return self.logWritterQueue.count > 0;
    }
}

- (unsigned long long)fileByteSize {
    return [[[NSFileManager defaultManager] attributesOfItemAtPath:self.filePath error:nil] fileSize];
}

@end
