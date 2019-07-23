//
//  SqliteResultSet.m
//  SqliteObjC
//
//  Created by Archer on 2019/7/16.
//

#import "SqliteResultSetMetaData.h"
#import "SqliteConnection.h"
#import "SqliteResultSet.h"
#import "SqliteStatement.h"
#import <sqlite3.h>

@implementation SqliteResultSet

- (instancetype)initWithStatement:(SqliteStatement *)statement {
    if ((self = [super init])) {
        _statement = statement;
        _metaData = [[SqliteResultSetMetaData alloc] initWithStatement:statement];
    }
    return self;
}

- (BOOL)next {
    return [self step] == SQLITE_ROW;
}

- (int)step {
    dispatch_semaphore_wait(_statement.connection.lock, DISPATCH_TIME_FOREVER);
    int result = sqlite3_step(_statement.pStmt);
    dispatch_semaphore_signal(_statement.connection.lock);
    return result;
}

- (void)close {
    [_statement close];
}

- (int)intForColumn:(NSString *)columnName {
    return [self intForColumnIndex:[self columnIndexForName:columnName]];
}

- (int)intForColumnIndex:(NSInteger)columnIndex {
    dispatch_semaphore_wait(_statement.connection.lock, DISPATCH_TIME_FOREVER);
    int value = sqlite3_column_int(_statement.pStmt, (int)columnIndex);
    dispatch_semaphore_signal(_statement.connection.lock);
    return value;
}

- (long)longForColumn:(NSString *)columnName {
    return [self longForColumnIndex:[self columnIndexForName:columnName]];
}

- (long)longForColumnIndex:(NSInteger)columnIndex {
    dispatch_semaphore_wait(_statement.connection.lock, DISPATCH_TIME_FOREVER);
    long value = (long)sqlite3_column_int64(_statement.pStmt, (int)columnIndex);
    dispatch_semaphore_signal(_statement.connection.lock);
    return value;
}

- (BOOL)boolForColumn:(NSString *)columnName {
    return [self boolForColumnIndex:[self columnIndexForName:columnName]];
}

- (BOOL)boolForColumnIndex:(NSInteger)columnIndex {
    return [self intForColumnIndex:columnIndex] != 0;
}

- (double)doubleForColumn:(NSString *)columnName {
    return [self doubleForColumnIndex:[self columnIndexForName:columnName]];
}

- (double)doubleForColumnIndex:(NSInteger)columnIndex {
    dispatch_semaphore_wait(_statement.connection.lock, DISPATCH_TIME_FOREVER);
    double value = sqlite3_column_double(_statement.pStmt, (int)columnIndex);
    dispatch_semaphore_signal(_statement.connection.lock);
    return value;
}

- (NSString *)stringForColumn:(NSString *)columnName {
    return [self stringForColumnIndex:[self columnIndexForName:columnName]];
}

- (NSString *)stringForColumnIndex:(NSInteger)columnIndex {
    if ([self columnIndexIsNull:columnIndex]) {
        return nil;
    }
    dispatch_semaphore_wait(_statement.connection.lock, DISPATCH_TIME_FOREVER);
    const char *str = (const char *)sqlite3_column_text(_statement.pStmt, (int)columnIndex);
    if (!str) {
        dispatch_semaphore_signal(_statement.connection.lock);
        return nil;
    }
    dispatch_semaphore_signal(_statement.connection.lock);
    return [NSString stringWithUTF8String:str];
}

- (NSData *)dataForColumn:(NSString *)columnName {
    return [self dataForColumnIndex:[self columnIndexForName:columnName]];
}

- (NSData *)dataForColumnIndex:(NSInteger)columnIndex {
    if ([self columnIndexIsNull:columnIndex]) {
        return nil;
    }
    dispatch_semaphore_wait(_statement.connection.lock, DISPATCH_TIME_FOREVER);
    int size = sqlite3_column_bytes(_statement.pStmt, (int)columnIndex);
    const char *buffer = sqlite3_column_blob(_statement.pStmt, (int)columnIndex);
    if (buffer == nil) {
        dispatch_semaphore_signal(_statement.connection.lock);
        return nil;
    }
    dispatch_semaphore_signal(_statement.connection.lock);
    return [NSData dataWithBytes:buffer length:size];
}

- (id)objectForColumn:(NSString *)columnName {
    return [self objectForColumnIndex:[self columnIndexForName:columnName]];
}

- (id)objectForColumnIndex:(NSInteger)columnIndex {
    dispatch_semaphore_wait(_statement.connection.lock, DISPATCH_TIME_FOREVER);
    int columnType = sqlite3_column_type(_statement.pStmt, (int)columnIndex);
    dispatch_semaphore_signal(_statement.connection.lock);
    switch (columnType) {
        case SQLITE_INTEGER:
            return @([self longForColumnIndex:columnIndex]);
        case SQLITE_FLOAT:
            return @([self doubleForColumnIndex:columnIndex]);
        case SQLITE_BLOB:
            return [self dataForColumnIndex:columnIndex];
        default:
            return [self stringForColumnIndex:columnIndex];
    }
}

- (BOOL)columnIsNull:(NSString *)columnName {
    return [self columnIndexIsNull:[self columnIndexForName:columnName]];
}

- (BOOL)columnIndexIsNull:(NSInteger)columnIndex {
    dispatch_semaphore_wait(_statement.connection.lock, DISPATCH_TIME_FOREVER);
    BOOL isNull = (sqlite3_column_type(_statement.pStmt, (int)columnIndex) == SQLITE_NULL);
    dispatch_semaphore_signal(_statement.connection.lock);
    return isNull;
}

- (int)columnIndexForName:(NSString *)columnName {
    SqliteResultSetMetaData *metaData = (SqliteResultSetMetaData *)_metaData;
    return (int)[metaData columnIndexForName:columnName];
}

@end
