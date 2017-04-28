//
//  TNDBBaseObject.m
//  Pods
//
//  Created by l-h-d on 4/5/17.
//  Copyright © 2017 l-h-d. All rights reserved.
//

#import "TNDBBaseObject.h"
#import <objc/runtime.h>

@implementation TNDBBaseObject

- (id)init {
    if (self = [super init]) {
        [self setupModelDefaultValue];
    }
    return self;
}

- (void)setupModelDefaultValue {
    NSDictionary *defaultValueDict = [self.class defaultPropertyValues];
    if (defaultValueDict.allValues.count == 0) {
        return;
    }
    
    unsigned int outCount;
    Ivar * ivars = class_copyIvarList(self.class, &outCount);
    for (int i = 0; i < outCount; i ++) {
        Ivar ivar = ivars[i];
        NSString * key = [NSString stringWithUTF8String:ivar_getName(ivar)] ;
        if([[key substringToIndex:1] isEqualToString:@"_"]){
            key = [key stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@""];
        }
        
        id defaultValue = defaultValueDict[key];
        defaultValue != nil ? [self setValue:defaultValue forKey:key] : nil;
    }
    free(ivars);
}

#pragma mark - Table Constraint
+ (NSString *)primaryKey {
    return nil;
}

+ (NSDictionary *)defaultPropertyValues {
    return nil;
}

@end
