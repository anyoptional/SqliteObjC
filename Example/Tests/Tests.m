//
//  SqliteObjCTests.m
//  SqliteObjCTests
//
//  Created by code4archer@163.com on 07/23/2019.
//  Copyright (c) 2019 code4archer@163.com. All rights reserved.
//

@import XCTest;
@import SqliteObjC;

@interface Tests : XCTestCase
@property id<Connection> connection;
@end

@implementation Tests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    NSString *dir = NSHomeDirectory();
    NSString *path = [dir stringByAppendingPathComponent:@"/Documents/test.db"];
    NSLog(@"dbpath = %@", path);
    [[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
    
    id<DataSource> ds = SqliteDataSource.new;
    ds.path = path;
    _connection = [ds getConnection];
    XCTAssert(!_connection.isClosed, @"Connection should be opened when getting from DataSource.");
    
    [self populateDatabase];
}


- (void)testCachedStatements {
    id<PreparedStatement> pStmt1 = [_connection prepareStatement:@"select * from test where c=?"];
    [pStmt1 setInt:5 atIndex:0];
    id<ResultSet> rs = [pStmt1 executeQuery];
    while ([rs next]) {
        XCTAssertTrue([[rs stringForColumnIndex:1] isEqualToString:@"number 5"]);
    }
    
    id<PreparedStatement> pStmt2 = [_connection prepareStatement:@"select * from test where c=?"];
    
    XCTAssertNil([pStmt2 executeQuery]);
    
    [pStmt2 setInt:3 atIndex:0];
    rs = [pStmt2 executeQuery];
    while ([rs next]) {
        XCTAssertTrue([[rs stringForColumnIndex:1] isEqualToString:@"number 3"]);
    }
    
    XCTAssertEqual(pStmt1, pStmt2);
    
    id<PreparedStatement> pStmt3 = [_connection prepareStatement:@"select * from test where b=?"];
    
    XCTAssertNotEqual(pStmt3, pStmt2);
    
}

- (void)populateDatabase {
    
    id<PreparedStatement> pStmt = [_connection prepareStatement:@"create table test (a text, b text, c integer, d double, e double)"];
    
    [pStmt executeUpdate];
    
    pStmt = [_connection prepareStatement:@"insert into test (a, b, c, d, e) values (?, ?, ?, ?, ?)"];
    
    [_connection beginTransaction];
    int i = 0;
    while (i++ < 20) {
        [pStmt executeUpdateWithArguments:@[@"hi'", // look!  I put in a ', and I'm not escaping it!
                                            [NSString stringWithFormat:@"number %d", i],
                                            [NSNumber numberWithInt:i],
                                            @([NSDate date].timeIntervalSince1970),
                                            [NSNumber numberWithFloat:2.2f]]];
    }
    [_connection commit];
    
    // do it again, just because
    [_connection beginTransaction];
    i = 0;
    while (i++ < 20) {
        [pStmt executeUpdateWithArguments:@[@"hi'", // look!  I put in a ', and I'm not escaping it!
                                            [NSString stringWithFormat:@"number %d", i],
                                            [NSNumber numberWithInt:i],
                                            @([NSDate date].timeIntervalSince1970),
                                            [NSNumber numberWithFloat:2.2f]]];
    }
    [_connection commit];
    
    [pStmt close];
    
    pStmt = [_connection prepareStatement:@"create table t3 (a somevalue)"];
    [pStmt executeUpdate];
    
    pStmt = [_connection prepareStatement:@"insert into t3 (a) values (?)"];
    [_connection beginTransaction];
    for (int i=0; i < 20; i++) {
        [pStmt setNumber:@(i) atIndex:0];
        [pStmt executeUpdate];
    }
    [_connection commit];
}

- (void)testDatabaseMetaData {
    
    id<DatabaseMetaData> meta = _connection.metaData;
    NSString *dir = NSHomeDirectory();
    NSString *path = [dir stringByAppendingPathComponent:@"/Documents/test.db"];
    XCTAssertTrue([path isEqualToString:meta.filePath]);
    
    XCTAssertTrue([meta tableExists:@"t3"]);
    XCTAssertTrue([meta tableExists:@"test"]);
    XCTAssertFalse([meta tableExists:@"no_such_table"]);
    
    NSArray *fields = [meta columnsInTable:@"test"];
    XCTAssertTrue([fields containsObject:@"a"]);
    XCTAssertTrue([fields containsObject:@"d"]);
    XCTAssertFalse([fields containsObject:@"f"]);
    XCTAssertFalse([fields containsObject:@"A"]);
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    [_connection close];
}



- (void)testFailOnUnopenedDatabase {
    
    [self.connection close];
    
    id<Statement> stmt = [self.connection createStatement];
    
    XCTAssertNil(stmt, @"Shouldn't get from a closed connection");
    XCTAssertNil([stmt executeQuery:@"select * from table"], @"Shouldn't get results from an empty table");
}


- (void)testFailOnBadStatement {
    id<Statement> stmt = [self.connection createStatement];
    
    XCTAssertFalse([stmt executeUpdate:@"blah blah blah"], @"Invalid statement should fail");
}

- (void)testPragmaJournalMode
{
    id<Statement> stmt = [self.connection createStatement];
    id<ResultSet> ps = [stmt executeQuery:@"pragma journal_mode=delete"];
    XCTAssertNotNil(ps, @"Result set should be non-nil");
    XCTAssertTrue([ps next], @"Result set should have a next result");
    [ps close];
}

- (void)testPragmaPageSize
{
    id<Statement> stmt = [self.connection createStatement];
    
    XCTAssertTrue([stmt executeUpdate:@"PRAGMA page_size=2048"], @"pragma should have succeeded");
}

- (void)testPragmaColumnInfo {
    id<PreparedStatement> pstmt = [self.connection prepareStatement:@"create table if not exists my_table (id integer primary key, content text, price double, data blob)"];
    XCTAssertTrue([pstmt executeUpdate], @"should have succeeded");
    
    id<Statement> stmt = [_connection createStatement];
    id<ResultSet> rs = [stmt executeQuery:@"PRAGMA table_info(my_table)"];
    XCTAssertTrue([rs next]);
    NSLog(@"---->> %@", [rs stringForColumn:@"name"]);
}

- (void)testVacuum
{
    id<Statement> stmt = [self.connection createStatement];
    XCTAssertTrue([stmt executeUpdate:@"VACUUM"], @"VACUUM should have succeeded");
}

- (void)testSelectLong
{
    id<PreparedStatement> stmt = [self.connection prepareStatement:@"create table if not exists ull (a integer)"];
    XCTAssertTrue([stmt executeUpdate], @"should have succeeded");
    
    stmt = [_connection prepareStatement:@"insert into ull (a) values (?)"];
    [stmt setLong:LONG_MAX atIndex:0];
    XCTAssertTrue([stmt executeUpdate], @"should have succeeded");
    XCTAssertEqual(stmt.changes, 1, @"Insert a row, so row changes should be 1");
    
    stmt = [self.connection prepareStatement:@"select a from ull"];
    id<ResultSet> rs = [stmt executeQuery];
    XCTAssertNotNil(rs, @"should not be nil");
    while ([rs next]) {
        XCTAssertEqual([rs longForColumnIndex:0], LONG_MAX, @"Result should be LONG_MAX");
        XCTAssertEqual([rs longForColumn:@"a"],   LONG_MAX, @"Result should be LONG_MAX");
    }
    
    [rs close];
}

- (void)testSelectByColumnName
{
    id<PreparedStatement> stmt = [self.connection prepareStatement:@"select rowid,* from test where a = ?"];
    id<ResultSet> rs = [stmt executeQueryWithArguments:@[@"hi"]];
    
    XCTAssertNotNil(rs, @"Should have a non-nil result set");
    
    while ([rs next]) {
        [rs intForColumn:@"c"];
        XCTAssertNotNil([rs stringForColumn:@"b"], @"Should have non-nil string for 'b'");
        XCTAssertNotNil([rs stringForColumn:@"a"], @"Should have non-nil string for 'a'");
        XCTAssertNotNil([rs stringForColumn:@"rowid"], @"Should have non-nil string for 'rowid'");
        [rs doubleForColumn:@"d"];
        [rs doubleForColumn:@"e"];
    }
    
    [rs close];
}

- (void)testInvalidColumnNames
{
    id<PreparedStatement> stmt = [self.connection prepareStatement:@"select rowid, a, b, c from test"];
    id<ResultSet> rs = [stmt executeQuery];
    
    XCTAssertNotNil(rs, @"Should have a non-nil result set");
    
    NSString *invalidColumnName = @"foobar";
    
    while ([rs next]) {
        XCTAssertNil([rs stringForColumn:invalidColumnName], @"Invalid column name should return nil");
        XCTAssertNil([rs dataForColumn:invalidColumnName], @"Invalid column name should return nil");
        XCTAssertNil([rs objectForColumn:invalidColumnName], @"Invalid column name should return nil");
    }
    
    [rs close];
}

- (void)testInvalidColumnIndexes
{
    id<PreparedStatement> stmt = [self.connection prepareStatement:@"select rowid, a, b, c from test"];
    id<ResultSet> rs = [stmt executeQuery];
    
    XCTAssertNotNil(rs, @"Should have a non-nil result set");
    
    int invalidColumnIndex = 999;
    
    while ([rs next]) {
        XCTAssertNil([rs stringForColumnIndex:invalidColumnIndex], @"Invalid column name should return nil");
        XCTAssertNil([rs dataForColumnIndex:invalidColumnIndex], @"Invalid column name should return nil");
        XCTAssertNil([rs objectForColumnIndex:invalidColumnIndex], @"Invalid column name should return nil");
    }
    
    [rs close];
}

- (void)testCaseSensitiveResultDictionary
{
    id<Statement> stmt = [_connection createStatement];
    [stmt executeUpdate:@"create table cs (aRowName integer, bRowName text)"];
    id<PreparedStatement> pStmt = [_connection prepareStatement:@"insert into cs (aRowName, bRowName) values (?, ?)"];
    [pStmt setNumber:@(YES) atIndex:0];
    [pStmt setString:@"hello" atIndex:1];
    XCTAssertTrue([pStmt executeUpdate], @"should succeed");
    
    id<ResultSet> rs = [stmt executeQuery:@"select * from cs"];
    while ([rs next]) {
        XCTAssertNotNil([rs objectForColumn:@"aRowName"], @"aRowName should be non-nil");
        XCTAssertNotNil([rs objectForColumn:@"arowname"], @"arowname should be non-nil");
        XCTAssertNotNil([rs objectForColumn:@"bRowName"], @"bRowName should be non-nil");
        XCTAssertNotNil([rs objectForColumn:@"browname"], @"browname should be non-nil");
    }
    
    [rs close];
    [stmt close];
    [pStmt close];
}

- (void)testBoolInsert
{
    id<Statement> stmt = [_connection createStatement];
    XCTAssertTrue([stmt executeUpdate:@"create table btest (aRowName integer)"]) ;
    id<PreparedStatement> pStmt = [_connection prepareStatement:@"insert into btest (aRowName) values (?)"];
    //    [pStmt setNumber:[NSNumber numberWithBool:12] atIndex:0];
    //    [pStmt executeUpdate];
    
    XCTAssertTrue([pStmt executeUpdateWithArguments:@[[NSNumber numberWithBool:12]]]);
    XCTAssertEqual(pStmt.changes, 1);
    id<ResultSet> rs = [stmt executeQuery:@"select * from btest"];
    XCTAssertNotNil(rs);
    while ([rs next]) {
        XCTAssertTrue([rs boolForColumnIndex:0], @"first column should be true.");
        XCTAssertTrue([rs intForColumnIndex:0] == 1, @"first column should be equal to 1 - it was %d.", [rs intForColumnIndex:0]);
    }
    
    [rs close];
    [stmt close];
    [pStmt close];
}

- (void)testBlobs
{
    id<Statement> stmt = [_connection createStatement];
    [stmt executeUpdate:@"create table blobTable (a text, b blob)"];
    
    
    // let's read an image from safari's app bundle.
    NSData *safariCompass = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"vim" ofType:@"txt"] ];
    if (safariCompass) {
        id<PreparedStatement> pStmt = [_connection prepareStatement:@"insert into blobTable (a, b) values (?, ?)"];
        
        [pStmt executeUpdateWithArguments: @[@"safari's compass", safariCompass]];
        
        pStmt = [_connection prepareStatement:@"select b from blobTable where a = ?"];
        [pStmt setString:@"safari's compass" atIndex:0];
        
        id<ResultSet> rs = [pStmt executeQuery];
        XCTAssertTrue([rs next]);
        NSData *readData = [rs dataForColumn:@"b"];
        XCTAssertEqualObjects(readData, safariCompass);
        
        
        [rs close];
        [stmt close];
        [pStmt close];
    }
}

- (void)testNestedResultSets
{
    id<Statement> stmt = [_connection createStatement];
    id<ResultSet> rs = [stmt executeQuery:@"select * from t3"];
    while ([rs next]) {
        int foo = [rs intForColumnIndex:0];
        
        int newVal = foo + 100;
        id<PreparedStatement> pStmt = [_connection prepareStatement:@"update t3 set a = ? where a = ?"];
        [pStmt setInt:newVal atIndex:0];
        [pStmt setInt:foo atIndex:1];
        [pStmt executeUpdate];
        
        [pStmt close];
        
        pStmt = [_connection prepareStatement:@"select a from t3 where a = ?"];
        id<ResultSet> rs2 = [pStmt executeQueryWithArguments:@[@(newVal)]];
        [rs2 next];
        
        XCTAssertEqual([rs2 intForColumnIndex:0], newVal);
        
        [rs2 close];
    }
    [rs close];
    [stmt close];
}

- (void)testNSNullInsertion
{
    
    id<Statement> stmt = [_connection createStatement];
    [stmt executeUpdate:@"create table nulltest (a text, b text)"];
    id<PreparedStatement> pStmt = [_connection prepareStatement:@"insert into nulltest (a, b) values (?, ?)"];
    [pStmt setString:nil atIndex:0];
    [pStmt setString:@"a" atIndex:1];
    [pStmt executeUpdate];
    [pStmt setString:nil atIndex:0];
    [pStmt setString:@"b" atIndex:1];
    [pStmt executeUpdate];
    
    id<ResultSet> rs = [stmt executeQuery:@"select * from nulltest"];
    
    while ([rs next]) {
        XCTAssertNil([rs stringForColumnIndex:0]);
        XCTAssertNotNil([rs stringForColumnIndex:1]);
    }
    
    [rs close];
}

- (void)testLotsOfNULLs
{
    NSData *safariCompass = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"vim" ofType:@"txt"] ];
    
    if (!safariCompass)
        return;
    
    id<Statement> stmt = [_connection createStatement];
    [stmt executeUpdate:@"create table nulltest2 (s text, d data, i integer, f double, b integer)"];
    
    id<PreparedStatement> pStmt = [_connection prepareStatement:@"insert into nulltest2 (s, d, i, f, b) values (?, ?, ?, ?, ?)"];
    
    [pStmt setString:@"Hi" atIndex:0];
    [pStmt setData:safariCompass atIndex:1];
    [pStmt setInt:12 atIndex:2];
    [pStmt setDouble:4.4 atIndex:3];
    [pStmt setBOOL:YES atIndex:4];
    [pStmt executeUpdate];
    [pStmt close];
    
    pStmt = [_connection prepareStatement:@"insert into nulltest2 (s, d, i, f, b) values (?, ?, ?, ?, ?)"];
    [pStmt setObject:nil atIndex:0];
    [pStmt setObject:nil atIndex:1];
    [pStmt setObject:nil atIndex:2];
    [pStmt setObject:nil atIndex:3];
    [pStmt setObject:nil atIndex:4];
    
    //    [pStmt executeUpdateWithArguments:@[[NSNull null], [NSNull null], [NSNull null], [NSNull null], [NSNull null]]];
    
    
    
    id<ResultSet> rs = [stmt executeQuery:@"select * from nulltest2"];
    
    while ([rs next]) {
        
        int i = [rs intForColumnIndex:2];
        
        if (i == 12) {
            // it's the first row we inserted.
            XCTAssertFalse([rs columnIndexIsNull:0]);
            XCTAssertFalse([rs columnIndexIsNull:1]);
            XCTAssertFalse([rs columnIndexIsNull:2]);
            XCTAssertFalse([rs columnIndexIsNull:3]);
            XCTAssertFalse([rs columnIndexIsNull:4]);
            XCTAssertTrue( [rs columnIndexIsNull:5]);
            
            XCTAssertEqualObjects([rs dataForColumn:@"d"], safariCompass);
            XCTAssertNil([rs dataForColumn:@"notthere"]);
            XCTAssertNil([rs stringForColumnIndex:-2], @"Negative columns should return nil results");
            XCTAssertTrue([rs boolForColumnIndex:4]);
            XCTAssertTrue([rs boolForColumn:@"b"]);
            
            XCTAssertEqualWithAccuracy(4.4, [rs doubleForColumn:@"f"], 0.0000001, @"Saving a float and returning it as a double shouldn't change the result much");
            
            XCTAssertEqual([rs intForColumn:@"i"], 12);
            XCTAssertEqual([rs intForColumnIndex:2], 12);
            
            XCTAssertEqual([rs intForColumnIndex:12],       0, @"Non-existent columns should return zero for ints");
            XCTAssertEqual([rs intForColumn:@"notthere"],   0, @"Non-existent columns should return zero for ints");
            
            XCTAssertEqual([rs longForColumn:@"i"], 12l);
        }
        else {
            // let's test various null things.
            
            XCTAssertTrue([rs columnIndexIsNull:0]);
            XCTAssertTrue([rs columnIndexIsNull:1]);
            XCTAssertTrue([rs columnIndexIsNull:2]);
            XCTAssertTrue([rs columnIndexIsNull:3]);
            XCTAssertTrue([rs columnIndexIsNull:4]);
            XCTAssertTrue([rs columnIndexIsNull:5]);
            
            
            XCTAssertNil([rs dataForColumn:@"d"]);
        }
    }
    
    [rs close];
    [stmt close];
    [pStmt close];
}

- (void)testArgumentsInArray
{
    
    id<Statement> stmt = [_connection createStatement];
    [stmt executeUpdate:@"create table testOneHundredTwelvePointTwo (a text, b integer)"];
    id<PreparedStatement> pStmt = [_connection prepareStatement:@"insert into testOneHundredTwelvePointTwo values (?, ?)"];
    [pStmt executeUpdateWithArguments:@[@"one", @(2)]];
    [pStmt executeUpdateWithArguments:@[@"one", @(3)]];
    [pStmt close];
    pStmt = [_connection prepareStatement:@"select * from testOneHundredTwelvePointTwo where b > ?"];
    [pStmt setInt:1 atIndex:0];
    id<ResultSet> rs = [pStmt executeQuery];
    
    XCTAssertTrue([rs next]);
    
    XCTAssertEqualObjects([rs stringForColumnIndex:0], @"one");
    XCTAssertEqual([rs intForColumnIndex:1], 2);
    
    XCTAssertTrue([rs next]);
    
    XCTAssertEqual([rs intForColumnIndex:1], 3);
    
    XCTAssertFalse([rs next]);
}

- (void)testColumnNamesContainingPeriods
{
    id<Statement> stmt = [_connection createStatement];
    [stmt executeUpdate:@"create table t4 (a text, b text)"];
    
    id<PreparedStatement> pStmt = [_connection prepareStatement:@"insert into t4 (a, b) values (?, ?)"];
    [pStmt executeUpdateWithArguments:@[@"one", @"two"]];
    
    
    id<ResultSet> rs = [stmt executeQuery:@"select t4.a as 't4.a', t4.b from t4;"];
    
    XCTAssertNotNil(rs);
    
    XCTAssertTrue([rs next]);
    
    XCTAssertEqualObjects([rs stringForColumn:@"t4.a"], @"one");
    XCTAssertEqualObjects([rs stringForColumn:@"b"], @"two");
    
    [rs close];
}


- (void)testUpdateWithErrorAndBindings
{
    id<Statement> stmt = [_connection createStatement];
    XCTAssertTrue([stmt executeUpdate:@"create table t5 (a text, b int, c blob, d text, e text)"]);
    id<PreparedStatement> pStmt = [_connection prepareStatement:@"insert into t5 values (?, ?, ?, ?, ?)"];
    BOOL result = [pStmt executeUpdateWithArguments:@[@"text", [NSNumber numberWithInt:42], @"BLOB", @"d", [NSNumber numberWithInt:0]]];
    XCTAssertTrue(result);
}

- (void)testSelectWithEmptyArgumentsArray
{
    id<PreparedStatement> pStmt = [_connection prepareStatement:@"select * from test where a=?"];
    id<ResultSet> rs = [pStmt executeQueryWithArguments:@[]];
    XCTAssertNil(rs);
}

- (void)testDatabaseAttach
{
    NSFileManager *fileManager = [NSFileManager new];
    NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/attachme.db"];
    [fileManager removeItemAtPath:path error:nil];
    
    id<DataSource> ds = SqliteDataSource.new;
    ds.path = path;
    id<Connection> dbB = [ds getConnection];
    
    XCTAssertTrue([dbB open]);
    XCTAssertTrue([[dbB createStatement] executeUpdate:@"create table attached (a text)"]);
    id<PreparedStatement> pStmt = [dbB prepareStatement:@"insert into attached values (?)"];
    [pStmt setString:@"test" atIndex:0];
    XCTAssertTrue(([pStmt executeUpdate]));
    XCTAssertTrue([dbB close]);
    
    NSString *sql = [NSString stringWithFormat:@"attach database '%@' as attack", path];
    [[self.connection createStatement] executeUpdate:sql];
    
    id<ResultSet> rs = [[self.connection createStatement] executeQuery:@"select * from attack.attached"];
    XCTAssertNotNil(rs);
    XCTAssertTrue([rs next]);
    [rs close];
}

- (void)testPragmaDatabaseList
{
    id<Statement> stmt = [self.connection createStatement];
    id<ResultSet> rs = [stmt executeQuery:@"pragma database_list"];
    int counter = 0;
    while ([rs next]) {
        counter++;
        XCTAssertEqualObjects([rs stringForColumn:@"file"], [NSHomeDirectory() stringByAppendingPathComponent:@"/Documents/test.db"]);
    }
    XCTAssertEqual(counter, 1, @"Only one database should be attached");
}

- (void)testColumnNameMap
{
    id<Statement> stmt = [self.connection createStatement];
    
    
    XCTAssertTrue([stmt executeUpdate:@"create table colNameTest (a, b, c, d)"]);
    XCTAssertTrue([stmt executeUpdate:@"insert into colNameTest values (1, 2, 3, 4)"]);
    
    id<ResultSet> ars = [stmt executeQuery:@"select * from colNameTest"];
    XCTAssertNotNil(ars);
    
    NSDictionary *d = [ars.metaData performSelector:@selector(columnNameToIndexMap)];
    XCTAssertEqual([d count], (NSUInteger)4);
    
    XCTAssertEqualObjects([d objectForKey:@"a"], @0);
    XCTAssertEqualObjects([d objectForKey:@"b"], @1);
    XCTAssertEqualObjects([d objectForKey:@"c"], @2);
    XCTAssertEqualObjects([d objectForKey:@"d"], @3);
    
}

- (void)testCharAndBoolTypes
{
    id<Statement> stmt = [_connection createStatement];
    
    XCTAssertTrue([stmt executeUpdate:@"create table charBoolTest (a, b, c)"]);
    
    id<PreparedStatement> pStmt = [_connection prepareStatement:@"insert into charBoolTest values (?, ?, ?)"];
    BOOL success = [pStmt executeUpdateWithArguments:@[@YES, @NO, @('x')]];
    
    XCTAssertTrue(success, @"Unable to insert values");
    
    id<ResultSet> rs = [stmt executeQuery:@"select * from charBoolTest"];
    XCTAssertNotNil(rs);
    
    XCTAssertTrue([rs next], @"Did not return row");
    
    XCTAssertEqual([rs boolForColumn:@"a"], true);
    XCTAssertEqualObjects([rs objectForColumn:@"a"], @YES);
    
    XCTAssertEqual([rs boolForColumn:@"b"], false);
    XCTAssertEqualObjects([rs objectForColumn:@"b"], @NO);
    
    XCTAssertEqual([rs intForColumn:@"c"], 'x');
    XCTAssertEqualObjects([rs objectForColumn:@"c"], @('x'));
    
    [rs close];
    
    XCTAssertTrue([stmt executeUpdate:@"drop table charBoolTest"], @"Did not drop table");
    
}


- (void)testOpenZeroLengthPath
{
    id<DataSource> ds = [SqliteDataSource dataSourceWithPath:@""];
    id<Connection> db = [ds getConnection];
    XCTAssert([db open], @"open failed");
    XCTAssert([[db createStatement] executeUpdate:@"create table foo (bar text)"], @"create failed");
    NSString *value = @"baz";
    id<PreparedStatement> pStmt = [db prepareStatement:@"insert into foo (bar) values (?)"];
    XCTAssert([pStmt executeUpdateWithArguments:@[value]], @"insert failed");
    pStmt = [db prepareStatement:@"select bar from foo"];
    id<ResultSet> rs = [pStmt executeQuery];
    [rs next];
    
    NSString *retrievedValue = [rs stringForColumnIndex:0];
    [rs close];
    XCTAssert([value compare:retrievedValue] == NSOrderedSame, @"values didn't match");
    
    XCTAssertEqual(db, [ds getConnection]);
    [db close];
    XCTAssertNotEqual(db, [ds getConnection]);
}

- (void)testOpenTwice
{
    [_connection open];
    XCTAssert([_connection open], @"Double open failed");
}

- (void)testInvalid
{
    NSString *documentsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *path          = [documentsPath stringByAppendingPathComponent:@"nonexistentfolder/test.sqlite"];
    
    id<DataSource> ds = SqliteDataSource.new;
    ds.path = path;
    id<Connection> db = [ds getConnection];
    XCTAssertNil(db);
    XCTAssertFalse([db open], @"open did NOT fail");
}


- (void)testCloseOpenResultSets
{
    id<DataSource> ds = SqliteDataSource.new;
    ds.path = @"";
    id<Connection> db = [ds getConnection];    XCTAssert([db open], @"open failed");
    XCTAssert([[db createStatement] executeUpdate:@"create table foo (bar text)"], @"create failed");
    NSString *value = @"baz";
    id<PreparedStatement> pStmt = [db prepareStatement:@"insert into foo (bar) values (?)"];
    XCTAssert([pStmt executeUpdateWithArguments:@[value]], @"insert failed");
    pStmt = [db prepareStatement:@"select bar from foo"];
    id<ResultSet> rs = [pStmt executeQuery];
    [rs close];
    XCTAssertFalse([rs next], @"step should have failed");
}

- (void)testGoodConnection
{
    id<DataSource> ds = SqliteDataSource.new;
    ds.path = @"";
    id<Connection> db = [ds getConnection];
    XCTAssert([db open], @"open failed");
    XCTAssertFalse([db isClosed], @"no good connection");
}

- (void)testBadConnection
{
    id<DataSource> ds = SqliteDataSource.new;
    ds.path = @"";
    id<Connection> db = [ds getConnection];
    [db close];
    // XCTAssert([db open], @"open failed");  // deliberately did not open
    XCTAssertTrue([db isClosed], @"no good connection");
}


- (void)testChanges
{
    id<DataSource> ds = SqliteDataSource.new;
    ds.path = @"";
    id<Connection> db = [ds getConnection];
    XCTAssert([db open], @"open failed");
    XCTAssert([[db createStatement] executeUpdate:@"create table foo (foo_id integer primary key autoincrement, bar text)"], @"create failed");
    id<PreparedStatement> pStmt = [db prepareStatement:@"insert into foo (bar) values (?)"];
    XCTAssert([pStmt executeUpdateWithArguments:@[@"baz"]], @"insert failed");
    XCTAssert([pStmt executeUpdateWithArguments:@[@"qux"]], @"insert failed");
    pStmt = [db prepareStatement:@"update foo set bar = ?"];
    XCTAssert([pStmt executeUpdateWithArguments:@[@"xxx"]], @"update failed");
    
    NSInteger changes = [pStmt changes];
    
    XCTAssertEqual(changes, 2, @"two rows should have incremented \(%ld)", (long)changes);
}

@end

