//
// PGTSTypeDescription.h
// BaseTen
//
// Copyright 2006-2009 Marko Karppinen & Co. LLC.
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

#import <Foundation/Foundation.h>
#import "PGTSSchemaObjectDescription.h"



@interface PGTSTypeDescription : PGTSSchemaObjectDescription 
{
    Oid mElementOid;
	NSInteger mLength;
    char mDelimiter;
	char mKind;
}
- (Oid) elementOid;
- (NSInteger) length;
- (char) delimiter;
- (char) kind;

//Thread un-safe methods.
- (void) setElementOid: (Oid) anOid;
- (void) setLength: (NSInteger) length;
- (void) setDelimiter: (char) delimiter;
- (void) setKind: (char) kind;
@end
