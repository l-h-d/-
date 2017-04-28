//
//  TNDBBaseUtils.m
//  Pods
//
//  Created by l-h-d on 4/5/17.
//  Copyright © 2017 l-h-d. All rights reserved.
//

#import "TNDBBaseUtils.h"

@implementation TNDBBaseUtils

+ (id)strToData:(NSString *)str {
    if (str == nil) {
        return nil;
    }
    
    NSData *jsonData = [str dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err = nil;
    id value = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&err];
    return err == nil ? value : nil;
}

+ (NSString *)dataToStr:(id)value {
    NSError *parseError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:value options:NSJSONWritingPrettyPrinted error:&parseError];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

@end
