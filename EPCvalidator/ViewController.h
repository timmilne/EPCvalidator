//
//  ViewController.h
//  EPCvalidator
//
//  Created by Tim.Milne on 4/20/15.
//  Copyright (c) 2015 Tim.Milne. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

- (void)updateAll;
- (NSString *)Dec2Bin:(NSString *)dec;
- (NSString *)Bin2Dec:(NSString *)bin;
- (NSString *)Dec2Hex:(NSString *)dec;
- (NSString *)Hex2Dec:(NSString *)hex;
- (NSString *)Hex2Bin:(NSString *)hex;
- (NSString *)Bin2Hex:(NSString *)bin;
- (NSString *)CalculateCheckDigit:(NSString *)upc;

@end

