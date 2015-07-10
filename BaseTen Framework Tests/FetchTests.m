//
// FetchTests.m
// BaseTen
//
// Copyright 2008-2010 Marko Karppinen & Co. LLC.
// 
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
//     http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "BXDatabaseTestCase.h"

#import <BaseTen/BaseTen.h>
#import <BaseTen/BXDatabaseObjectIDPrivate.h>
#import <BaseTen/BXEnumerate.h>
#import <BaseTen/BXEntityDescriptionPrivate.h>


@interface BXDatabaseObject (BXKVC)
- (id) id1;
- (id) id2;
- (id) value1;
@end


@interface FetchTestObject : BXDatabaseObject
{
	@public
	BOOL didTurnIntoFault;
}
@end


@implementation FetchTestObject
- (void) didTurnIntoFault
{
	didTurnIntoFault = YES;
}
@end

@interface FetchTests : BXDatabaseTestCase 
{
    BXEntityDescription* mEntity;
}

@end

@implementation FetchTests

- (void) setUp
{
	[super setUp];
    mEntity = [[mContext databaseObjectModel] entityForTable: @"test"];
    XCTAssertNotNil (mEntity);
}

- (void) testObjectWithID
{
    NSError* error = nil;
	NSString* uriString = [[self databaseURI] absoluteString];
	uriString = [uriString stringByAppendingString: @"/public/test?id,n=1"];
	NSURL* objectURI = [NSURL URLWithString: uriString];
	BXDatabaseObjectID* anId = [[BXDatabaseObjectID alloc] initWithURI: objectURI
																context: mContext];
	XCTAssertNotNil (anId);
	
    BXDatabaseObject* object = [mContext objectWithID: anId error: &error];
	XCTAssertNotNil (object, @"%@",[error description]);
	
    XCTAssertEqualObjects ([object primitiveValueForKey: @"id"], [NSNumber numberWithInt: 1]);
    //if this is not nil, then another test has failed or the database isn't clean.
    XCTAssertEqualObjects ([object valueForKey: @"value"], nil, @"Database is not in known state!");
}

- (void) testMultiColumnPkey
{
    NSError* error = nil;
    [mContext connectIfNeeded: nil];
    
    BXEntityDescription* multicolumnpkey = [[mContext databaseObjectModel] entityForTable: @"multicolumnpkey"];
    XCTAssertNotNil (multicolumnpkey);
    NSArray* multicolumnpkeys = [mContext executeFetchForEntity: multicolumnpkey withPredicate: nil error: &error];
    XCTAssertNotNil (multicolumnpkeys, @"%@",[error description]);
    XCTAssertTrue (3 == [multicolumnpkeys  count]);
    
    NSSortDescriptor* s1 = [[NSSortDescriptor alloc] initWithKey: @"id1" ascending: YES];
    NSSortDescriptor* s2 = [[NSSortDescriptor alloc] initWithKey: @"id2" ascending: YES];
    multicolumnpkeys = [multicolumnpkeys sortedArrayUsingDescriptors: [NSArray arrayWithObjects: s1, s2, nil]];
    
    id r1 = [multicolumnpkeys objectAtIndex: 0];
    id r2 = [multicolumnpkeys objectAtIndex: 1];
    id r3 = [multicolumnpkeys objectAtIndex: 2];
    
    NSNumber* id1 = [r1 id1];
    XCTAssertEqualObjects (id1, [NSNumber numberWithInt: 1]);
    XCTAssertEqualObjects ([r1 id2], [NSNumber numberWithInt: 1]);
    XCTAssertEqualObjects ([r1 value1], @"thevalue1");
    XCTAssertEqualObjects ([r2 id1], [NSNumber numberWithInt: 1]);
    XCTAssertEqualObjects ([r2 id2], [NSNumber numberWithInt: 2]);
    XCTAssertEqualObjects ([r2 value1], @"thevalue2");
    XCTAssertEqualObjects ([r3 id1], [NSNumber numberWithInt: 2]);
    XCTAssertEqualObjects ([r3 id2], [NSNumber numberWithInt: 3]);
    XCTAssertEqualObjects ([r3 value1], @"thevalue3");
}

- (void) testDates
{
    NSError* error = nil;
    [mContext connectIfNeeded: nil];
    
    BXEntityDescription* datetest = [[mContext databaseObjectModel] entityForTable: @"datetest"];
    XCTAssertNotNil (datetest);
    NSArray* dateobjects = [mContext executeFetchForEntity: datetest withPredicate: nil error: &error];
    XCTAssertNotNil (dateobjects, @"%@",[error description]);
}

- (void) testQuery
{
	NSError* error = nil;
	NSArray* result = [mContext executeQuery: [NSString stringWithUTF8String: "SELECT * FROM ♨"] error: &error];
	XCTAssertNotNil (result, @"%@",[error description]);
	XCTAssertTrue (3 == [result count]);
	BXEnumerate (currentRow, e, [result objectEnumerator])
		XCTAssertTrue (2 == [currentRow count]);
}

- (void) testCommand
{
	NSError* error = nil;
	unsigned long long count = [mContext executeCommand: [NSString stringWithUTF8String: "UPDATE ♨ SET value = 'test'"] error: &error];
	XCTAssertTrue (0 < count, @"%@",[error description]);
	XCTAssertTrue (3 == count);
}

- (void) testNullValidation
{
	NSError* error = nil;
	BXEntityDescription* person = [[mContext databaseObjectModel] entityForTable: @"person"];
	XCTAssertNotNil (person);
	
	NSArray* people = [mContext executeFetchForEntity: person withPredicate: nil error: &error];
	BXDatabaseObject* personObject = [people objectAtIndex: 0];
	
	//soulmate has a non-null constraint.
	id value = nil;
	[personObject validateValue: &value forKey: @"soulmate" error: &error];
	XCTAssertEqualObjects ([error domain], kBXErrorDomain, @"%@",[error description]);
	XCTAssertTrue ([error code] == kBXErrorNullConstraintNotSatisfied, @"%@",[error description]);
	
	error = nil;
	value = [NSNull null];
	[personObject validateValue: &value forKey: @"soulmate" error: &error];
	XCTAssertEqualObjects ([error domain], kBXErrorDomain, @"%@",[error description]);
	XCTAssertTrue ([error code] == kBXErrorNullConstraintNotSatisfied, @"%@",[error description]);
	
	error = nil;
	value = [NSNumber numberWithInt: 1];
	XCTAssertTrue ([personObject validateValue: &value forKey: @"soulmate" error: &error], @"%@",[error description]);
}

- (void) testExclusion
{
	NSError* error = nil;
	XCTAssertTrue ([mContext connectIfNeeded: &error], @"%@",[error description]);

	NSString* fieldname = @"value";
	BXAttributeDescription* property = [[mEntity attributesByName] objectForKey: fieldname];
	XCTAssertFalse ([property isExcluded]);

	NSArray* result = [mContext executeFetchForEntity: mEntity withPredicate: nil 
									 excludingFields: [NSArray arrayWithObject: fieldname]
											   error: &error];
	XCTAssertNotNil (result, @"%@",[error description]);
	XCTAssertTrue ([property isExcluded]);
	
	//Quite the same, which object we get
	BXDatabaseObject* object = [result objectAtIndex: 0]; 
	XCTAssertTrue (1 == [object isFaultKey: fieldname]);
	XCTAssertTrue ([mContext fireFault: object key: fieldname error: &error], @"%@",[error description]);
	XCTAssertTrue (0 == [object isFaultKey: fieldname]);
	
	[mEntity resetAttributeExclusion];
}

- (void) testJoin
{
	NSError* error = nil;
	XCTAssertTrue ([mContext connectIfNeeded: &error], @"%@",[error description]);
	
	BXEntityDescription* person = [[mContext databaseObjectModel] entityForTable: @"person"];
	XCTAssertNotNil (person);
	
	NSPredicate* predicate = [NSPredicate predicateWithFormat: @"person_address.address = 'Mannerheimintie 1'"];
	XCTAssertNotNil (predicate);
	
	//Make another predicate just to test compound predicates.
	NSPredicate* truePredicate = [NSPredicate predicateWithFormat: @"TRUEPREDICATE"];
	XCTAssertNotNil (truePredicate);
	NSPredicate* compound = [NSCompoundPredicate andPredicateWithSubpredicates: 
		[NSArray arrayWithObjects: predicate, truePredicate, nil]];
	
	NSArray* res = [mContext executeFetchForEntity: person withPredicate: compound error: &error];
	XCTAssertNotNil (res, @"%@",[error description]);
	
	XCTAssertTrue (1 == [res count]);
	XCTAssertEqualObjects ([[res objectAtIndex: 0] valueForKey: @"name"], @"nzhuk");
}

- (void) testFault
{
	NSError* error = nil;
	[mEntity setDatabaseObjectClass: [FetchTestObject class]];
	NSArray* res = [mContext executeFetchForEntity: mEntity withPredicate: [NSPredicate predicateWithFormat: @"id = 1"]
								  returningFaults: NO error: &error];
	XCTAssertNotNil (res, @"%@",[error description]);
	
	FetchTestObject* object = [res objectAtIndex: 0];
	XCTAssertFalse ([object isFaultKey: @"value"]);
	
	object->didTurnIntoFault = NO;
	[object faultKey: @"value"];
	XCTAssertTrue (object->didTurnIntoFault);
	XCTAssertTrue ([object isFaultKey: nil]);
	XCTAssertTrue ([object isFaultKey: @"value"]);
	XCTAssertFalse ([object isFaultKey: @"id"]);
	
	object->didTurnIntoFault = NO;
	[object primitiveValueForKey: @"value"];
	[object faultKey: nil];
	XCTAssertTrue (object->didTurnIntoFault);	
	XCTAssertTrue ([object isFaultKey: nil]);
	XCTAssertTrue ([object isFaultKey: @"value"]);
	
	object->didTurnIntoFault = NO;
	[object valueForKey: @"value"];
	[mContext refreshObject: object mergeChanges: YES];
	XCTAssertFalse (object->didTurnIntoFault);
	XCTAssertFalse ([object isFaultKey: @"value"]);
	
	object->didTurnIntoFault = NO;
	[object valueForKey: @"value"];
	[mContext refreshObject: object mergeChanges: NO];
	XCTAssertTrue (object->didTurnIntoFault);
	XCTAssertTrue ([object isFaultKey: nil]);
	XCTAssertTrue ([object isFaultKey: @"value"]);
		
	[mEntity setDatabaseObjectClass: nil];
}
@end
