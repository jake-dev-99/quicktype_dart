// To parse this JSON:
//
//   NSError *error;
//   QTTest *test = [QTTest fromJSON:json encoding:NSUTF8Encoding error:&error];
//   QTConvert *convert = [QTConvert fromJSON:json encoding:NSUTF8Encoding error:&error];

#import <Foundation/Foundation.h>

@class QTTest;
@class QTConvert;

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Object interfaces

@interface QTTest : NSObject
@property (nonatomic, copy) NSString *asdf;
@property (nonatomic, copy) NSString *asdf2;

+ (_Nullable instancetype)fromJSON:(NSString *)json encoding:(NSStringEncoding)encoding error:(NSError *_Nullable *)error;
+ (_Nullable instancetype)fromData:(NSData *)data error:(NSError *_Nullable *)error;
- (NSString *_Nullable)toJSON:(NSStringEncoding)encoding error:(NSError *_Nullable *)error;
- (NSData *_Nullable)toData:(NSError *_Nullable *)error;
@end

@interface QTConvert : NSObject
+ (_Nullable instancetype)fromJSON:(NSString *)json encoding:(NSStringEncoding)encoding error:(NSError *_Nullable *)error;
+ (_Nullable instancetype)fromData:(NSData *)data error:(NSError *_Nullable *)error;
- (NSString *_Nullable)toJSON:(NSStringEncoding)encoding error:(NSError *_Nullable *)error;
- (NSData *_Nullable)toData:(NSError *_Nullable *)error;
@end

NS_ASSUME_NONNULL_END
