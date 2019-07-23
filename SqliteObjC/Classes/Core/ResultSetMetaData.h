//
//  ResultSetMetaData.h
//  SqliteObjC
//
//  Created by Archer on 2019/7/16.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Supported column types defined by sqlite3.
 */
typedef NS_ENUM(NSInteger, SQLiteColumnType) {
    SQLiteColumnTypeNull,
    SQLiteColumnTypeBlob,
    SQLiteColumnTypeText,
    SQLiteColumnTypeFloat,
    SQLiteColumnTypeInteger
};

/**
 An object that can be used to get information of the
 columns in a `ResultSet` object.
 */
@protocol ResultSetMetaData <NSObject>

/**
 The number of columns in this `ResultSet` object.
 */
@property (nonatomic, readonly, assign) NSInteger columnCount;

/**
 Column index for column name

 @param columnName The name of the column
 @return Zero-based index for column.
 */
- (NSInteger)columnIndexForName:(NSString *)columnName;

/**
 Get the designated column's name.
 
 @param columnIdx Zero-based index for column
 @return Column name
 */
- (nullable NSString *)columnNameForIndex:(NSInteger)columnIdx;

/**
 Get the designated column's type.
 NOTE: If the ResultSet does not currently point to a valid row, or if the
 column index is out of range, the result is undefined, that is, you should
 call this method after a [ResultSet next] call.
 
 @param columnIdx Zero-based index for column.
 @return Column type.
 */
- (SQLiteColumnType)columnTypeForIndex:(NSInteger)columnIdx;

@end

NS_ASSUME_NONNULL_END
