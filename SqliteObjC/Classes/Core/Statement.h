//
//  Statement.h
//  SqliteObjC
//
//  Created by Archer on 2019/7/16.
//

#import <Foundation/Foundation.h>
#import "ResultSet.h"

NS_ASSUME_NONNULL_BEGIN

/**
 The object used for executing a static SQL statement
 and returning the results it produces.
 */
@protocol Statement <NSObject>

/**
 Executes the given SQL statement, which may be an INSERT, UPDATE,
 or DELETE statement or an SQL statement that returns nothing,
 such as an SQL DDL statement.

 @param sql an SQL Data Manipulation Language (DML) statement, such as
 INSERT, UPDATE or DELETE; or an SQL statement that returns nothing,
 such as a DDL statement.
 @return `YES` if successful, `NO` on error.

 NOTE: This method cannot be called on a PreparedStatement.
 */
- (BOOL)executeUpdate:(NSString *)sql;

/**
 The number of rows changed by prior SQL statement.
 
 This function returns the number of database rows that were changed or
 inserted or deleted by the most recently completed SQL statement on the
 database connection specified by the first parameter.
 Only changes that are directly specified by the INSERT, UPDATE, or DELETE statement are counted.
 */
@property (nonatomic, readonly, assign) NSInteger changes;

/**
 Executes the given SQL statement, which returns a single
 ResultSet object.

 @param sql An SQL statement to be sent to the database, typically a
 static SQL SELECT statement.
 @return A ResultSet object that contains the data produced by the
 given query.
 
 NOTE: This method cannot be called on a PreparedStatement.
 */
- (nullable id<ResultSet>)executeQuery:(NSString *)sql;

/**
 Releases this Statement object's database.
 It is generally good practice to release resources as soon as
 you are finished with them to avoid tying up database resources.

 @return `YES` if successful, `NO` on error.
 */
- (BOOL)close;

/**
 Retrieves whether this Statement object has been closed. A Statement is closed
 if the method `close` has been called on it, or if it is never opened before.
 */
@property (nonatomic, readonly, assign) BOOL isClosed;

@end

NS_ASSUME_NONNULL_END
