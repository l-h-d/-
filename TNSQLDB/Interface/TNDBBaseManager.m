//
//  TNDBBaseManager.m
//  Pods
//
//  Created by l-h-d on 4/5/17.
//  Copyright © 2017 l-h-d. All rights reserved.
//

#import "TNDBBaseManager.h"
#import <FMDB/FMDatabaseAdditions.h>
#import <objc/runtime.h>
#import "TNDBBaseObject.h"
#import "TNDBBaseUtils.h"
#import "TNDBSortField.h"

#define kTNSQLDBExtension @".sqlite"

static id TNValueFromInvocation(id object, SEL selector) {
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[object methodSignatureForSelector:selector]];
    invocation.target = object;
    invocation.selector = selector;
    [invocation invoke];
    
    __unsafe_unretained id result = nil;
    [invocation getReturnValue:&result];
    return result;
}

@interface TNDBBaseManager()

@end

@implementation TNDBBaseManager

#pragma mark - Public Method
- (void)setupDBBaseManagerWithDBName:(NSString *)dbName withVersion:(NSString *)dbVersion withUId:(NSString *)uid withDelegate:(id<TNDBBaseManagerDelegate>)delegate {
    [_dbQueue close];
    _dbQueue = nil;
    
    NSString *libraryDirectory = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES).lastObject;
    NSString* dbPath = [NSString stringWithFormat:@"%@/TNDB/%@-%@%@", libraryDirectory, dbName, uid, kTNSQLDBExtension];
    if (![[NSFileManager defaultManager] fileExistsAtPath:dbPath]) {
        NSString *directoryPath = [dbPath substringToIndex:dbPath.length - [(NSString *)dbPath.pathComponents.lastObject length]];
        [[NSFileManager defaultManager] createDirectoryAtPath:directoryPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSLog(@"db manager %@ local path:%@", self.class, dbPath);
    _dbQueue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    
    __weak __typeof(self)weakSelf = self;
    __block NSInteger oldVersion = -1;
    NSArray *tableList = [delegate registerTableClasses];
    [_dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        NSMutableArray *createTableSql = [NSMutableArray array];
        for (Class tableClass in tableList) {
            if ([db tableExists:NSStringFromClass(tableClass)]) {
                continue;
            }
            [db executeUpdate:[weakSelf createTableSqlWithTableClass:tableClass]];
        }
    }];
}

- (void)saveItems:(NSArray<TNDBBaseObject *> *)items {
    __weak __typeof(self)weakSelf = self;
    __block BOOL isSuccess = YES;
    [_dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        for (id item in items) {
            isSuccess = [db executeUpdate:[weakSelf insertTableSqlWithItem:item]];
            if (!isSuccess) {
                break;
            }
        }
        if (!isSuccess) {
            *rollback = YES;
        }
    }];
}

- (void)updateItemsInTable:(Class)tableClass withContent:(NSDictionary *)content where:(NSString *)where, ...NS_REQUIRES_NIL_TERMINATION {
    if (tableClass == nil || content.count == 0 || where.length == 0) {
        return;
    }
    
    va_list args;
    va_start(args, where);
    NSString *updateConditionStr = [self conditionStr:where args:args];
    va_end(args);
    __weak __typeof(self)weakSelf = self;
    [_dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        *rollback = ![db executeUpdate:[weakSelf updateTableSqlWithTableClass:tableClass withContent:content where:updateConditionStr]];
    }];
}

- (void)deleteItemsInTable:(Class)tableClass where:(NSString *)where, ...NS_REQUIRES_NIL_TERMINATION {
    if (tableClass == nil) {
        return;
    }
    
    va_list args;
    va_start(args, where);
    NSString *deleteConditionStr = [self conditionStr:where args:args];
    va_end(args);
    __weak __typeof(self)weakSelf = self;
    [_dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        *rollback = ![db executeUpdate:[weakSelf deleteTableSqlWithTableClass:tableClass where:deleteConditionStr]];
    }];
}

- (void)deleteItemsInTable:(Class)tableClass withArgs:(NSArray<NSDictionary *> *)args {
    if (tableClass == nil || args.count == 0) {
        return;
    }
    
    __weak __typeof(self)weakSelf = self;
    [_dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        for (NSDictionary *dict in args) {
            [db executeUpdate:[weakSelf excuteTableSqlWithMethod:@"DELETE" withTableClass:tableClass withArg:dict]];
        }
    }];
}

- (NSArray<TNDBBaseObject *> *)queryItemsInTable:(Class)tableClass where:(NSString *)where, ...NS_REQUIRES_NIL_TERMINATION {
    NSMutableArray *resList = [NSMutableArray array];
    if (tableClass == nil) {
        return @[];
    }
    
    __weak __typeof(self)weakSelf = self;
    va_list args;
    va_start(args, where);
    NSString *querySqlStr = [weakSelf queryTableSqlWithTableClass:tableClass where:where args:args];
    va_end(args);
    [_dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs = [db executeQuery:querySqlStr];
        while ([rs next]){
            [resList addObject:[weakSelf parseOneRowToModelWithClass:tableClass withRs:rs]];
        }
    }];
    return resList;
}

- (NSArray<TNDBBaseObject *> *)queryItemsInTable:(Class)tableClass withArgs:(NSArray<NSDictionary *> *)args {
    if (tableClass == nil || args.count == 0) {
        return @[];
    }
    
    __weak __typeof(self)weakSelf = self;
    NSMutableArray *resList = [NSMutableArray array];
    [_dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        for (NSDictionary *dict in args) {
            FMResultSet *rs = [db executeQuery:[weakSelf excuteTableSqlWithMethod:@"SELECT *" withTableClass:tableClass withArg:dict]];
            while ([rs next]){
                [resList addObject:[weakSelf parseOneRowToModelWithClass:tableClass withRs:rs]];
            }
        }
    }];
    
    return resList;
}

- (NSArray<NSDictionary *> *)queryItemJSONInTable:(Class)tableClass where:(NSString *)where, ...NS_REQUIRES_NIL_TERMINATION {
    NSMutableArray *resList = [NSMutableArray array];
    if (tableClass == nil) {
        return @[];
    }
    
    __weak __typeof(self)weakSelf = self;
    va_list args;
    va_start(args, where);
    NSString *querySqlStr = [weakSelf queryTableSqlWithTableClass:tableClass where:where args:args];
    va_end(args);
    
    [_dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs = [db executeQuery:querySqlStr];
        while ([rs next]){
            [resList addObject:[weakSelf parseOneRowToJosonWithRs:rs]];
        }
    }];
    return resList;
}

- (NSArray<NSDictionary *> *)queryItemsInTables:(NSArray *)tableClasses tableFields:(NSArray *)tableFileds where:(NSString *)where, ...NS_REQUIRES_NIL_TERMINATION {
    NSMutableArray *resList = [NSMutableArray array];
    if (tableClasses.count == 0 || tableFileds.count == 0) {
        return @[];
    }
    
    __weak __typeof(self)weakSelf = self;
    va_list args;
    va_start(args, where);
    NSString *querySqlStr = [self queryMultibleTableSqlWithTableClasses:tableClasses tableFileds:tableFileds where:where args:args];
    va_end(args);
    
    [_dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs = [db executeQuery:querySqlStr];
        while ([rs next]){
            [resList addObject:[weakSelf parseOneRowToJosonWithRs:rs]];
        }
    }];
    return resList;
}

- (NSArray<NSDictionary *> *)queryItemsInTable:(NSArray *)tableClasses withTableFields:(NSArray *)tableFields withPre:(NSString *)pre withArgs:(NSArray<NSDictionary *> *)args {
    if (tableClasses == nil || args.count == 0) {
        return @[];
    }
    
    __weak __typeof(self)weakSelf = self;
    NSMutableArray *resList = [NSMutableArray array];
    [_dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        for (NSDictionary *dict in args) {
            FMResultSet *rs = [db executeQuery:[weakSelf queryTableSqlWithTableClasses:tableClasses withPre:pre withSelectFields:tableFields withArg:dict]];
            while ([rs next]){
                [resList addObject:[weakSelf parseOneRowToJosonWithRs:rs]];
            }
        }
    }];
    
    return resList;
}

- (NSArray<TNDBBaseObject *> *)queryItemsInTable:(Class)tableClass sortFields:(NSArray<TNDBSortField *> *)sortFields where:(NSString *)where, ...NS_REQUIRES_NIL_TERMINATION {
    NSMutableArray *resList = [NSMutableArray array];
    if (tableClass == nil) {
        return @[];
    }
    
    __weak __typeof(self)weakSelf = self;
    va_list args;
    va_start(args, where);
    NSString *querySqlStr = [weakSelf queryTableSqlWithTableClass:tableClass where:where args:args sortFields:sortFields];
    va_end(args);
    [_dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs = [db executeQuery:querySqlStr];
        while ([rs next]){
            [resList addObject:[weakSelf parseOneRowToModelWithClass:tableClass withRs:rs]];
        }
    }];
    return resList;
}

- (NSArray<NSDictionary *> *)queryItemJSONInTable:(Class)tableClass sortFields:(NSArray<TNDBSortField *> *)sortFields where:(NSString *)where, ...NS_REQUIRES_NIL_TERMINATION {
    NSMutableArray *resList = [NSMutableArray array];
    if (tableClass == nil) {
        return @[];
    }
    
    __weak __typeof(self)weakSelf = self;
    va_list args;
    va_start(args, where);
    NSString *querySqlStr = [weakSelf queryTableSqlWithTableClass:tableClass where:where args:args sortFields:sortFields];
    va_end(args);
    
    [_dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs = [db executeQuery:querySqlStr];
        while ([rs next]){
            [resList addObject:[weakSelf parseOneRowToJosonWithRs:rs]];
        }
    }];
    return resList;
}

- (NSArray<NSDictionary *> *)queryItemsInTables:(NSArray *)tableClasses tableFields:(NSArray *)tableFileds sortFields:(NSArray<TNDBSortField *> *)sortFields where:(NSString *)where, ...NS_REQUIRES_NIL_TERMINATION {
    NSMutableArray *resList = [NSMutableArray array];
    if (tableClasses.count == 0 || tableFileds.count == 0) {
        return @[];
    }
    
    __weak __typeof(self)weakSelf = self;
    va_list args;
    va_start(args, where);
    NSString *querySqlStr = [self queryMultibleTableSqlWithTableClasses:tableClasses tableFileds:tableFileds where:where args:args sortFields:sortFields];
    va_end(args);
    
    [_dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs = [db executeQuery:querySqlStr];
        while ([rs next]){
            [resList addObject:[weakSelf parseOneRowToJosonWithRs:rs]];
        }
    }];
    return resList;
}

#pragma mark - TNDBBaseManagerDelegate
- (NSArray *)registerTableClasses {
    return nil;
}

#pragma mark -
- (NSString *)createTableSqlWithTableClass:(Class)tableClass {
    NSAssert(tableClass != nil, nil);
    NSMutableString *createSqlMStr = [NSMutableString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (", tableClass];
    unsigned int outCount;
    Ivar * ivars = class_copyIvarList(tableClass, &outCount);
    NSDictionary *defaultValueDict = [self tableForDefaultValueWithTableClass:tableClass];
    for (int i = 0; i < outCount; i ++) {
        Ivar ivar = ivars[i];
        NSString * key = [NSString stringWithUTF8String:ivar_getName(ivar)] ;
        if([[key substringToIndex:1] isEqualToString:@"_"]){
            key = [key stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@""];
        }
        
        i != 0 ? [createSqlMStr appendFormat:@", %@",key] : [createSqlMStr appendFormat:@"%@", key];
        
        id defaultValue = defaultValueDict[key];
        if (defaultValue != nil) {
            if ([defaultValue isKindOfClass:[NSDictionary class]] || [defaultValue isKindOfClass:[NSMutableDictionary class]] || [defaultValue isKindOfClass:[NSArray class]] || [defaultValue isKindOfClass:[NSMutableArray class]]) {
                defaultValue = [TNDBBaseUtils dataToStr:defaultValue];
            } else if ([defaultValue isKindOfClass:[NSString class]]) {
                defaultValue = [defaultValue stringByReplacingOccurrencesOfString:@"'" withString:@"''"];
            }
            [createSqlMStr appendFormat:@" default '%@'",defaultValue];
        }
    }
    free(ivars);
    NSString *primaryKey = [self tableForPrimaryKeyWithTableClass:tableClass];
    NSAssert(primaryKey.length > 0, nil);
    [createSqlMStr appendFormat:@", PRIMARY KEY(%@)", primaryKey];
    [createSqlMStr appendString:@")"];
    return createSqlMStr;
}

- (NSString *)insertTableSqlWithItem:(id)item {
    NSMutableString *formatSqlMStr = [NSMutableString stringWithFormat:@"INSERT OR REPLACE INTO %@ (", [item class]];
    NSMutableString *valueSqlMStr = [NSMutableString stringWithString:@"VALUES ("];
    unsigned int outCount;
    Ivar * ivars = class_copyIvarList([item class], &outCount);
    for (int i = 0; i < outCount; i ++) {
        Ivar ivar = ivars[i];
        NSString * key = [NSString stringWithUTF8String:ivar_getName(ivar)] ;
        if([[key substringToIndex:1] isEqualToString:@"_"]){
            key = [key stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@""];
        }
        
        id value = [item valueForKey:key];
        if ([value isKindOfClass:[NSDictionary class]] || [value isKindOfClass:[NSMutableDictionary class]] || [value isKindOfClass:[NSArray class]] || [value isKindOfClass:[NSMutableArray class]]) {
            value = [TNDBBaseUtils dataToStr:value];
        } else if ([value isKindOfClass:[NSString class]]) {
            value = [value stringByReplacingOccurrencesOfString:@"'" withString:@"''"];
        }
        
        if (i == 0) {
            [formatSqlMStr appendString:key];
            [valueSqlMStr appendFormat:@"%@", [value isKindOfClass:[NSString class]] ? [NSString stringWithFormat:@"'%@'", value] : value];
        } else {
            [formatSqlMStr appendFormat:@", %@", key];
            [valueSqlMStr appendFormat:@", %@", [value isKindOfClass:[NSString class]] ? [NSString stringWithFormat:@"'%@'", value] : value];
        }
    }
    
    free(ivars);
    
    [formatSqlMStr appendString:@") "];
    [formatSqlMStr appendString:valueSqlMStr];
    [formatSqlMStr appendString:@");"];
    
    return formatSqlMStr;
}

- (NSString *)updateTableSqlWithTableClass:(Class)tableClass withContent:(NSDictionary *)content where:(NSString *)where {
    NSMutableString *updateSqlMStr = [NSMutableString stringWithFormat:@"UPDATE %@ SET ", tableClass];
    NSArray *allKeys = content.allKeys;
    NSInteger updateCount = 0;
    unsigned int outCount;
    Ivar * ivars = class_copyIvarList([tableClass class], &outCount);
    for (int i = 0; i < outCount; i ++) {
        Ivar ivar = ivars[i];
        NSString * key = [NSString stringWithUTF8String:ivar_getName(ivar)] ;
        if([[key substringToIndex:1] isEqualToString:@"_"]){
            key = [key stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@""];
        }
        
        if (![allKeys containsObject:key]) {
            continue;
        }
        
        id value = content[key];
        if ([value isKindOfClass:[NSDictionary class]] || [value isKindOfClass:[NSMutableDictionary class]] || [value isKindOfClass:[NSArray class]] || [value isKindOfClass:[NSMutableArray class]]) {
            value = [TNDBBaseUtils dataToStr:value];
        } else if ([value isKindOfClass:[NSString class]]) {
            value = [value stringByReplacingOccurrencesOfString:@"'" withString:@"''"];
        }
        
        updateCount != 0 ? [updateSqlMStr appendFormat:@",%@ = '%@'", key, value] : [updateSqlMStr appendFormat:@"%@ = '%@'", key, value];
        
        updateCount++;
        if (updateCount >= allKeys.count) {
            break;
        }
    }
    
    free(ivars);
    [updateSqlMStr appendFormat:@" WHERE %@;", where];
    return updateSqlMStr;
}

- (NSString *)deleteTableSqlWithTableClass:(Class)tableClass where:(NSString *)where {
    return where.length > 0 ? [NSString stringWithFormat:@"DELETE FROM %@ WHERE  %@;", tableClass, where] : [NSString stringWithFormat:@"DELETE FROM %@;", tableClass];
}

- (NSString *)excuteTableSqlWithMethod:(NSString *)method withTableClass:(Class)tableClass withArg:(NSDictionary *)arg {
    NSMutableString *querySqlMStr = [NSMutableString stringWithFormat:@"%@ FROM %@ WHERE ", method, NSStringFromClass(tableClass)];
    NSArray *allKeys = arg.allKeys;
    for (NSInteger i = 0; i < allKeys.count; i++) {
        NSString *key = allKeys[i];
        id value = arg[key];
        if ([value isKindOfClass:[NSDictionary class]] || [value isKindOfClass:[NSMutableDictionary class]] || [value isKindOfClass:[NSArray class]] || [value isKindOfClass:[NSMutableArray class]]) {
            value = [TNDBBaseUtils dataToStr:value];
        } else if ([value isKindOfClass:[NSString class]]) {
            value = [value stringByReplacingOccurrencesOfString:@"'" withString:@"''"];
        }
        i == 0 ? [querySqlMStr appendFormat:@"%@ = '%@'", key, value] : [querySqlMStr appendFormat:@" AND %@ = '%@'", key, value];
    }
    [querySqlMStr appendString:@";"];
    return querySqlMStr;
}

- (NSString *)queryTableSqlWithTableClasses:(NSArray *)tableClasses withPre:(NSString *)pre withSelectFields:(NSArray *)selectFields withArg:(NSDictionary *)arg {
    NSMutableString *querySqlMStr = [NSMutableString stringWithFormat:@"SELECT %@ FROM %@", [selectFields componentsJoinedByString:@","], [tableClasses componentsJoinedByString:@","]];
    if (arg.count > 0 || pre.length > 0) {
        [querySqlMStr appendString:@" WHERE "];
        pre.length > 0 ? [querySqlMStr appendFormat:@"%@ ", pre] : nil;
    }
    
    NSArray *allKeys = arg.allKeys;
    for (NSInteger i = 0; i < allKeys.count; i++) {
        NSString *key = allKeys[i];
        id value = arg[key];
        if ([value isKindOfClass:[NSDictionary class]] || [value isKindOfClass:[NSMutableDictionary class]] || [value isKindOfClass:[NSArray class]] || [value isKindOfClass:[NSMutableArray class]]) {
            value = [TNDBBaseUtils dataToStr:value];
        } else if ([value isKindOfClass:[NSString class]]) {
            value = [value stringByReplacingOccurrencesOfString:@"'" withString:@"''"];
        }
        (i == 0 && pre.length == 0) ? [querySqlMStr appendFormat:@"%@ = '%@'", key, value] : [querySqlMStr appendFormat:@" AND %@ = '%@'", key, value];
    }
    [querySqlMStr appendString:@";"];
    return querySqlMStr;
}

- (NSString *)queryTableSqlWithTableClass:(Class)tableClass where:(NSString *)where args:(va_list)args {
    return where.length > 0 ? [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@;", tableClass, [self conditionStr:where args:args]] : [NSString stringWithFormat:@"SELECT * FROM %@;", tableClass];
}

- (NSString *)queryMultibleTableSqlWithTableClasses:(NSArray *)tableClasses tableFileds:(NSArray *)fileds where:(NSString *)where args:(va_list)args {
    NSMutableArray *tableStrList = [NSMutableArray array];
    for (Class class in tableClasses) {
        [tableStrList addObject:NSStringFromClass(class)];
    }
    
    NSMutableString *querySqlMStr = [NSMutableString stringWithFormat:@"SELECT %@ FROM %@", [fileds componentsJoinedByString:@","], [tableStrList componentsJoinedByString:@","]];
    where.length > 0 ? [querySqlMStr appendFormat:@" WHERE %@;", [self conditionStr:where args:args]] : [querySqlMStr appendString:@";"];
    return querySqlMStr;
}

- (NSString *)queryTableSqlWithTableClass:(Class)tableClass where:(NSString *)where args:(va_list)args sortFields:(NSArray<TNDBSortField *> *)sortFields {
    NSString *querySqlStr = where.length > 0 ? [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@", tableClass, [self conditionStr:where args:args]] : [NSString stringWithFormat:@"SELECT * FROM %@", tableClass];
    NSInteger sortFieldsCount = sortFields.count;
    if (sortFieldsCount > 0) {
        NSMutableString *sortSqlMStr = [NSMutableString stringWithString:@" ORDER BY "];
        for (NSInteger i = 0; i < sortFieldsCount; i++) {
            TNDBSortField *field = sortFields[i];
            i != 0 ? [sortSqlMStr appendFormat:@",%@ %@", field.fieldName, field.ascing ? @"ASC" : @"DESC"] : [sortSqlMStr appendFormat:@"%@ %@", field.fieldName, field.ascing ? @"ASC" : @"DESC"];
        }
        querySqlStr = [querySqlStr stringByAppendingString:sortSqlMStr];
    }
    querySqlStr = [querySqlStr stringByAppendingString:@";"];
    return querySqlStr;
}

- (NSString *)queryMultibleTableSqlWithTableClasses:(NSArray *)tableClasses tableFileds:(NSArray *)fileds where:(NSString *)where args:(va_list)args sortFields:(NSArray<TNDBSortField *> *)sortFields {
    NSMutableArray *tableStrList = [NSMutableArray array];
    for (Class class in tableClasses) {
        [tableStrList addObject:NSStringFromClass(class)];
    }
    
    NSMutableString *querySqlMStr = [NSMutableString stringWithFormat:@"SELECT %@ FROM %@", [fileds componentsJoinedByString:@","], [tableStrList componentsJoinedByString:@","]];
    where.length > 0 ? [querySqlMStr appendFormat:@" WHERE %@", [self conditionStr:where args:args]] : [querySqlMStr appendString:@""];
    NSInteger sortFieldsCount = sortFields.count;
    if (sortFieldsCount > 0) {
        NSMutableString *sortSqlMStr = [NSMutableString stringWithString:@" ORDER BY "];
        for (NSInteger i = 0; i < sortFieldsCount; i++) {
            TNDBSortField *field = sortFields[i];
            i != 0 ? [sortSqlMStr appendFormat:@",%@ %@", field.fieldName, field.ascing ? @"ASC" : @"DESC"] : [sortSqlMStr appendFormat:@"%@ %@", field.fieldName, field.ascing ? @"ASC" : @"DESC"];
        }
        [querySqlMStr appendString:sortSqlMStr];
    }
    [querySqlMStr appendString:@";"];
    return querySqlMStr;
}

- (NSString *)conditionStr:(NSString *)str args:(va_list)args {
    if (str.length == 0) {
        return @"";
    }
    
    NSMutableArray *argList = [str componentsSeparatedByString:@"%@"];
    NSMutableString *formatStr = [NSMutableString string];
    [formatStr appendString:argList[0]];
    if (str) {
        id arg = va_arg(args, NSObject *);
        NSInteger i = 0;
        while (arg) {
            if ([arg isKindOfClass:[NSArray class]]) {
                [formatStr appendString:@"('"];
                [formatStr appendFormat:[(NSArray *)arg componentsJoinedByString:@"','"]];
                [formatStr appendString:@"')"];
            } else if ([arg isKindOfClass:[NSString class]]) {
                arg = [arg stringByReplacingOccurrencesOfString:@"'" withString:@"''"];
                [formatStr appendFormat:@"%@", arg];
            } else {
                [formatStr appendFormat:@"%@", arg];
            }
            
            arg = va_arg(args, NSObject *);
            i++;
            NSAssert(argList.count >= i, nil);
            [formatStr appendString:argList[i]];
        }
    }
    return formatStr;
}

#pragma mark - PrimaryKey
- (NSString *)tableForPrimaryKeyWithTableClass:(Class)tableClass {
    return TNValueFromInvocation(tableClass, NSSelectorFromString(@"primaryKey"));
}

#pragma mark - DefaultValues
- (NSDictionary *)tableForDefaultValueWithTableClass:(Class)tableClass {
    return TNValueFromInvocation(tableClass, NSSelectorFromString(@"defaultPropertyValues"));
}

#pragma mark - Parsel Fields To Moel
- (id)parseOneRowToModelWithClass:(Class)tableClass withRs:(FMResultSet *)rs {
    id object = [tableClass new];
    unsigned int outCount;
    Ivar * ivars = class_copyIvarList(tableClass, &outCount);
    for (int i = 0; i < outCount; i ++) {
        Ivar ivar = ivars[i];
        NSString * key = [NSString stringWithUTF8String:ivar_getName(ivar)] ;
        if([[key substringToIndex:1] isEqualToString:@"_"]){
            key = [key stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@""];
        }
        
        id value = [rs objectForColumnName:key];
        if ([value isKindOfClass:[NSString class]]) {
            id result = [TNDBBaseUtils strToData:value];
            if ([result isKindOfClass:[NSDictionary class]] || [result isKindOfClass:[NSMutableDictionary class]] || [result isKindOfClass:[NSArray class]] || [result isKindOfClass:[NSMutableArray class]]) {
                result != [NSNull null] ? [object setValue:result forKey:key] : nil;
            } else {
                value != [NSNull null] ? [object setValue:value forKey:key] : nil;
            }
        } else {
            value != [NSNull null] ? [object setValue:value forKey:key] : nil;
        }
    }
    free(ivars);
    return object;
}

- (NSDictionary *)parseOneRowToJosonWithRs:(FMResultSet *)rs {
    NSMutableDictionary *object = [NSMutableDictionary new];
    for (int i = 0; i < rs.columnCount; i++) {
        NSString *key = [rs columnNameForIndex:i];
        id value = [rs objectForColumnName:key];
        if ([value isKindOfClass:[NSString class]]) {
            id result = [TNDBBaseUtils strToData:value];
            if ([result isKindOfClass:[NSDictionary class]] || [result isKindOfClass:[NSMutableDictionary class]] || [result isKindOfClass:[NSArray class]] || [result isKindOfClass:[NSMutableArray class]]) {
                result != [NSNull null] ? [object setValue:result forKey:key] : nil;
            } else {
                value != [NSNull null] ? [object setValue:value forKey:key] : nil;
            }
        } else {
            value != [NSNull null] ? [object setValue:value forKey:key] : nil;
        }
    }
    
    return object;
}
#pragma mark - Dealloc
- (void)dealloc {
    [_dbQueue close];
    _dbQueue = nil;
}
@end
