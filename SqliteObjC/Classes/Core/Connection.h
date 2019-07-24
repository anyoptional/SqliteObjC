//
//  Connection.h
//  SqliteObjC
//
//  Created by Archer on 2019/7/16.
//

#import <Foundation/Foundation.h>
#import "PreparedStatement.h"
#import "DatabaseMetaData.h"
#import "Statement.h"

NS_ASSUME_NONNULL_BEGIN

/**
 A connection  with a specific database. SQL statements are
 executed and results are returned within the context of a connection.
 */
@protocol Connection <NSObject>

/**
 Creates a Statement object for sending SQL statements
 to the database.
 SQL statements without parameters are normally executed
 using Statement objects.

 @return A new default Statement object.
 */
- (nullable id<Statement>)createStatement;

/**
 Retrieves a PreparedStatement object for sending parameterized
 SQL statements to the database.
 A SQL statement with or without IN parameters can be stored
 in a PreparedStatement object. This object can then be used
 to efficiently execute this statement multiple times.

 @param sql An SQL statement that may contain one or more '?'
 IN parameter placeholders
 @return A cached PreparedStatement object, if any, or a new default one.
 */
- (nullable id<PreparedStatement>)prepareStatement:(NSString *)sql;

/**
 Retrieves a `DatabaseMetaData` object that contains metadata about the
 database to which this `Connection` object represents a connection.
 */
@property (nonatomic, readonly, strong) id<DatabaseMetaData> metaData;

/**
 Opening a new database connection.
 
 The database is opened for reading and writing.
 
 @return `YES` if successful, `NO` on error.
 */
- (BOOL)open;

/**
 Releases this Connection object's database immediately.
 Calling the method `close` on a Connection object that is
 already closed is a no-op.

 @return `YES` if success, `NO` on error.
 */
- (BOOL)close;

/**
 Retrieves whether this Connection object has been closed.
 A connection is closed if the method `close` has been called
 on it or if certain fatal errors have occurred.
 */
@property (nonatomic, readonly, assign) BOOL isClosed;

/**
 Begin an exclusive transaction

 @return `YES` if success, `NO` on error.
 */
- (BOOL)beginTransaction;

/**
 Rollback a transaction that was initiated.

 @return `YES` if success, `NO` on error.
 */
- (BOOL)rollback;

/**
 Commit a transaction that was initiated.
 
 @return `YES` if success, `NO` on error.
 */
- (BOOL)commit;

/**
 Creates a savepoint with the given name in the current transaction.

 @param name Name of the save point.
 @return `YES` if success, `NO` on error.
 */
- (BOOL)setSavePoint:(NSString *)name;

/**
 Removes specified save point based on a name;

 @param name Name of the save point.
 @return `YES` if success, `NO` on error.
 */
- (BOOL)releaseSavePoint:(NSString *)name;

/**
 Undoes all changes made after the given save point
 was set.

 @param name Name of the save point.
 @return `YES` if success, `NO` on error.
 */
- (BOOL)rollbackToSavePoint:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
