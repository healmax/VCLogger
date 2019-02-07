//
//  NSMutableArray+VCQueueAdditions.h
//  VCLogger
//
//  Created by healmax healmax on 2019/2/5.
//  Copyright © 2019 com.healmax. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSMutableArray (VCQueueAdditions)

- (void)enqueue:(id)object;
- (void)enqueueObjectsFromArray:(NSArray *)otherArray;
- (id)dequeue;

@end

NS_ASSUME_NONNULL_END
