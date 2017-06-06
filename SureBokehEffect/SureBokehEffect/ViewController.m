//
//  ViewController.m
//  SureBokehEffect
//
//  Created by 刘硕 on 2017/6/6.
//  Copyright © 2017年 刘硕. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIImageView *imageView = [[UIImageView alloc]initWithFrame:self.view.bounds];
    [self.view addSubview:imageView];
    
    //高斯模糊滤镜
    CIFilter *filter = [CIFilter filterWithName:@"CIGaussianBlur"];
    UIImage *image = [UIImage imageNamed:@"IMG_1018.JPG"];
    //将UIImage转换为CIImage类型
    CIImage *ciImage = [[CIImage alloc]initWithImage:image];
    [filter setValue:ciImage forKey:kCIInputImageKey];
    //设置模糊程度
    [filter setValue:@8 forKey:kCIInputRadiusKey];//默认为10
    
    //径向渐变滤镜（同心圆）
    CIFilter *radialFilter = [CIFilter filterWithName:@"CIRadialGradient"];
    //图像像素为(1080,1920);
    //将圆点设置为人物头像位置，粗略估计为中心点偏上480
    [radialFilter setValue:[CIVector vectorWithX:image.size.width / 2 Y:image.size.height / 2 + 480] forKey:@"inputCenter"];
    //内圆半径
    [radialFilter setValue:@300 forKey:@"inputRadius0"];
    //外圆半径
    [radialFilter setValue:@500 forKey:@"inputRadius1"];
    
    CIFilter *linefilter = [CIFilter filterWithName:@"CILinearGradient"];
    [linefilter setValue:[CIVector vectorWithCGPoint:CGPointMake(0, 200)] forKey:@"inputPoint0"];
    [linefilter setValue:[CIVector vectorWithCGPoint:CGPointMake(200, 200)] forKey:@"inputPoint1"];
    
    //滤镜混合
    CIFilter *maskFilter = [CIFilter filterWithName:@"CIBlendWithMask"];
    //原图
    [maskFilter setValue:ciImage forKey:kCIInputImageKey];
    //高斯模糊处理后的图片
    [maskFilter setValue:filter.outputImage forKey:kCIInputBackgroundImageKey];
    //遮盖图片，这里为径向渐变所生成
    [maskFilter setValue:radialFilter.outputImage forKey:kCIInputMaskImageKey];
    
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef endImageRef = [context createCGImage:maskFilter.outputImage fromRect:ciImage.extent];
    imageView.image = [UIImage imageWithCGImage:endImageRef];

    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
