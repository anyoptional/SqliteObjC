//
//  SqliteDatabaseMetaData.m
//  SqliteObjC
//
//  Created by Archer on 2019/7/24.
//

#import "SqliteDatabaseMetaData.h"
#import "PreparedStatement.h"
#import "SqliteConnection.h"
#import "ResultSet.h"

@implementation SqliteDatabaseMetaData

- (instancetype)initWithConnection:(SqliteConnection *)connection {
    if (self = [super init]) {
        _connection = connection;
    }
    return self;
}

- (NSString *)filePath {
    return _connection.databasePath;
}

- (NSArray<NSString *> *)columnsInTable:(NSString *)tableName {
    if (!tableName || tableName.length == 0) return @[];
    NSMutableArray *columns = @[].mutableCopy;
    id<Statement> stmt = [_connection createStatement];
    NSString *query = [NSString stringWithFormat:@"PRAGMA table_info('%@')", tableName];
    id<ResultSet> resultSet = [stmt executeQuery:query];
    while ([resultSet next]) {
        NSString *columnName = [resultSet stringForColumn:@"name"];
        if (columnName) { [columns addObject:columnName]; }
    }
    [resultSet close];
    return columns;
}

- (BOOL)tableExists:(NSString *)tableName {
    if (!tableName || tableName.length == 0) return NO;
    id<PreparedStatement> stmt = [_connection prepareStatement:@"SELECT [sql] FROM sqlite_master WHERE [type] = 'table' AND name = ?"];
    [stmt setString: tableName atIndex: 0];
    id<ResultSet> resultSet = [stmt executeQuery];
    BOOL result = [resultSet next];
    [resultSet close];
    return result;
}

@end
