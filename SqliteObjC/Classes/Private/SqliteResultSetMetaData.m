//
//  SqliteResultSetMetaData.m
//  SqliteObjC
//
//  Created by Archer on 2019/7/16.
//

#import "SqliteResultSetMetaData.h"
#import "SqliteConnection.h"

@implementation SqliteResultSetMetaData

- (instancetype)initWithStatement:(SqliteStatement *)statement {
    if ((self = [super init])) {
        _statement = statement;
        _columnCount = sqlite3_column_count(statement.pStmt);
        NSMutableDictionary *columnNameToIndexMap = @{}.mutableCopy;
        for (int i = 0; i < _columnCount; ++i) {
            NSString *key = [NSString stringWithUTF8String:sqlite3_column_name(statement.pStmt, i)];
            columnNameToIndexMap[key.lowercaseString] = @(i);
        }
        _columnNameToIndexMap = columnNameToIndexMap.copy;
    }
    return self;
}

- (NSInteger)columnIndexForName:(NSString *)columnName {
    NSNumber *index = _columnNameToIndexMap[columnName.lowercaseString];
    if (index) {
        return index.intValue;
    }
    // not found
    return -1;
}

- (NSString *)columnNameForIndex:(NSInteger)columnIdx {
    dispatch_semaphore_wait(_statement.connection.lock, DISPATCH_TIME_FOREVER);
    NSString *columnName = [NSString stringWithUTF8String:sqlite3_column_name(_statement.pStmt, (int)columnIdx)];
    dispatch_semaphore_signal(_statement.connection.lock);
    return columnName;
}

- (SQLiteColumnType)columnTypeForIndex:(NSInteger)columnIdx {
    dispatch_semaphore_wait(_statement.connection.lock, DISPATCH_TIME_FOREVER);
    int columnType = sqlite3_column_type(_statement.pStmt, (int)columnIdx);
    dispatch_semaphore_signal(_statement.connection.lock);
    switch (columnType) {
        case SQLITE_INTEGER:
            return SQLiteColumnTypeInteger;
        case SQLITE_FLOAT:
            return SQLiteColumnTypeFloat;
        case SQLITE_BLOB:
            return SQLiteColumnTypeBlob;
        case SQLITE_TEXT:
            return SQLiteColumnTypeText;
        case SQLITE_NULL:
            return SQLiteColumnTypeNull;
    }
    NSLog(@"WARNING: sqlite3 Can not determine column type.");
    return SQLiteColumnTypeNull;
}

@end
