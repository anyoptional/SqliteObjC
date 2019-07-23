//
//  SqlitePreparedStatement.m
//  SqliteObjC
//
//  Created by Archer on 2019/7/16.
//

#import "SqlitePreparedStatement.h"
#import "SqliteConnection.h"
#import "SqliteResultSet.h"
#import <sqlite3.h>

@interface SqlitePreparedStatement ()
@property (nonatomic, readonly, strong) NSMutableDictionary<NSNumber *, id> *parameterIndexToValueMap;
@end

@implementation SqlitePreparedStatement

- (instancetype)initWithConnection:(SqliteConnection *)connection associatedQuery:(NSString *)sql {
    if (self = [super initWithConnection:connection]) {
        _sql = sql;
        _parameterIndexToValueMap = @{}.mutableCopy;
    }
    return self;
}

- (BOOL)close {
    [self clearParameters];
    return [super close];
}

- (void)setNull:(NSInteger)parameterIndex {
    dispatch_semaphore_wait(self.connection.lock, DISPATCH_TIME_FOREVER);
    self.parameterIndexToValueMap[@(parameterIndex)] = (id)kCFNull;
    dispatch_semaphore_signal(self.connection.lock);
}

- (void)setBOOL:(BOOL)value atIndex:(NSInteger)parameterIndex {
    dispatch_semaphore_wait(self.connection.lock, DISPATCH_TIME_FOREVER);
    self.parameterIndexToValueMap[@(parameterIndex)] = @(value);
    dispatch_semaphore_signal(self.connection.lock);
}

- (void)setInt:(int)value atIndex:(NSInteger)parameterIndex {
    dispatch_semaphore_wait(self.connection.lock, DISPATCH_TIME_FOREVER);
    self.parameterIndexToValueMap[@(parameterIndex)] = @(value);
    dispatch_semaphore_signal(self.connection.lock);
}

- (void)setLong:(long)value atIndex:(NSInteger)parameterIndex {
    dispatch_semaphore_wait(self.connection.lock, DISPATCH_TIME_FOREVER);
    self.parameterIndexToValueMap[@(parameterIndex)] = @(value);
    dispatch_semaphore_signal(self.connection.lock);
}

- (void)setDouble:(double)value atIndex:(NSInteger)parameterIndex {
    dispatch_semaphore_wait(self.connection.lock, DISPATCH_TIME_FOREVER);
    self.parameterIndexToValueMap[@(parameterIndex)] = @(value);
    dispatch_semaphore_signal(self.connection.lock);
}

- (void)setNumber:(NSNumber *)value atIndex:(NSInteger)parameterIndex {
    dispatch_semaphore_wait(self.connection.lock, DISPATCH_TIME_FOREVER);
    self.parameterIndexToValueMap[@(parameterIndex)] = value ? value : (id)kCFNull;
    dispatch_semaphore_signal(self.connection.lock);
}

- (void)setString:(NSString *)value atIndex:(NSInteger)parameterIndex {
    dispatch_semaphore_wait(self.connection.lock, DISPATCH_TIME_FOREVER);
    self.parameterIndexToValueMap[@(parameterIndex)] = value ? value : (id)kCFNull;
    dispatch_semaphore_signal(self.connection.lock);
}

- (void)setData:(NSData *)value atIndex:(NSInteger)parameterIndex {
    dispatch_semaphore_wait(self.connection.lock, DISPATCH_TIME_FOREVER);
    self.parameterIndexToValueMap[@(parameterIndex)] = value ? value : (id)kCFNull;
    dispatch_semaphore_signal(self.connection.lock);
}

- (void)setObject:(id)value atIndex:(NSInteger)parameterIndex {
    dispatch_semaphore_wait(self.connection.lock, DISPATCH_TIME_FOREVER);
    self.parameterIndexToValueMap[@(parameterIndex)] = value ? value : (id)kCFNull;
    dispatch_semaphore_signal(self.connection.lock);
}

- (void)clearParameters {
    dispatch_semaphore_wait(self.connection.lock, DISPATCH_TIME_FOREVER);
    [self.parameterIndexToValueMap removeAllObjects];
    dispatch_semaphore_signal(self.connection.lock);
}

- (BOOL)executeUpdate {
    dispatch_semaphore_wait(self.connection.lock, DISPATCH_TIME_FOREVER);
    NSArray *arguments = [self _prepareBindingArguments];
    dispatch_semaphore_signal(self.connection.lock);
    return [self executeUpdateWithArguments:arguments];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
- (BOOL)executeUpdate:(NSString *)sql {
    NSLog(@"WARNING: %s line:%d this method cannot be called on a PreparedStatement.", __FUNCTION__, __LINE__);
    [self doesNotRecognizeSelector:_cmd];
    return 0;
}
#pragma clang diagnostic pop

- (BOOL)executeUpdateWithArguments:(NSArray<id> *)arguments {
    SqliteResultSet *resultSet = (SqliteResultSet *)[self executeQueryWithArguments:arguments];
    if (!resultSet) return NO;
    int result = [resultSet step];
    // Do not close `ResultSet` here since we cached this statement
//    [resultSet close];
    if (result == SQLITE_DONE) {
        return YES;
    } else if (result == SQLITE_ROW) {
        NSLog(@"WARNING: %s line:%d please use executeQuery instead.", __FUNCTION__, __LINE__);
        return NO;
    }
    NSLog(@"WARNING: %s line:%d sqlite execute failed (%d).", __FUNCTION__, __LINE__, result);
    return NO;
}

- (id<ResultSet>)executeQuery {
    dispatch_semaphore_wait(self.connection.lock, DISPATCH_TIME_FOREVER);
    NSArray *arguments = [self _prepareBindingArguments];
    dispatch_semaphore_signal(self.connection.lock);
    return [self executeQueryWithArguments:arguments];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
- (id<ResultSet>)executeQuery:(NSString *)sql {
    NSLog(@"WARNING: %s line:%d this method cannot be called on a PreparedStatement.", __FUNCTION__, __LINE__);
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}
#pragma clang diagnostic pop

- (id<ResultSet>)executeQueryWithArguments:(NSArray<id> *)arguments {
    if (SQLiteConnectionIsClosed(self.connection)) return nil;
    dispatch_semaphore_wait(self.connection.lock, DISPATCH_TIME_FOREVER);
    [self prepareStatementIfNeeded:self.sql];
    int queryCount = sqlite3_bind_parameter_count(self.pStmt);
    int argumentCount = (int)arguments.count;
    if (queryCount != argumentCount) {
        NSLog(@"WARNING: %s line:%d Statement arguments count doesn't match given arguments count.", __FUNCTION__, __LINE__);
        dispatch_semaphore_signal(self.connection.lock);
        [self close];
        return nil;
    }
    for (int idx = 0; idx < queryCount; ++idx) {
        [self _bindObject:arguments[idx] toColumn:(idx + 1)];
    }
    dispatch_semaphore_signal(self.connection.lock);
    return [[SqliteResultSet alloc] initWithStatement:self];
}

- (NSArray<id> *)_prepareBindingArguments {
    NSInteger argumentsCount = self.parameterIndexToValueMap.count;
    NSMutableArray *arguments = [NSMutableArray arrayWithCapacity:argumentsCount];
    
    // after sorting, allKeys should be @[@(0), @(1), @(2)...]
    NSArray<NSNumber *> *allKeys = [self.parameterIndexToValueMap.allKeys sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [obj1 compare:obj2];
    }];
    
    for (NSInteger i = 0; i < allKeys.count; ++i) {
        if (allKeys[i].integerValue != i) {
            NSLog(@"WARNING: %s line:%d parameter index should be zero-based and reflect position of `?` placeholder.", __FUNCTION__, __LINE__);
            return nil;
        }
        arguments[allKeys[i].integerValue] = self.parameterIndexToValueMap[allKeys[i]];
    }

    return [arguments copy];
}

/**
 Note: sqlite3 query index binding is one-based, while querying result is zero-based.
 */
- (void)_bindObject:(id)obj toColumn:(int)idx {
    if ((!obj) || (obj == (id)kCFNull)) {
        sqlite3_bind_null(self.pStmt, idx);
    } else if ([obj isKindOfClass:NSData.class]) {
        const void *bytes = [obj bytes];
        if (!bytes) {
            // It's an empty NSData object, aka [NSData data].
            // Don't pass a NULL pointer, or sqlite will bind a SQL null instead of a blob.
            bytes = "";
        }
        sqlite3_bind_blob(self.pStmt, idx, bytes, (int)[obj length], SQLITE_TRANSIENT);
    } else if ([obj isKindOfClass:NSNumber.class]) {
        if (CFNumberIsFloatType((__bridge CFNumberRef)obj)) {
            sqlite3_bind_double(self.pStmt, idx, [obj doubleValue]);
        } else {
            sqlite3_bind_int64(self.pStmt, idx, [obj longLongValue]);
        }
    } else {
        if (![obj isKindOfClass:NSString.class]) {
            NSLog(@"WARNING: %s line:%d sqlite is binding unsupported type (%@) which will be turned to NSString object using [object description].", __FUNCTION__, __LINE__, [obj class]);
        }
        sqlite3_bind_text(self.pStmt, idx, [obj description].UTF8String, -1, SQLITE_TRANSIENT);
    }
}

@end
