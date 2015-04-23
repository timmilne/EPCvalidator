//
//  ViewController.m
//  EPCvalidator
//
//  Created by Tim.Milne on 4/20/15.
//  Copyright (c) 2015 Tim.Milne. All rights reserved.
//

#import "ViewController.h"

// NSString
@import Foundation;

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextField *Dpt_fld;
@property (weak, nonatomic) IBOutlet UITextField *Cls_fld;
@property (weak, nonatomic) IBOutlet UITextField *Itm_fld;
@property (weak, nonatomic) IBOutlet UITextField *Ser_fld;
@property (weak, nonatomic) IBOutlet UITextField *SGTIN_URI_fld;
@property (weak, nonatomic) IBOutlet UITextField *SGTIN_Hex_fld;
@property (weak, nonatomic) IBOutlet UITextField *GIAI_URI_fld;
@property (weak, nonatomic) IBOutlet UITextField *GIAI_Hex_fld;
@property (weak, nonatomic) IBOutlet UITextField *GID_URI_fld;
@property (weak, nonatomic) IBOutlet UITextField *GID_Hex_fld;
@end

// Global values
NSString *SGTIN_URI_Prefix = @"urn:epc:tag:sgtin-96:1.";
NSString *SGTIN_Bin_Prefix = @"00110000";
NSString *GIAI_URI_Prefix  = @"urn:epc:tag:giai-96:0.";
NSString *GIAI_Bin_Prefix  = @"00110100";
NSString *GID_URI_Prefix   = @"urn:epc:tag:gid-96:";
NSString *GID_Bin_Prefix   = @"00110101";

NSDictionary *dictBin2Hex;
NSDictionary *dictHex2Bin;

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    dictBin2Hex = [[NSDictionary alloc] initWithObjectsAndKeys:
                        @"0",@"0000",
                        @"1",@"0001",
                        @"2",@"0010",
                        @"3",@"0011",
                        @"4",@"0100",
                        @"5",@"0101",
                        @"6",@"0110",
                        @"7",@"0111",
                        @"8",@"1000",
                        @"9",@"1001",
                        @"A",@"1010",
                        @"B",@"1011",
                        @"C",@"1100",
                        @"D",@"1101",
                        @"E",@"1110",
                        @"F",@"1111", nil];
    
    dictHex2Bin = [[NSDictionary alloc] initWithObjectsAndKeys:
                        @"0000",@"0",
                        @"0001",@"1",
                        @"0010",@"2",
                        @"0011",@"3",
                        @"0100",@"4",
                        @"0101",@"5",
                        @"0110",@"6",
                        @"0111",@"7",
                        @"1000",@"8",
                        @"1001",@"9",
                        @"1010",@"A",
                        @"1011",@"B",
                        @"1100",@"C",
                        @"1101",@"D",
                        @"1110",@"E",
                        @"1111",@"F", nil];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// Delegate to dimiss keyboard after return
// Set the delegate of any input text field to the ViewController class
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}

// All the edit fields point here, after you end the edit and hit return
- (IBAction)Update:(id)sender {
    // Get and validate inputs
    NSString *Dpt = [self.Dpt_fld text];
    NSString *Cls = [self.Cls_fld text];
    NSString *Itm = [self.Itm_fld text];
    NSString *Ser = [self.Ser_fld text];
    
    // Make sure the inputs are not too long (especially the Serial Number)
    if ([Dpt length] > 3) {
        Dpt = [Dpt substringToIndex:3];
        [self.Dpt_fld setText:Dpt];
    }
    if ([Cls length] > 2) {
        Cls = [Cls substringToIndex:2];
        [self.Cls_fld setText:Cls];
    }
    if ([Itm length] > 4) {
        Itm = [Itm substringToIndex:4];
        [self.Itm_fld setText:Itm];
    }
    if ([Ser length] > 10) {
        // SGTIN serial number max = 11
        // GIAI serial number max = 18
        // GID serial number max = 10
        // Shorten to the least common denominator for now
        Ser = [Ser substringToIndex:10];
        [self.Ser_fld setText:Ser];
    }

    
    // SGTIN - e.g. urn:epc:tag:sgtin-96:1.04928100.08570.12345
    //              3030259932085E8000003039
    //
    // A UPC 12 can be promoted to an EAN14 by right shifting and adding to zeros to the front.
    // One of these zeroes is an indicator digit, which is '0' for items, and this will be moved
    // to the front of the item reference.  The other is the country code, and can be omitted
    // for US and Canada, as those country codes are '0'.
    //
    // Here is how to pack the SGTIN-96 into the EPC
    // 8 bits are the header: 00110000 or 0x30 (SGTIN-96)
    // 3 bits are the Filter: 001 (1 POS Item)
    // 3 bits are the Partition: 100 (4, so 8 digits for manager, 5 for item)
    // 27 bits are the manager number: 049 + Department + Class (8 digits)
    // 17 bits are the 0 prefixed Item: 0 + Item (5 digits, no check digit)
    // 38 bits are the serial number (guaranteed 11 digits)
    // = 96 bits
    NSString *Dpt_Cls_dec = [NSString stringWithFormat:@"049%@%@",Dpt,Cls];
    NSString *Dpt_Cls_bin = [self Dec2Bin:(Dpt_Cls_dec)];
    for (int i=(int)[Dpt_Cls_bin length]; i<(int)27; i++) {
        Dpt_Cls_bin = [NSString stringWithFormat:@"0%@", Dpt_Cls_bin];
    }
    NSString *Itm_dec = [NSString stringWithFormat:@"0%@",Itm];
    NSString *Itm_bin = [self Dec2Bin:(Itm_dec)];
    for (int i=(int)[Itm_bin length]; i<(int)17; i++) {
        Itm_bin = [NSString stringWithFormat:@"0%@", Itm_bin];
    }
    NSString *Ser_bin = [self Dec2Bin:(Ser)];
    for (int i=(int)[Ser_bin length]; i<(int)38; i++) {
        Ser_bin = [NSString stringWithFormat:@"0%@", Ser_bin];
    }
    NSString *SGTIN_Bin_str = [NSString stringWithFormat:@"%@001100%@%@%@",SGTIN_Bin_Prefix,Dpt_Cls_bin,Itm_bin,Ser_bin];
    NSString *SGTIN_Hex_str = [self Bin2Hex:(SGTIN_Bin_str)];
    NSString *SGTIN_URI_str = [NSString stringWithFormat:@"%@%@.%@.%@",SGTIN_URI_Prefix,Dpt_Cls_dec,Itm_dec,Ser];

// Check with http://www.kentraub.net/tools/tagxlate/EPCEncoderDecoder.html
//    NSString *SGTIN_Hex_Ken_str = @"3030259932085E8000003039";
//    NSString *GSTIN_Bin_Ken_str = [self Hex2Bin:SGTIN_Hex_Ken_str];
    
    [self.SGTIN_URI_fld setText:SGTIN_URI_str];
    [self.SGTIN_Hex_fld setText:SGTIN_Hex_str];

    
    // GIAI - e.g. urn:epc:tag:giai-96:0.49281008570.12345
    //             34056F2C1077400000003039
    //
    // Here is how to pack the GIAI-96 into the EPC
    // 8 bits are the header: 00110100 or 0x34 (GIAI-96)
    // 3 bits are the Filter: 000 (All Others)
    // 3 bits are the Partition: 001 (1)
    // 37 bits are the manager number: 49 + Department + Class + Item (11 digits)
    // 45 bits are the serial number (guaranteed 14 digits)
    // = 96 bits
    NSString *Dpt_Cls_Itm_dec = [NSString stringWithFormat:@"49%@%@%@",Dpt,Cls,Itm];
    NSString *Dpt_Cls_Itm_bin = [self Dec2Bin:(Dpt_Cls_Itm_dec)];
    for (int i=(int)[Dpt_Cls_Itm_bin length]; i<(int)37; i++) {
        Dpt_Cls_Itm_bin = [NSString stringWithFormat:@"0%@", Dpt_Cls_Itm_bin];
    }
    Ser_bin = [self Dec2Bin:(Ser)];
    for (int i=(int)[Ser_bin length]; i<(int)45; i++) {
        Ser_bin = [NSString stringWithFormat:@"0%@", Ser_bin];
    }
    NSString *GIAI_Bin_str = [NSString stringWithFormat:@"%@000001%@%@",GIAI_Bin_Prefix,Dpt_Cls_Itm_bin,Ser_bin];
    NSString *GIAI_Hex_str = [self Bin2Hex:(GIAI_Bin_str)];
    NSString *GIAI_URI_str = [NSString stringWithFormat:@"%@%@.%@",GIAI_URI_Prefix,Dpt_Cls_Itm_dec,Ser];

// Check with http://www.kentraub.net/tools/tagxlate/EPCEncoderDecoder.html
//    NSString *GIAI_Hex_Ken_str = @"34056F2C1077400000003039";
//    NSString *GIAI_Bin_Ken_str = [self Hex2Bin:GIAI_Hex_Ken_str];
    
    [self.GIAI_URI_fld setText:GIAI_URI_str];
    [self.GIAI_Hex_fld setText:GIAI_Hex_str];

    
    // GID - e.g. urn:epc:tag:gid-96:4928100.85702.12345
    //            3504B3264014EC6000003039
    //
    // Here is how to pack the GID-96 into the EPC
    // 8 bits are the header: 00110101 or 0x35 (GID-96)
    // No Filter
    // No Partition
    // 28 bits are the manager number: 00 + 49 + Department + Class (9 digits)
    // 24 bits are the item number (object class): 000 + Item + Check Digit (8 digits)
    // 36 bits are the serial number (guaranteed 10 digits)
    // = 96 bits
    Dpt_Cls_dec = [NSString stringWithFormat:@"49%@%@",Dpt,Cls];
    Dpt_Cls_bin = [self Dec2Bin:(Dpt_Cls_dec)];
    for (int i=(int)[Dpt_Cls_bin length]; i<(int)28; i++) {
        Dpt_Cls_bin = [NSString stringWithFormat:@"0%@", Dpt_Cls_bin];
    }
    NSString *upc = [NSString stringWithFormat:@"49%@%@%@",Dpt,Cls,Itm];
    NSString *checkDigit = [self CalculateCheckDigit:upc];
    NSString *Itm_Chk_dec = [NSString stringWithFormat:@"%@%@",Itm,checkDigit];
    NSString *Itm_Chk_bin = [self Dec2Bin:(Itm_Chk_dec)];
    for (int i=(int)[Itm_Chk_bin length]; i<(int)24; i++) {
        Itm_Chk_bin = [NSString stringWithFormat:@"0%@", Itm_Chk_bin];
    }
    Ser_bin = [self Dec2Bin:(Ser)];
    for (int i=(int)[Ser_bin length]; i<(int)36; i++) {
        Ser_bin = [NSString stringWithFormat:@"0%@", Ser_bin];
    }
    
    NSString *GID_Bin_str = [NSString stringWithFormat:@"%@%@%@%@",GID_Bin_Prefix,Dpt_Cls_bin,Itm_Chk_bin,Ser_bin];
    NSString *GID_Hex_str = [self Bin2Hex:(GID_Bin_str)];
    NSString *GID_URI_str = [NSString stringWithFormat:@"%@%@.%@.%@",GID_URI_Prefix,Dpt_Cls_dec,Itm_Chk_dec,Ser];

// Check with http://www.kentraub.net/tools/tagxlate/EPCEncoderDecoder.html
//    NSString *GID_Hex_Ken_str = @"3504B3264014EC6000003039";
//    NSString *GID_Bin_Ken_str = [self Hex2Bin:GID_Hex_Ken_str];
    
    [self.GID_URI_fld setText:GID_URI_str];
    [self.GID_Hex_fld setText:GID_Hex_str];
}

- (NSString *)Dec2Bin:(NSString *)dec {
    return [self Hex2Bin:([self Dec2Hex:(dec)])];
}

- (NSString *)Bin2Dec:(NSString *)bin {
    return [self Hex2Dec:([self Bin2Hex:(bin)])];
}

- (NSString *)Dec2Hex:(NSString *)dec {
// TPM: This did not work with a number longer than 32 bits...
//    return [NSString stringWithFormat:@"%X",[dec intValue]];
// TPM: So switched to a 64 bit long - watch out if you go longer than that...
    return [NSString stringWithFormat:@"%llX",[dec longLongValue]];
}

- (NSString *)Hex2Dec:(NSString *)hex {
    NSScanner *scanner = [NSScanner scannerWithString:hex];
    unsigned int tmpDec;
    [scanner scanHexInt:&tmpDec];
    return [NSString stringWithFormat:@"%d",tmpDec];
}

- (NSString *)Bin2Hex:(NSString *)bin {
    NSString *hex = @"";

    for (int i = 0;i < [bin length]; i+=4)
    {
        NSString *binKey = [bin substringWithRange: NSMakeRange(i, 4)];
        hex = [NSString stringWithFormat:@"%@%@",hex,[dictBin2Hex valueForKey:binKey]];
    }
    
    return hex;
}

- (NSString *)Hex2Bin:(NSString *)hex {
    NSString *bin = @"";
    
    for (int i = 0;i < [hex length]; i++)
    {
        NSString *hexKey = [hex substringWithRange: NSMakeRange(i, 1)];
        bin = [NSString stringWithFormat:@"%@%@",bin,[dictHex2Bin valueForKey:hexKey]];
    }
    
    return bin;
}

- (NSString *)CalculateCheckDigit:(NSString *)upc {
    int sumOdd = 0;
    int sumEven = 0;
    NSRange range = {0, 1};
    
    for (; range.location < [upc length]; range.location++) {
        sumOdd += [[upc substringWithRange:range] integerValue];
        range.location++;
        if (range.location < [upc length]){
            sumEven += [[upc substringWithRange:range] integerValue];
        }
    }
    
    return [NSString stringWithFormat:@"%d",((10 - ((3*sumOdd + sumEven)%10))%10)];
}

@end
