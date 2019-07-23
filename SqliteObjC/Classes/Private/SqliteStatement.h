//
//  SqliteStatement.h
//  SqliteObjC
//
//  Created by Archer on 2019/7/16.
//

#import <Foundation/Foundation.h>
#import "Statement.h"
#import <sqlite3.h>

@class SqliteConnection;

NS_ASSUME_NONNULL_BEGIN

/**
 DO NOT USE.
 */
@interface SqliteStatement : NSObject <Statement>

@property (nonatomic, readonly, strong) SqliteConnection *connection;
@property (nullable, nonatomic, readonly, assign) sqlite3_stmt *pStmt;

- (void)prepareStatementIfNeeded:(NSString *)sql;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithConnection:(SqliteConnection *)connection;

@end

NS_ASSUME_NONNULL_END
