//
//  DatabaseMetaData.h
//  SqliteObjC
//
//  Created by Archer on 2019/7/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Additional infomation about underlying databse.
 */
@protocol DatabaseMetaData <NSObject>

/**
 Does table exist in database?
 
 @param tableName The name of the table being looked for.
 
 @return `YES` if table found; `NO` if not found.
 */
- (BOOL)tableExists:(NSString *)tableName;

/**
 All the fields in the table.

 @param tableName The name of the table being looked for.
 @return All the fields in the table.
 */
- (NSArray<NSString *> *)columnsInTable:(NSString *)tableName;

/**
 Path of database file.
 */
@property (nonatomic, readonly, copy) NSString *filePath;

@end

NS_ASSUME_NONNULL_END
