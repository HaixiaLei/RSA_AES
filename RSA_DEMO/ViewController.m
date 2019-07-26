//
//  ViewController.m
//  cryptoDemo
//
//  Created by Arvin on 17/9/16.
//  Copyright © 2017年 Arvin. All rights reserved.
//

#import "ViewController.h"
#import "RSACrypt.h"
#import "AESViewController.h"

static NSString *const archiver = @"keyPair.archiver";

@interface ViewController ()

@property (nonatomic, strong) MIHKeyPair *keyPair;
@property (nonatomic, strong) NSString *encryptStr;
@property (nonatomic, copy) NSString *sha128,*sha256,*md5;

@end

@implementation ViewController


/*
 *   按下POST按钮触发的事件
 */
- (IBAction)request:(UIButton *)sender {
    
    //关闭键盘
    [self.view endEditing:YES];

    //POST请求数据
    [RSACrypt postWithOrderId:self.tf_orderID.text
                     callabck:^(NSError *error, int code, id response) {
        
        // 1.发生错误
        if (code != 200) {
            NSString *descript = error.localizedDescription; // 错误描述
            [self performSelectorOnMainThread:@selector(inputText:) withObject:descript waitUntilDone:YES];//一定要回到主线程，才更新UI！！！
            return ;
        }
        
        // 2.拿到了正确的数据
        NSDictionary *dict = response;   //这个字典就是获取到的有效数据
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:0];
        NSString *dataStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        [self performSelectorOnMainThread:@selector(inputText:) withObject:dataStr waitUntilDone:YES];//一定要回到主线程，才更新UI！！！
    }];
}






/*
 *  ！！！！！！！！！！！！下方内容不需要理会！！！！！！！！！！
 */


/*
 *  ！！！！！！！！！！！！下方内容不需要理会！！！！！！！！！！
 */


/*
 *  ！！！！！！！！！！！！下方内容不需要理会！！！！！！！！！！
 */









































































































































































#pragma mark -
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    //私钥默认值
    self.privateKey.text = RSA_PRIVATE_KEY;
    
    //密文默认值
    self.encryptedText.text = @"cXjTba8UCDEAt6Nuf+PNYVYiSFSd8oILHMi8pV8AtmgV67wor5APT1oNi0LmJm6zpLLFFZxekFaps0FpAFtc6ERejRFExkLsKlWM2Q/JsUNhwun6VQe7tfzIgEaUzsOEBwQyQasjQZoJzHEesZKiMSptxlrfpWQAb0PjoVqFy67lt7LROrPVY0wnqKxPo3GMmNF+Q8qM0xHKNs9Q0zKzqenqP5GMBOaJxzijSEm4ufFdUJ0RChXdtVAdSci98xLRSKqQu0CzIVpCPd6OMkOhhV3u//02/tpN4HTLCPQy+phxFj1wcuAFdXVbypBXqGn8er4NqvFPieuM+ij1252Q6A==";
}


- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}


- (IBAction)onEncrypt:(UIButton *)sender {

}

/*用公钥加密*/
- (void)encryptByPublicKey:(MIHKeyPair *)keyPair {

}

- (IBAction)onDecrypt:(UIButton *)sender {
    __weak typeof(self) weakSelf = self;
    
    NSString *g = @"";// 公钥
    if (self.publicKey.text.length > 5) {
        g = self.publicKey.text;
    }
    
    NSString *s = @"";// 私钥
    if (self.privateKey.text.length > 5) {
        s = self.privateKey.text;
    }
    
    
    [RSACrypt keyPair:^(MIHKeyPair *keyPair) {
        
        [weakSelf decryptByPrivateKey:keyPair];
        
    } publicKey:g privateKey:s];
}

- (IBAction)gotoAES:(id)sender {
    AESViewController *vc = [[AESViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

/*用私钥解密*/
- (void)decryptByPrivateKey:(MIHKeyPair *)keyPair {
    NSString *enStr = self.encryptedText.text;
    NSString *deStr = [RSACrypt privateDecrypt:keyPair decryptStr:enStr];
    
    NSLog(@"密文是:\n%@", enStr);
    NSLog(@"私钥解密后的明文是:\n%@", deStr);
    
    self.decryptedText.text = deStr;
}









- (void)inputText:(NSString *)text {
    self.tv_result.text = text;
}

@end



