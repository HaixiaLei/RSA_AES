//
//  ViewController.h
//  cryptoDemo
//
//  Created by Arvin on 17/9/16.
//  Copyright © 2017年 Arvin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextView *publicKey;
@property (weak, nonatomic) IBOutlet UITextView *privateKey;
@property (weak, nonatomic) IBOutlet UITextView *encryptedText;
@property (weak, nonatomic) IBOutlet UITextView *decryptedText;



- (IBAction)onEncrypt:(UIButton *)sender;
- (IBAction)onDecrypt:(UIButton *)sender;
- (IBAction)gotoAES:(id)sender;









@property (weak, nonatomic) IBOutlet UITextView *tv_result;
@property (weak, nonatomic) IBOutlet UITextField *tf_orderID;

- (IBAction)request:(UIButton *)sender;










@end

