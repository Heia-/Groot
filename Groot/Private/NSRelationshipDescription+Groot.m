//  NSRelationshipDescription+Groot.m
//
// Copyright (c) 2016-2017 Ryan Cook
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "NSRelationshipDescription+Groot.h"
#import "NSEntityDescription+Groot.h"

@implementation NSRelationshipDescription (Groot)

- (BOOL)grt_isAnIncompleteRelationship
{
    return [(NSString*)self.userInfo[@"MergeOnly"] boolValue];
}

- (nullable NSArray*)grt_objectsNotInRelationship:(nonnull NSArray <NSManagedObject*> *)objects
                                          context:(nonnull NSManagedObjectContext *)context
{
    NSSet *attributes = [self.destinationEntity grt_identityAttributes];
    
    if (attributes.count == 0) {
        return objects;
    } else {// if (attributes.count == 1) {
        return [self pendingRelationshipsUsingUniqueAttributes:attributes objects:objects context:context];
//    } else {
//        return nil;//[[GRTCompositeUniquingSerializationStrategy alloc] initWithEntity:entity uniqueAttributes:attributes];
    }
}

- (nullable NSArray *)pendingRelationshipsUsingUniqueAttributes:(nonnull NSSet <NSAttributeDescription *>  *)uniqueAttributes
                                                        objects:(nonnull NSArray <NSManagedObject*> *)objects
                                                        context:(nonnull NSManagedObjectContext *)context
{
    NSError *error;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    fetchRequest.entity = self.entity;
    fetchRequest.returnsObjectsAsFaults = NO;
    // Create the predicate for each unique Attribute
    NSMutableArray *predicates = [NSMutableArray array];
    for (NSAttributeDescription *attribute in uniqueAttributes) {
        [predicates addObject:[NSPredicate predicateWithFormat:@"%K.%K IN %@", self.name, attribute.name, [objects valueForKey:attribute.name]]];
    }
    fetchRequest.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];
    
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    
    if (fetchedObjects != nil) {
        NSMutableArray *pendingRelations = [NSMutableArray arrayWithCapacity:objects.count - fetchedObjects.count];
        
        for (NSManagedObject *object in objects) {
            if (![fetchedObjects containsObject:object]) {
                [pendingRelations addObject:object];
            }
//            id identifier = [object valueForKey:self.uniqueAttribute.name];
//            if (identifier != nil) {
//                objects[identifier] = object;
//            }
        }
        return pendingRelations;
    }
    
    return nil;
}
//
//- (NSManagedObject *)serializeJSONValue:(id)value
//                              inContext:(NSManagedObjectContext *)context
//                        existingObjects:(NSDictionary *)existingObjects
//                                  error:(NSError *__autoreleasing  __nullable * __nullable)outError
//{
//    NSManagedObject *managedObject = [self managedObjectForJSONValue:value
//                                                           inContext:context
//                                                     existingObjects:existingObjects];
//    
//    NSError *error = nil;
//    if ([value isKindOfClass:[NSDictionary class]]) {
//        [managedObject grt_serializeJSONDictionary:value mergeChanges:YES error:&error];
//    } else {
//        [managedObject grt_serializeJSONValue:value
//                              uniqueAttribute:self.uniqueAttribute
//                                        error:&error];
//    }
//    
//    if (error != nil) {
//        [context deleteObject:managedObject];
//        
//        if (outError != nil) {
//            *outError = error;
//        }
//        
//        return nil;
//    }
//    
//    return managedObject;
//}

@end
