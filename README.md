# SureBokehEffect
滤镜初探，三步集成美图软件背景虚化效果
######【前文提要】
因工作一直没有接触过滤镜领域，所以在闲暇之余粗略的阅读了下文档，尝试实现某些效果，纯属娱乐，大神无视勿喷。
![左侧为原图，右侧为背景虚化后的效果图](http://upload-images.jianshu.io/upload_images/1767950-f82f3377879d68de.JPG?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
大致为突显女主上半身形象，并以上半身为中心渐变模糊扩散的效果。
######一、为图片添加高斯模糊滤镜
既然需要执行滤镜操作，那肯定离不开[Core Image](https://developer.apple.com/reference/coreimage?language=objc)这一强大的框架了，感兴趣的童鞋可以点击进入查看文档。本篇文章中主要使用其几种常用的滤镜。对于模糊效果，系统提供了很多样式，但毕竟不是设计，无法通过肉眼区别它们之间的区别，因此这里简单的选取了高斯模糊效果。

首先我们来创建高斯模糊滤镜，对于** CIFilter**就不做过多的介绍了。将具体滤镜名称传入即可创建对应滤镜样式。这里需要注意的我们传入的图片信息并非我们常用的**UIImage**，因为**UIImage**是不可变的，只能通过已存在的图片创建它，而滤镜需要对原始图片进行修改，因此这里我们需要将**UIImage**转换为**CIImage**类型做处理。
```
//高斯模糊滤镜
CIFilter *filter = [CIFilter filterWithName:@"CIGaussianBlur"];
UIImage *image = [UIImage imageNamed:@"IMG_0857.JPG"];
//将UIImage转换为CIImage类型
CIImage *ciImage = [[CIImage alloc]initWithImage:image];
//设置输入的图片信息
[filter setValue:ciImage forKey:kCIInputImageKey];
//设置模糊程度
[filter setValue:@8 forKey:kCIInputRadiusKey];//默认为10
```
执行如上操作生成的效果如下，也即是文章顶部效果图中的模糊效果：
![高斯模糊效果图](http://upload-images.jianshu.io/upload_images/1767950-7d1cda504f0818fc.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
######二、确定显示区域
常用美图软件的童鞋们会发现背景虚化效果是存在两种显示调节形式的，一种为两个同心圆确定区域，一种为平行矩形确定区域。以美图秀秀为例。
![美图秀秀操作效果](http://upload-images.jianshu.io/upload_images/1767950-4526aaa2d64667d8.JPG?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
######那如何通过代码实现如上效果呢？
其实同心圆与平行矩形在代码中对应分别为[CIRadialGradient](https://developer.apple.com/library/content/documentation/GraphicsImaging/Reference/CoreImageFilterReference/#//apple_ref/doc/filter/ci/CIRadialGradient)和[CILinearGradient](https://developer.apple.com/library/content/documentation/GraphicsImaging/Reference/CoreImageFilterReference/#//apple_ref/doc/filter/ci/CILinearGradient)滤镜。我们可称其为径向渐变滤镜。

这里拿同心圆的径向渐变滤镜为例通过代码生成一个内圆半径为300，外圆半径为500的同心圆。需要注意的是设置圆点或半径并不是以iOS设备的屏幕分辨率为参照的，而是由原图像信息来决定的。例如原图片像素为（750，1334），若想将同心圆的圆点定位在图片中心，需要将inputCenter设置为（375，667），同理对于同心圆中内圆与外圆的半径设置也是一样。并且还需要坐标系问题，在这里（0，0）点属于屏幕左下角而非左上角。也就说他使用的是现实中的直角坐标系。
```
//径向渐变滤镜（同心圆）
CIFilter *radialFilter = [CIFilter filterWithName:@"CIRadialGradient"];
//圆点
[radialFilter setValue:[CIVector vectorWithX:image.size.width / 2 Y:image.size.height / 2] forKey:@"inputCenter"];
//内圆半径
[radialFilter setValue:@300 forKey:@"inputRadius0"];
//外圆半径
[radialFilter setValue:@500 forKey:@"inputRadius1"];
```
上述代码可生成如下图效果：
![径向渐变滤镜（同心圆）效果图](http://upload-images.jianshu.io/upload_images/1767950-e45b3c770d76dfbc.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
根据效果图我们可以看出，内圆部分是完全透明的，内圆与外圆之间部分呈现渐变模糊效果。
######三、背景虚化效果合成
通过上两步的操作我们生成了高斯模糊后的图片并且确定了所需显示的区域，接下来我们要通过**CIBlendWithMask**滤镜来进行效果合成。对于**CIBlendWithMask**滤镜，字面意思为遮盖物混合滤镜，文档解释过于草率，我们根据文档给予的效果图来分析：

![CIBlendWithMask滤镜](http://upload-images.jianshu.io/upload_images/1767950-3a014b0dd8341cc0.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
如图所示，** CIBlendWithMask**滤镜可将左侧的三张图片合成为右侧的输出图片。具体的执行流程是，左一图做为左二图的填充，后续在与左三进行混合。**（这张图建议大家仔细观察下）**

######那如何通过这种混合方式实现自己的需求呢？

我们可以将左三图分别替换为原图、同心圆、高斯模糊滤镜生成的效果图。这样即可实现我们想要的背景虚化的效果了。也可理解为我们将需要高亮显示的位置在原图上扣出来再与整体的模糊效果进行混合，代码如下：
```
//滤镜混合
CIFilter *maskFilter = [CIFilter filterWithName:@"CIBlendWithMask"];
//原图
[maskFilter setValue:ciImage forKey:kCIInputImageKey];
//高斯模糊处理后的图片
[maskFilter setValue:filter.outputImage forKey:kCIInputBackgroundImageKey];
//遮盖图片，这里为径向渐变所生成的同心圆或同轴矩形
[maskFilter setValue:radialFilter.outputImage forKey:kCIInputMaskImageKey];
```

最后通过**CIContext**生成执行滤镜操作后的图片，给**imageView**赋值。

⚠️注意：若需要测试高斯模糊等效果，均需要调用下方代码，将对应的输出图像更改下即可，比如想测试高斯模糊效果，将下方代码**maskFilter.outputImage **更改为**filter.outputImage**即可。
```
CIContext *context = [CIContext contextWithOptions:nil];
CGImageRef endImageRef = [context createCGImage:maskFilter.outputImage fromRect:ciImage.extent];
imageView.image = [UIImage imageWithCGImage:endImageRef];
```
因滤镜操作**CPU**渲染会比**GPU**要慢，所以效果呈现会慢一些，换做真机就没问题啦。另外仍可以继续优化，将当前的**context**替换为**OpenGL**的**context**，代码如下：
```
CIContext *context = [CIContext contextWithEAGLContext:[[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2]];
```
使用它的优点是渲染的图像保存在**GPU**上，并不需要拷贝回**CPU**内存。并且如果需要实时滤镜处理的话，这种创建形式更好。

最后不要忘记内存泄漏问题，对于非OC对象要手动进行内存释放，前一篇文章[关于内存泄漏，还有哪些是你不知道的？](http://www.jianshu.com/p/d465831aebbf)也有描述过。因此需要添加内存释放代码
```
CGImageRelease(endImageRef);
```

本文暂时写到这里，demo已上传Github，喜欢的可以点个赞关注我，比心(｡･ω･｡)ﾉ♡
[https://github.com/LSure/SureBokehEffect](https://github.com/LSure/SureBokehEffect)

最后放一张模拟器中的效果图
![最终效果图](http://upload-images.jianshu.io/upload_images/1767950-596529984356b8f9.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

另附感言：P图软件公司的开发真不容易啊～
