//
//  SqliteResultSet.h
//  SqliteObjC
//
//  Created by Archer on 2019/7/16.
//

#import <Foundation/Foundation.h>
#import "ResultSet.h"

@class SqliteStatement;

NS_ASSUME_NONNULL_BEGIN

/**
 DO NOT USE.
 */
@interface SqliteResultSet : NSObject <ResultSet>

/**
 Move the current result to next row, and returns the raw SQLite return code for the cursor.
 Useful for detecting end of cursor vs. error.
 */
- (int)step;

@property (nonatomic, readonly, strong) SqliteStatement *statement;
@property (nonatomic, readonly, strong) id<ResultSetMetaData> metaData;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithStatement:(SqliteStatement *)statement;

@end

NS_ASSUME_NONNULL_END
