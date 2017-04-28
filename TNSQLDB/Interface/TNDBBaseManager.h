//
//  TNDBBaseManager.h
//  Pods
//
//  Created by l-h-d on 4/5/17.
//
//

#import <Foundation/Foundation.h>
#import <FMDB/FMDatabaseQueue.h>

@protocol TNDBBaseManagerDelegate <NSObject>
@required
- (NSArray *)registerTableClasses;
@end

@class TNDBBaseObject;
@class TNDBSortField;

@interface TNDBBaseManager : NSObject

@property(nonatomic, strong, readonly) FMDatabaseQueue *dbQueue;

- (void)setupDBBaseManagerWithDBName:(NSString *)dbName withVersion:(NSString *)dbVersion withUId:(NSString *)uid withDelegate:(id<TNDBBaseManagerDelegate>)delegate;

- (void)saveItems:(NSArray<TNDBBaseObject *> *)items;

//where only support object, not base type
- (void)updateItemsInTable:(Class)tableClass withContent:(NSDictionary *)content where:(NSString *)where, ...NS_REQUIRES_NIL_TERMINATION;

- (void)deleteItemsInTable:(Class)tableClass where:(NSString *)where, ...NS_REQUIRES_NIL_TERMINATION;
- (void)deleteItemsInTable:(Class)tableClass withArgs:(NSArray<NSDictionary *> *)args;

- (NSArray<TNDBBaseObject *> *)queryItemsInTable:(Class)tableClass where:(NSString *)where, ...NS_REQUIRES_NIL_TERMINATION;
- (NSArray<NSDictionary *> *)queryItemJSONInTable:(Class)tableClass where:(NSString *)where, ...NS_REQUIRES_NIL_TERMINATION;
- (NSArray<TNDBBaseObject *> *)queryItemsInTable:(Class)tableClass withArgs:(NSArray<NSDictionary *> *)args;

- (NSArray<NSDictionary *> *)queryItemsInTables:(NSArray *)tableClasses tableFields:(NSArray *)tableFileds where:(NSString *)where, ...NS_REQUIRES_NIL_TERMINATION;
- (NSArray<NSDictionary *> *)queryItemsInTable:(NSArray *)tableClasses withTableFields:(NSArray *)tableFields withPre:(NSString *)pre withArgs:(NSArray<NSDictionary *> *)args;

- (NSArray<TNDBBaseObject *> *)queryItemsInTable:(Class)tableClass sortFields:(NSArray<TNDBSortField *> *)sortFields where:(NSString *)where, ...NS_REQUIRES_NIL_TERMINATION;
- (NSArray<NSDictionary *> *)queryItemJSONInTable:(Class)tableClass sortFields:(NSArray<TNDBSortField *> *)sortFields where:(NSString *)where, ...NS_REQUIRES_NIL_TERMINATION;
- (NSArray<NSDictionary *> *)queryItemsInTables:(NSArray *)tableClasses tableFields:(NSArray *)tableFileds sortFields:(NSArray<TNDBSortField *> *)sortFields where:(NSString *)where, ...NS_REQUIRES_NIL_TERMINATION;
@end
