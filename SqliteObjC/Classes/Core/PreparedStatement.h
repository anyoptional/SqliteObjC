//
//  PreparedStatement.h
//  SqliteObjC
//
//  Created by Archer on 2019/7/16.
//

#import <Foundation/Foundation.h>
#import "Statement.h"

NS_ASSUME_NONNULL_BEGIN

/**
 An object that represents a precompiled SQL statement.
 A SQL statement is precompiled and stored in a PreparedStatement object.
 This object can then be used to efficiently execute this statement multiple times.
 */
@protocol PreparedStatement <Statement>

/**
 Sets the designated parameter to SQL NULL.

 @param parameterIndex Zero-based index for parameter
 */
- (void)setNull:(NSInteger)parameterIndex;

/**
 Sets the designated parameter to the given ObjC BOOL value.
 The underlying database implementation converts this to a
 NSNumber when it sends it to the database.

 @param value The parameter value
 @param parameterIndex Zero-based index for parameter
 */
- (void)setBOOL:(BOOL)value atIndex:(NSInteger)parameterIndex;

/**
 Sets the designated parameter to the given ObjC int value.
 The underlying database implementation converts this to a
 NSNumber when it sends it to the database.
 
 @param value The parameter value
 @param parameterIndex Zero-based index for parameter
 */
- (void)setInt:(int)value atIndex:(NSInteger)parameterIndex;

/**
 Sets the designated parameter to the given ObjC long value.
 The underlying database implementation converts this to a
 NSNumber when it sends it to the database.
 
 @param value The parameter value
 @param parameterIndex Zero-based index for parameter
 */
- (void)setLong:(long)value atIndex:(NSInteger)parameterIndex;

/**
 Sets the designated parameter to the given ObjC double value.
 The underlying database implementation converts this to a
 NSNumber when it sends it to the database.
 
 @param value The parameter value
 @param parameterIndex Zero-based index for parameter
 */
- (void)setDouble:(double)value atIndex:(NSInteger)parameterIndex;

/**
 Sets the designated parameter to the given ObjC NSNumber object.

 @param value The parameter value
 @param parameterIndex Zero-based index for parameter
 */
- (void)setNumber:(nullable NSNumber *)value atIndex:(NSInteger)parameterIndex;

/**
 Sets the designated parameter to the given ObjC NSString object.
 
 @param value The parameter value
 @param parameterIndex Zero-based index for parameter
 */
- (void)setString:(nullable NSString *)value atIndex:(NSInteger)parameterIndex;

/**
 Sets the designated parameter to the given ObjC NSData object.
 
 @param value The parameter value
 @param parameterIndex Zero-based index for parameter
 */
- (void)setData:(nullable NSData *)value atIndex:(NSInteger)parameterIndex;

/**
 Sets the designated parameter to the given ObjC object.
 
 @param value The parameter value
 @param parameterIndex Zero-based index for parameter
 */
- (void)setObject:(nullable id)value atIndex:(NSInteger)parameterIndex;

/**
 Clears the current parameter values immediately.
 In general, parameter values remain in force for repeated use of a
 statement.
 */
- (void)clearParameters;

/**
 Executes the given SQL statement, which may be an INSERT, UPDATE,
 or DELETE statement or an SQL statement that returns nothing,
 such as an SQL DDL statement.

 @return `YES` if successful, `NO` on error.
  */
- (BOOL)executeUpdate;

/**
 Executing queries returns an ResultSet object if successful, and `nil` upon failure.
 In order to iterate through the results of your query, you use a `while()` loop.
 You also need to "step" (via `[ResultSet next]`) from one record to the other.

 @return A ResultSet object that contains the data produced by the
 given query.
 */
- (nullable id<ResultSet>)executeQuery;

- (BOOL)executeUpdate:(NSString *)sql NS_UNAVAILABLE;
- (nullable id<ResultSet>)executeQuery:(NSString *)sql NS_UNAVAILABLE;

#pragma mark - Convenience standalone execution methods

/**
 Executes the given SQL statement, which may be an INSERT, UPDATE,
 or DELETE statement or an SQL statement that returns nothing,
 such as an SQL DDL statement.
 
 @param arguments A `NSArray` of objects to be used when binding values
 to the `?` placeholders in the SQL statement.
 @return `YES` if successful, `NO` on error.
 
 NOTE: `Arguments` will not be retained, any further call to `executeUpdate`
 method will NOT uses this `arguments`.
 */
- (BOOL)executeUpdateWithArguments:(NSArray<id> *)arguments NS_SWIFT_NAME(executeUpdate(_:));

/**
 Executing queries returns an ResultSet object if successful, and `nil` upon failure.
 In order to iterate through the results of your query, you use a `while()` loop.
 You also need to "step" (via `[ResultSet next]`) from one record to the other.

 @param arguments A `NSArray` of objects to be used when binding values
 to the `?` placeholders in the SQL statement.
 @return A ResultSet object that contains the data produced by the
 given query.

 NOTE: `Arguments` will not be retained, any further call to `executeUpdate`
 method will NOT uses this `arguments`.
 */
- (nullable id<ResultSet>)executeQueryWithArguments:(NSArray<id> *)arguments NS_SWIFT_NAME(executeQuery(_:));

@end

NS_ASSUME_NONNULL_END
