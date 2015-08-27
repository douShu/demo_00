//
//  ViewController.m
//  demoForNSURLSession
//
//  Created by 逗叔 on 15/8/27.
//  Copyright (c) 2015年 逗叔. All rights reserved.
//

#import "ViewController.h"
#import "NSString+Hash.h"

/**
 *  续传文件的本地路径
 */
#define localResumeDataPath @"/Users/doudou/Documents/iOS学习/Demo-代码/demo_00/demoForNSURLSession/续传数据"

@interface ViewController () <NSURLSessionDownloadDelegate>
/**
 *  进度条
 */
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
/**
 *  绘画
 */
@property (nonatomic, strong) NSURLSession *session;
/**
 *  下载任务
 */
@property (nonatomic, strong) NSURLSessionDownloadTask *downloadTask;
/**
 *  续传数据
 */
@property (nonatomic, strong) NSData *resumeData;
/**
 *  url
 */
@property (nonatomic, strong) NSURL *url;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {

    [self downLoadData];
}

- (void)downLoadData {

    // 创建url
    NSString *urlStr = @"http://dldir1.qq.com/qqfile/QQforMac/QQ_V4.0.3.dmg";
    urlStr = [urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *url = [NSURL URLWithString:urlStr];
    self.url = url;
    
    // 从磁盘中查看续传的数据
    NSString *filePath = [self filePathWithURL:url];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        
        NSLog(@"%@", filePath);

        // 读取续传数据
        self.resumeData = [NSData dataWithContentsOfFile:filePath];
        
        // 断点续传
        self.downloadTask = [self.session downloadTaskWithResumeData:self.resumeData];
    } else {
        
        // 异步下载
        self.downloadTask = [self.session downloadTaskWithURL:url];
    }
    [self.downloadTask resume];
}

#pragma mark - /****************** 暂停/继续下载任务 ******************/
// 暂停
- (IBAction)pauseDownload {

    [self.downloadTask cancelByProducingResumeData:^(NSData *resumeData) {
        
        self.resumeData = resumeData;
        
        // 创建续传文件路径
        NSString *filePath = [self filePathWithURL:self.url];
        
        // 将续传数据存入磁盘中
        [self.resumeData writeToFile:filePath atomically:YES];
    }];
}
// 续传文件存储的文件名
- (NSString *)filePathWithURL: (NSURL *)url {
    
    NSString *str = url.absoluteString.md5String;

    return [[localResumeDataPath stringByAppendingPathComponent:str] stringByAppendingString:@"~resute"];
}
// 继续
- (IBAction)continueDownload:(id)sender {

    [self downLoadData];
}

#pragma mark - /****************** 代理方法 ******************/
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {

    NSLog(@"%@", location);
    
    NSLog(@"%@", NSHomeDirectory());
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes {
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {

    dispatch_async(dispatch_get_main_queue(), ^{
        
        self.progressView.progress = (float)totalBytesWritten / totalBytesExpectedToWrite;
        
        NSLog(@"%.2f", self.progressView.progress);
    });
}

#pragma mark - /****************** 懒加载 ******************/
- (NSURLSession *)session {

    if(_session == nil) {

        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        _session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
    }
    return _session;
}
@end
