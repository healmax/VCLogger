//
//  NSMutableArray+VCQueueAdditions.m
//  VCLogger
//
//  Created by healmax healmax on 2019/2/5.
//  Copyright © 2019 com.healmax. All rights reserved.
//

#import "NSMutableArray+VCQueueAdditions.h"

@implementation NSMutableArray (VCQueueAdditions)

- (void)enqueueObjectsFromArray:(NSArray *)otherArray {
    [self addObjectsFromArray:otherArray];
}

- (void)enqueue:(id)object {
    [self addObject:object];
}

- (id)dequeue {
    id objecct = [self objectAtIndex:0];
    if (objecct) {
        [self removeObjectAtIndex:0];
    }
    
    return objecct;
}

@end
