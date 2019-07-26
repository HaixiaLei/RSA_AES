//
//  AESViewController.h
//  cryptoDemo
//
//  Created by david on 2019/7/24.
//  Copyright © 2019 Arvin. All rights reserved.
//

#import "ViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface AESViewController : ViewController



@property (weak, nonatomic) IBOutlet UITextField *tf_key;
@property (weak, nonatomic) IBOutlet UITextField *tf_iv;
@property (weak, nonatomic) IBOutlet UITextView *tv_decryptedText;
@property (weak, nonatomic) IBOutlet UITextView *tv_plainText;


- (IBAction)onDecrypt:(id)sender;

- (IBAction)POST:(UIButton *)sender;











@end

NS_ASSUME_NONNULL_END
