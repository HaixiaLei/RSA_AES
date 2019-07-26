//
//  EncryptedHeader.h
//  cryptoDemo
//
//  Created by david on 2019/7/26.
//  Copyright © 2019 Arvin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RSACrypt.h"

NS_ASSUME_NONNULL_BEGIN

@interface EncryptedHeader : NSObject


+(void)postWithOrderId:(NSString *)orderID callabck:(Callback)callback;


@end

NS_ASSUME_NONNULL_END
