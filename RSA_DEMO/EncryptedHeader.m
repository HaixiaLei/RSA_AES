//
//  EncryptedHeader.m
//  cryptoDemo
//
//  Created by david on 2019/7/26.
//  Copyright © 2019 Arvin. All rights reserved.
//

#import "EncryptedHeader.h"

@implementation EncryptedHeader


+(void)postWithOrderId:(NSString *)orderID callabck:(Callback)callback {
    [RSACrypt postWithOrderId:orderID callabck:callback];
}



@end
