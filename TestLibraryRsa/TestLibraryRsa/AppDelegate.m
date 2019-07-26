//
//  AppDelegate.m
//  TestLibraryRsa
//
//  Created by david on 2019/7/26.
//  Copyright © 2019 david. All rights reserved.
//

#import "AppDelegate.h"
#import <EncryptedChannel.h>

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    
    [RSACrypt postWithOrderId:@"" callabck:^(NSError *error, int code, id response) {
        //当且仅当code==200时，为正确数据，此时response是一个NSDictionary类型。
    }];
    
    
    
    //POST请求数据
    [RSACrypt postWithOrderId:@"9900001"
                     callabck:^(NSError *error, int code, id response) {
                         
                         // 1.发生错误
                         if (code != 200) {
                             NSString *descript = error.localizedDescription; // 错误描述
                             NSLog(@"\n\nError occur:\n%@",descript);
                             
                             return ;
                         }
                         
                         // 2.拿到了正确的数据
                         NSDictionary *dict = response;   //这个字典就是获取到的有效数据
                         NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:0];
                         NSString *dataStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                         
                         NSLog(@"\n\nSuccess:\n%@",dataStr);
                     }];
    
    
    
    
    
    
    
    
    
    
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
