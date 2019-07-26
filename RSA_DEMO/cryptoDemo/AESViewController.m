//
//  AESViewController.m
//  cryptoDemo
//
//  Created by david on 2019/7/24.
//  Copyright © 2019 Arvin. All rights reserved.
//

#import "AESViewController.h"
#import "RSACrypt.h"

@interface AESViewController ()

@end

@implementation AESViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 60, 60, 30)];
    button.backgroundColor = [UIColor redColor];
    [button setTitle:@"返回" forState:0];
    [self.view addSubview:button];
    [button addTarget:self action:@selector(onBack) forControlEvents:UIControlEventTouchUpInside];
    
    

    
    
    
    
    
    
    
    
    
//    NSString *text = @"https://j38922.com/";
//    NSString *entext = [RSACrypt encrypt:text];
//    
//    NSLog(@"\n原文是：%@，密文：%@",text,entext);
//    
//    
//    //密文
//    NSString *decrypted_text = @"57156cf3d6ecec286afdeb9f7590895e6080ab72a008d6c4";
//    
//    
//    NSString *plain_text = @"";
//    
//    plain_text = [RSACrypt decrypt:decrypted_text];
//    
//    NSLog(@"\n\n密文是：%@,,,AES解密:%@",decrypted_text,plain_text);
    
    
    
}

- (void)onBack {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)onDecrypt:(id)sender {
    
    self.tv_plainText.text = @"";
    
    NSString *miwen = self.tv_decryptedText.text;
    NSString *key = self.tf_key.text;
    NSString *iv = self.tf_iv.text;
    
    NSString *plain_text = [RSACrypt decrypt:miwen key:key iv:iv];
    
    self.tv_plainText.text = plain_text;
}

- (IBAction)POST:(UIButton *)sender {
    
    [RSACrypt postWithOrderId:@"9900001" callabck:^(NSError *error, int code, id response) {
        
    }];
    
    
    
}
@end
