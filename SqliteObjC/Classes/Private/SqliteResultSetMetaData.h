//
//  SqliteResultSetMetaData.h
//  SqliteObjC
//
//  Created by Archer on 2019/7/16.
//

#import <Foundation/Foundation.h>
#import "ResultSetMetaData.h"
#import "SqliteStatement.h"

NS_ASSUME_NONNULL_BEGIN

/**
 DO NOT USE.
 */
@interface SqliteResultSetMetaData : NSObject <ResultSetMetaData>

@property (nonatomic, readonly, assign) NSInteger columnCount;
@property (nonatomic, readonly, strong) SqliteStatement *statement;
@property (nonatomic, readonly, copy) NSDictionary *columnNameToIndexMap;

- (instancetype)initWithStatement:(SqliteStatement *)statement;

@end

NS_ASSUME_NONNULL_END
