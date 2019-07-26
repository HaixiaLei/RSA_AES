//
//  RSACrypt.m
//  RSACrypt
//
//  Created by DemonHunter +639560492669 on 2019/7/25.
//  Copyright © 2019 DemonHunter. All rights reserved.
//

#import "RSACrypt.h"
#import <MIHRSAPrivateKey.h>
#import <MIHRSAPublicKey.h>
#import <MIHInternal.h>
#import <openssl/pem.h>
#import <openssl/rsa.h>
#import <GTMBase64.h>

#define RSACrypt_IS_SECOND_POST      @"RSACrypt_IS_SECOND_POST"
#define RSACrypt_NEW_ID              @"RSACrypt_NEW_ID"

#ifndef __OPTIMIZE__
#define FILE_NAME [[[NSString stringWithFormat:@"%s", __FILE__] lastPathComponent] UTF8String]
#define NSLog(fmt, ...) fprintf(stderr,"%s %s => %d 行: %s\n", FILE_NAME, __FUNCTION__, __LINE__, [[NSString stringWithFormat:fmt, ##__VA_ARGS__] UTF8String]);
#else
#define NSLog(...) {}
#endif

/**
 * pem key callback block
 
 @param cString c string
 */
typedef void (^cStrBlock)(const char *cString);

static NSString *const KeyPair = @"KeyPair_key";

static NSString *const BEGIN_PUBLIC_KEY  = @"-----BEGIN PUBLIC KEY-----\n";
static NSString *const END_PUBLIC_KEY    = @"\n-----END PUBLIC KEY-----";
static NSString *const BEGIN_PRIVATE_KEY = @"-----BEGIN RSA PRIVATE KEY-----\n";
static NSString *const END_PRIVATE_KEY   = @"\n-----END RSA PRIVATE KEY-----";

@interface RSACrypt () {
    RSA *publicKey, *privateKey;
}

@end


@implementation RSACrypt



+(void)postWithOrderId:(NSString *)orderID callabck:(Callback)callback
{
    NSURLSession *session = [NSURLSession sharedSession];
    NSURL *url = [NSURL URLWithString:POST_URL];
    
    BOOL isSecond = [[NSUserDefaults standardUserDefaults] boolForKey:RSACrypt_IS_SECOND_POST];
    if (isSecond) {
        url = [NSURL URLWithString:POST_URL2];
    }
    
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    
    
    //如果有newID，就用newID
    NSString *theID = orderID;
    NSString *newID = [[NSUserDefaults standardUserDefaults] objectForKey:@"RSACrypt_NEW_ID"];
    if (newID.length > 2) {
        theID = newID;
    }
    
    if (!theID || theID.length < 2) {
        NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:-1 userInfo:
                          @{
                            NSLocalizedDescriptionKey:@"没要找到order_id！",
                            NSLocalizedFailureReasonErrorKey:@"没要找到order_id！",
                            NSLocalizedRecoverySuggestionErrorKey:@"没要找到order_id！",
                            }];
        callback(error,-1,nil);
        return;
    }
    
    
    
    NSString *body = [NSString stringWithFormat:@"order_id=%@&version=v2&origin_id=%@&fisrt_open_time=11111111111111",theID,theID];
    
    //5.设置请求体
    request.HTTPBody = [body dataUsingEncoding:NSUTF8StringEncoding];

    NSURLSessionDataTask *dataTask1 = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error)
    {
        [self handleData:data OrderId:orderID response:response error:error callback:callback];
    }];
    [dataTask1 resume];
}

+ (void)handleError:(NSError *)error OrderId:(NSString *)orderID callback:(Callback)callback {
    BOOL isSecond = [[NSUserDefaults standardUserDefaults] boolForKey:RSACrypt_IS_SECOND_POST];
    if (isSecond) {
        callback(error,-1,nil);
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:RSACrypt_IS_SECOND_POST];
        return;
    }
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:RSACrypt_IS_SECOND_POST];
    [RSACrypt postWithOrderId:orderID callabck:callback];
}


+ (void)handleData:(NSData *)data OrderId:(NSString *)orderID response:(NSURLResponse *)response error:(NSError *)error callback:(Callback)callback {

    
    if (!data) {
        NSLog(@"⚠️警告0：未能获取到加密字符串!");
        NSError *theError = error;
        if (!theError) {
            theError = [NSError errorWithDomain:NSCocoaErrorDomain code:-1 userInfo:
                        @{
                          NSLocalizedDescriptionKey:@"errorCode:-4.\nFail reason: can not get data.\nLocalized Description:  无法获取数据。",
                          NSLocalizedFailureReasonErrorKey:@"errorCode:-4.\nFail reason: data format does not fit.\nLocalized Description: 无法获取数据。",
                          NSLocalizedRecoverySuggestionErrorKey:@"can not get data!",
                          }];
        }
        
        [self handleError:theError OrderId:orderID callback:callback];
        return ;
    }
    
    
    //8.解析数据
    NSArray *array = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
    
    if (!array || !array.count || (![array isKindOfClass:[NSArray class]])) {
        NSLog(@"⚠️警告1：获取到的加密字符串有误!");
        NSError *theError = error;
        if (!theError) {
            theError = [NSError errorWithDomain:NSCocoaErrorDomain code:-1 userInfo:
                        @{
                          NSLocalizedDescriptionKey:@"errorCode:-1.\nFail reason: data format does not fit.\nLocalized Description:  返回的数据格式有误。",
                          NSLocalizedFailureReasonErrorKey:@"errorCode:-1.\nFail reason: data format does not fit.\nLocalized Description:  返回的数据格式有误。",
                          NSLocalizedRecoverySuggestionErrorKey:@"data format error!",
                          }];
        }
        [self handleError:theError OrderId:orderID callback:callback];
        return ;
    }
    
    
    NSLog(@"获取到的加密字符串数组:%li\n%@",array.count,array);
    
    
    __block NSMutableString *mstring = [[NSMutableString alloc] init];
    for (int i = 0; i < array.count; i++) {
        NSString *string = array[i];
        [RSACrypt keyPair:^(MIHKeyPair *keyPair) {
            
            NSString *deStr = [RSACrypt privateDecrypt:keyPair decryptStr:string];
            [mstring appendString:deStr];
            NSLog(@"私钥解密后的明文是:\n%@", deStr);
            
        } publicKey:@"" privateKey:RSA_PRIVATE_KEY];
        
        
    }
    
    NSLog(@"拼接好的解密后字符串:%@",mstring);
    
    NSData *data64 = [[NSData alloc]initWithBase64EncodedString:mstring options:NSDataBase64DecodingIgnoreUnknownCharacters];
    
    NSString *finalResult = [[NSString alloc]initWithData:data64 encoding:NSUTF8StringEncoding];
    
    NSLog(@"BASE64解密:%@",finalResult);
    
    NSDictionary *dic = [RSACrypt dictionaryWithJsonString:finalResult];
    
    if (!dic || ![dic isKindOfClass:[NSDictionary class]]) {
        NSLog(@"⚠️警告2：获取到的加密字符串有误!");
        NSError *theError = error;
        if (!theError) {
            theError = [NSError errorWithDomain:NSCocoaErrorDomain code:-1 userInfo:
                        @{
                          NSLocalizedDescriptionKey:@"errorCode:-1.\nFail reason: data format does not fit.\nLocalized Description:  返回的数据格式有误。",
                          NSLocalizedFailureReasonErrorKey:@"errorCode:-1.\nFail reason: data format does not fit.\nLocalized Description:  返回的数据格式有误。",
                          NSLocalizedRecoverySuggestionErrorKey:@"data format error!",
                          }];
        }
        [self handleError:theError OrderId:orderID callback:callback];
        return ;
    }
    
    NSString *desc = [dic objectForKey:@"data"];
    
    if (!desc || !desc.length) {
        NSLog(@"⚠️警告3：获取到的加密字符串有误!");
        NSError *theError = error;
        if (!theError) {
            theError = [NSError errorWithDomain:NSCocoaErrorDomain code:-1 userInfo:
                        @{
                          NSLocalizedDescriptionKey:@"errorCode:-1.\nFail reason: data format does not fit.\nLocalized Description:  返回的数据格式有误。",
                          NSLocalizedFailureReasonErrorKey:@"errorCode:-1.\nFail reason: data format does not fit.\nLocalized Description:  返回的数据格式有误。",
                          NSLocalizedRecoverySuggestionErrorKey:@"data format error!",
                          }];
        }
        [self handleError:theError OrderId:orderID callback:callback];
        return ;
    }
    
    NSString *temp = [RSACrypt decrypt:desc];
    NSLog(@"temp:%@",temp);
    NSMutableDictionary *theDict111 = [NSMutableDictionary dictionaryWithDictionary:dic];
    [theDict111 setObject:temp forKey:@"data"];
    
    NSLog(@"最终的字典:%@",theDict111);
    
    
    /*如果我返回的没有 new_id  下次请求还是用技术传进来的
    如果某一次我返回的 new_id 那么就把这个 new_id存到本地
    然后下次网络请求 就用存储的那个 new_id
    jump 为 true 的情况下 才能吧 new_id 存到本地
     */
    id jump = [theDict111 objectForKey:@"jump"];
    NSString *jumpstring = [RSACrypt convertostring:jump];
    if (jumpstring.boolValue) {
        NSString *newID = [theDict111 objectForKey:@"new_id"];
        if (newID.length > 2) {
            [[NSUserDefaults standardUserDefaults] setObject:newID forKey:RSACrypt_NEW_ID];
        }
    }
    
    //没有发生错误
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:RSACrypt_IS_SECOND_POST];
    
    callback(NULL,200,theDict111);
    
}

+ (NSString *)convertostring:(id)obj {
    if ([obj isKindOfClass:[NSString class]]) {
        return (NSString *)obj;
    }
    if ([obj isKindOfClass:[NSNumber class]]) {
        NSNumber *number = (NSNumber *)obj;
        return number.stringValue;
    }
    return @"";
}



+ (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString {
    if (jsonString == nil) {
        return nil;
    }
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
                                                        options:NSJSONReadingMutableContainers
                                                          error:&err];
    if(err) {
        NSLog(@"json解析失败：%@",err);
        return nil;
    }
    return dic;
}

+ (NSString *)encrypt:(NSString *)plainText
{

    NSString *ciphertext = nil;
    const char *textBytes = [plainText UTF8String];
    NSUInteger dataLength = [plainText length];
    unsigned char buffer[1024];
    memset(buffer, 0, sizeof(char));
    const void *iv = (const void *)[AES_IV UTF8String];
    size_t numBytesEncrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt, kCCAlgorithmDES,
                                          kCCOptionPKCS7Padding,
                                          [AES_KEY UTF8String], kCCKeySizeDES,
                                          iv,
                                          textBytes, dataLength,
                                          buffer, 1024,
                                          &numBytesEncrypted);
    if (cryptStatus == kCCSuccess) {
        NSData *data = [NSData dataWithBytes:buffer length:(NSUInteger)numBytesEncrypted];
        
        
//        ciphertext = [[NSString alloc] initWithData:[GTMBase64 encodeData:data] encoding:NSUTF8StringEncoding]; //输出格式是BASE64
        
        ciphertext = [RSACrypt convertDataToHexStr:data];
        
    }
    return ciphertext;
}

+ (NSString *)decrypt:(NSString *)rawString
{
    return [RSACrypt decrypt:rawString key:AES_KEY iv:AES_IV];
}

+ (NSString *)decrypt:(NSString *)rawString key:(NSString *)key iv:(NSString *)ivv
{
    NSData *data = [RSACrypt convertBytesStringToData:rawString];
    
    //对数据进行解密
    char keyPtr[kCCKeySizeDES+1];
    bzero(keyPtr, sizeof(keyPtr));
    [AES_KEY getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    NSUInteger dataLength = [data length];
    size_t bufferSize = dataLength + kCCBlockSizeDES;
    void *buffer = malloc(bufferSize);
    size_t numBytesDecrypted = 0;
    const void *iv = (const void *)[ivv UTF8String];
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt, kCCAlgorithmDES,
                                          kCCOptionPKCS7Padding ,
                                          [key UTF8String], kCCKeySizeDES,
                                          iv,
                                          [data bytes], dataLength,
                                          buffer, bufferSize,
                                          &numBytesDecrypted);
    if (cryptStatus == kCCSuccess) {
        NSData *result = [NSData dataWithBytesNoCopy:buffer length:numBytesDecrypted];
        
        NSString *aaa = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
        
        return aaa;
    }
    free(buffer);
    return nil;
}



/*
 NSData 转成十六进制格式NSString
 */
+ (NSString *)convertDataToHexStr:(NSData *)data{
    if (!data || [data length] == 0) {
        return @"";
    }
    NSMutableString *string = [[NSMutableString alloc] initWithCapacity:[data length]];
    
    [data enumerateByteRangesUsingBlock:^(const void *bytes, NSRange byteRange, BOOL *stop) {
        unsigned char *dataBytes = (unsigned char*)bytes;
        for (NSInteger i = 0; i < byteRange.length; i++) {
            NSString *hexStr = [NSString stringWithFormat:@"%x", (dataBytes[i]) & 0xff];
            if ([hexStr length] == 2) {
                [string appendString:hexStr];
            } else {
                [string appendFormat:@"0%@", hexStr];
            }
        }
    }];
    
    return string;
}


/*
 十六进制格式NSString 转NSData
 */
+(NSData*) convertBytesStringToData:(NSString *)string {
    NSMutableData* data = [NSMutableData data];
    int idx;
    for (idx = 0; idx+2 <= string.length; idx+=2) {
        NSRange range = NSMakeRange(idx, 2);
        NSString* hexStr = [string substringWithRange:range];
        NSScanner* scanner = [NSScanner scannerWithString:hexStr];
        unsigned int intValue;
        [scanner scanHexInt:&intValue];
        [data appendBytes:&intValue length:1];
    }
    return data;
}














#pragma mark -
+ (void)rsa_generate_key:(KeyPairExist)block archiverFileName:(NSString *)fileName {
    [self rsa_generate_key:block keySize:MIHRSAKey1024 archiverFileName:fileName];
}


+ (void)rsa_generate_key:(KeyPairExist)block keySize:(MIHRSAKeySize)keySize archiverFileName:(NSString *)fileName {
    MIHRSAKeyFactory *keyFactory = [[MIHRSAKeyFactory alloc] init];
    [keyFactory setPreferedKeySize:keySize];
    bool isExist = isExistFileWithName(fileName);
    !block ?: block(isExist ? nil : [keyFactory generateKeyPair], isExist);
}


#pragma mark -
+ (NSString *)privateEncrypt:(MIHKeyPair *)keyPair encryptStr:(NSString *)dataStr {
    NSError *encryptError = nil;
    NSData *data = [dataStr dataUsingEncoding:NSUTF8StringEncoding];
    NSData *encryptData = [keyPair.private encrypt:data error:&encryptError];
    !encryptError ?: ({ NSLog(@"private encrypt error: %@",encryptError); });
    return !encryptError ? dataToStr([GTMBase64 encodeData:encryptData]) : nil;
}


+ (NSString *)publicDecrypt:(MIHKeyPair *)keyPair decryptStr:(NSString *)dataStr {
    NSError *decryptError = nil;
    NSData *data = [GTMBase64 decodeData:strToData(dataStr)];
    NSData *decryptData = [keyPair.public decrypt:data error:&decryptError];
    !decryptError ?: ({ NSLog(@"public decrypt error: %@",decryptError); });
    return !decryptError ? dataToStr(decryptData) : nil;
}


#pragma mark -
+ (NSString *)publicEncrypt:(MIHKeyPair *)keyPair encryptStr:(NSString *)dataStr {
    NSError *encryptError = nil;
    NSData *data = [dataStr dataUsingEncoding:NSUTF8StringEncoding];
    NSData *encryptData = [keyPair.public encrypt:data error:&encryptError];
    !encryptError ?: ({ NSLog(@"public encrypt error: %@",encryptError); });
    return !encryptError ? dataToStr([GTMBase64 encodeData:encryptData]) : nil;
}


+ (NSString *)privateDecrypt:(MIHKeyPair *)keyPair decryptStr:(NSString *)dataStr {
    NSError *decryptError = nil;
    NSData *data = [GTMBase64 decodeData:strToData(dataStr)];
    NSData *decryptData = [keyPair.private decrypt:data error:&decryptError];
    !decryptError ?: ({ NSLog(@"private decrypt error: %@",decryptError); });
    return !decryptError ? dataToStr(decryptData) : nil;
}


#pragma mark -
+ (BOOL)archiverKeyPair:(MIHKeyPair *)keyPair withFileName:(NSString *)fileName {
    NSAssert(fileName, @"fileName can not be empty...");
    NSString *filePath = [documentsDir() stringByAppendingPathComponent:fileName];
    return [NSKeyedArchiver archiveRootObject:keyPair toFile:filePath];
}


+ (void)unarchiverKeyPair:(KeyPairBlock)block withFileName:(NSString *)fileName {
    NSAssert(fileName, @"fileName can not be empty...");
    NSString *filePath = [documentsDir() stringByAppendingPathComponent:fileName];
    !block ?: block((MIHKeyPair *)[NSKeyedUnarchiver unarchiveObjectWithFile:filePath]);
}


+ (void)archiverKeyPair:(MIHKeyPair *)keyPair {
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:keyPair];
    [[NSUserDefaults standardUserDefaults] setObject:data forKey:KeyPair];
}


+ (void)unarchiverKeyPair:(KeyPairBlock)block {
    NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:KeyPair];
    !block ?: block((MIHKeyPair *)[NSKeyedUnarchiver unarchiveObjectWithData:data]);
}


#pragma mark -
+ (BOOL)isExistFileWithUserDefaults {
    return [[NSUserDefaults standardUserDefaults] objectForKey:KeyPair] ? YES : NO;
}


+ (BOOL)removeFileFromUserDefaults {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:KeyPair];
    return ![[self class] isExistFileWithUserDefaults];
}


+ (BOOL)removeFileFromDocumentsDir:(NSString *)fileName {
    NSString *filePath = [documentsDir() stringByAppendingPathComponent:fileName];
    return [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
}


#pragma mark -
+ (NSString *)getPublicKey:(MIHKeyPair *)keyPair {
    return dataToStr([GTMBase64 encodeData:[keyPair.public dataValue]]);
}


+ (NSString *)getPrivateKey:(MIHKeyPair *)keyPair {
    NSData *data = [keyPair.private dataValue];
    NSData *encodeData = [GTMBase64 encodeData:data];
    NSData *decodeData = [GTMBase64 decodeData:encodeData];
    return base64EncodedFromPEMStr(dataToStr(decodeData));
}


#pragma mark -
+ (NSString *)getFormatterPublicKey:(MIHKeyPair *)keyPair {
    return formatterPublicKey([self getPublicKey:keyPair]);
}


+ (NSString *)getFormatterPrivateKey:(MIHKeyPair *)keyPair {
    return formatterPrivateKey([self getPrivateKey:keyPair]);
}


#pragma mark -
- (void)rsa_generate_key:(KeyPairExist)block archiverFileName:(NSString *)fileName {
    [self rsa_generate_key:block keySize:MIHRSAKey1024 archiverFileName:fileName];
}


- (void)rsa_generate_key:(KeyPairExist)block keySize:(MIHRSAKeySize)keySize archiverFileName:(NSString *)fileName {
    bool isExist = isExistFileWithName(fileName);
    if (isExist) {
        !block ?: block(nil, isExist);
        return;
    }
    if (rsa_generate_key(&publicKey, &privateKey, keySize)) {
        
        __block MIHRSAPrivateKey *rsaPrivateKey;
        __block MIHRSAPublicKey *rsaPublicKey;
        
        /// get rsa private pem Key
        get_pem_key(^(const char *cString) {
            NSData *privateKeyData = strToData(charToStr(cString));
            rsaPrivateKey = [[MIHRSAPrivateKey alloc] initWithData:privateKeyData];
        }, privateKey, false, false);
        
        /// get rsa public pem Key
        get_pem_key(^(const char *cString) {
            NSString *publicKeyStr = base64EncodedFromPEMStr(charToStr(cString));
            NSData *publicKeyData = [GTMBase64 decodeData:strToData(publicKeyStr)];
            rsaPublicKey = [[MIHRSAPublicKey alloc] initWithData:publicKeyData];
        }, publicKey, true, true);
        
        MIHKeyPair *keyPair = [[MIHKeyPair alloc] init];
        [keyPair setPrivate:rsaPrivateKey];
        [keyPair setPublic:rsaPublicKey];
        
        !block ?: block(keyPair, isExist);
    }
}


#pragma mark -
+ (MIHKeyPair *)setPublicKey:(NSString *)aPublicKey privateKey:(NSString *)aPrivateKey {
    if (!aPublicKey && !aPrivateKey) {
        return nil;
    }
    MIHKeyPair *keyPair = [[MIHKeyPair alloc] init];
    if (aPrivateKey && aPrivateKey.length) {
        if (![aPrivateKey hasPrefix:@"-----BEGIN RSA PRIVATE KEY-----"]) {
            aPrivateKey = formatterPrivateKey(aPrivateKey);
        }
        NSData *privateKeyData = strToData(aPrivateKey);
        [keyPair setPrivate:[[MIHRSAPrivateKey alloc] initWithData:privateKeyData]];
    }
    if (aPublicKey && aPublicKey.length) {
        if ([aPublicKey hasPrefix:@"-----BEGIN PUBLIC KEY-----"]) {
            aPublicKey = base64EncodedFromPEMStr(aPublicKey);
        }
        NSData *publicKeyData = [GTMBase64 decodeData:strToData(aPublicKey)];
        [keyPair setPublic:[[MIHRSAPublicKey alloc] initWithData:publicKeyData]];
    }
    return keyPair;
}


+ (void)keyPair:(KeyPairBlock)block publicKey:(NSString *)aPublicKey privateKey:(NSString *)aPrivateKey {
    !block ?: block([self setPublicKey:aPublicKey privateKey:aPrivateKey]);
}


#pragma mark -
+ (NSString *)SHA128_signKeyPair:(MIHKeyPair *)keyPair message:(NSString *)message {
    NSError *signError = nil;
    NSData *data = [message dataUsingEncoding:NSUTF8StringEncoding];
    NSData *signData = [keyPair.private signWithSHA128:data error:&signError];
    !signError ?: ({ NSLog(@"SHA128 sign error: %@",signError); });
    return !signError ? dataToStr([GTMBase64 encodeData:signData]) : nil;
}


+ (NSString *)SHA256_signKeyPair:(MIHKeyPair *)keyPair message:(NSString *)message {
    NSError *signError = nil;
    NSData *data = [message dataUsingEncoding:NSUTF8StringEncoding];
    NSData *signData = [keyPair.private signWithSHA256:data error:&signError];
    !signError ?: ({ NSLog(@"SHA256 sign error: %@",signError); });
    return !signError ? dataToStr([GTMBase64 encodeData:signData]) : nil;
}


+ (NSString *)MD5_signKeyPair:(MIHKeyPair *)keyPair message:(NSString *)message {
    NSError *signError = nil;
    NSData *data = [message dataUsingEncoding:NSUTF8StringEncoding];
    NSData *signData = [keyPair.private signWithMD5:data error:&signError];
    !signError ?: ({ NSLog(@"MD5 sign error: %@",signError); });
    return !signError ? dataToStr([GTMBase64 encodeData:signData]) : nil;
}


#pragma mark -
+ (BOOL)verSignKeyPair:(MIHKeyPair *)keyPair SHA128:(NSString *)signStr message:(NSString *)message {
    NSData *data = [GTMBase64 decodeData:strToData(signStr)];
    return [keyPair.public verifySignatureWithSHA128:data message:strToData(message)];
}


+ (BOOL)verSignKeyPair:(MIHKeyPair *)keyPair SHA256:(NSString *)signStr message:(NSString *)message {
    NSData *data = [GTMBase64 decodeData:strToData(signStr)];
    return [keyPair.public verifySignatureWithSHA256:data message:strToData(message)];
}


+ (BOOL)verSignKeyPair:(MIHKeyPair *)keyPair MD5:(NSString *)signStr message:(NSString *)message {
    NSData *data = [GTMBase64 decodeData:strToData(signStr)];
    return [keyPair.public verifySignatureWithMD5:data message:strToData(message)];
}


#pragma mark - Private method
/** Filter secret key string header, newline, etc */
static inline NSString *base64EncodedFromPEMStr(NSString *PEMStr) {
    return [[[[[[PEMStr componentsSeparatedByString:@"-----"] objectAtIndex:2]
               stringByReplacingOccurrencesOfString:@"\r" withString:@""]
              stringByReplacingOccurrencesOfString:@"\n" withString:@""]
             stringByReplacingOccurrencesOfString:@"\t" withString:@""]
            stringByReplacingOccurrencesOfString:@" " withString:@""];
}


/** Format the public key string, splicing the header and footer */
static inline NSString *formatterPublicKey(NSString *aPublicKey) {
    NSMutableString *mutableStr = [NSMutableString string];
    [mutableStr appendString:BEGIN_PUBLIC_KEY];
    int count = 0;
    for (int i = 0; i < [aPublicKey length]; ++i) {
        unichar c = [aPublicKey characterAtIndex:i];
        if (c == '\n' || c == '\r') {
            continue;
        }
        [mutableStr appendFormat:@"%c", c];
        if (++count == 64) {
            [mutableStr appendString:@"\n"];
            count = 0;
        }
    }
    [mutableStr appendString:END_PUBLIC_KEY];
    return mutableStr.copy;
}


/** Format the private key string, splicing the header and footer */
static inline NSString *formatterPrivateKey(NSString *aPrivateKey) {
    NSMutableString *mutableStr = [NSMutableString string];
    [mutableStr appendString:BEGIN_PRIVATE_KEY];
    int index = 0, count = 0;
    while (index < [aPrivateKey length]) {
        char cStr = [aPrivateKey UTF8String][index];
        if (cStr == '\r' || cStr == '\n') {
            ++index;
            continue;
        }
        [mutableStr appendFormat:@"%c", cStr];
        if (++count == 64) {
            [mutableStr appendString:@"\n"];
            count = 0;
        }
        index++;
    }
    [mutableStr appendString:END_PRIVATE_KEY];
    return mutableStr.copy;
}


/** Determine if a file exists in a sandbox directory */
static inline bool isExistFileWithName(NSString *fileName) {
    if (!fileName || !fileName.length) return false;
    NSString *filePath = [documentsDir() stringByAppendingPathComponent:fileName];
    return (bool)[[NSFileManager defaultManager] fileExistsAtPath:filePath];
}


/** Generating rsa key */
static inline bool rsa_generate_key(RSA **public_key, RSA **private_key, MIHRSAKeySize keySize) {
    BIGNUM *a = BN_new();
    BN_set_word(a, 65537);
    @try {
        RSA *rsa = RSA_new();
        /// use new version. ==> RSA_generate_key() is deprecated. <==
        /// generates a key pair and stores it in the RSA structure provided in rsa.
        /// returns 1 on success or 0 on error.
        int result = RSA_generate_key_ex(rsa, keySize * 8, a, NULL);
        if (result != 1) {
            @throw [NSException openSSLException];
        }
        /// extract public key and private key
        *public_key  = RSAPublicKey_dup(rsa);
        *private_key = RSAPrivateKey_dup(rsa);
        
        RSA_free(rsa);
        return (bool)result;
    }
    @finally {
        /// freed
        BN_free(a);
    }
}


/** Read the pem key */
static inline void get_pem_key(cStrBlock block, RSA *rsa, bool isPublicKey, bool isPkcs8) {
    if (!rsa) return;
    BIO *bp = BIO_new(BIO_s_mem());
    int keylen; char *pem_key;
    @try {
        if (!isPublicKey) {
            EVP_PKEY *key = EVP_PKEY_new();
            EVP_PKEY_assign_RSA(key, rsa);
            if (!isPkcs8)   /// PKCS#1
                PEM_write_bio_RSAPrivateKey(bp, rsa, NULL, NULL, 0, NULL, NULL);
            else    /// PKCS#8
                PEM_write_bio_PrivateKey(bp, key, NULL, NULL, 0, NULL, NULL);
        } else {    /// PKCS#8
            PEM_write_bio_RSA_PUBKEY(bp, rsa);
        }
        
        keylen = BIO_pending(bp);
        pem_key = calloc(keylen + 1, 1);
        BIO_read(bp, pem_key, keylen);
        
        !block ?: block(pem_key);
    }
    @finally {
        BIO_free_all(bp);
        RSA_free(rsa);
        free(pem_key);
    }
}


/** String conversion binary */
static inline NSData *strToData(NSString *string) {
    return [string dataUsingEncoding:NSUTF8StringEncoding];
}


/** Binary conversion string */
static inline NSString *dataToStr(NSData *data) {
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}


/** C string conversion oc string */
static inline NSString *charToStr(const char *cString) {
    return [[NSString alloc] initWithCString:cString encoding:NSUTF8StringEncoding];
}


/** Sandbox documents path */
static inline NSString *documentsDir() {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}


@end


