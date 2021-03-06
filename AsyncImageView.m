//
//  AsyncImageView.m
//  Postcard
//
//  Created by markj on 2/18/09.
//  Copyright 2009 Mark Johnson. You have permission to copy parts of this code into your own projects for any use.
//  www.markj.net
//

#import "AsyncImageView.h"
#include <syslog.h>


// This class demonstrates how the URL loading system can be used to make a UIView subclass
// that can download and display an image asynchronously so that the app doesn't block or freeze
// while the image is downloading. It works fine in a UITableView or other cases where there
// are multiple images being downloaded and displayed all at the same time. 

@implementation AsyncImageView

- (void)dealloc {
  [connection cancel]; //in case the URL is still downloading
  [connection release];
  [data release]; 
  [super dealloc];
}

- (void)loadImageFromURL:(NSURL*)url {
  if (connection!=nil) { [connection release]; } //in case we are downloading a 2nd image
  if (data!=nil) { [data release]; }
  
  NSURLRequest* request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10.0];
  syslog(LOG_DEBUG, "loadImageFromURL got a request..");
  connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
  //TODO error handling, what if connection is nil?

  if (connection)
    syslog(LOG_DEBUG, "loadImageFromURL got a connection..");
  else
    syslog(LOG_ERR, "loadImageFromURL got a nil connection!");
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection 
           willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
  syslog(LOG_DEBUG, "willCacheResponse..");
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
  syslog(LOG_DEBUG, "connection didReceiveResponse");
}

-(void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error
{
  syslog(LOG_ERR, "NSURLConnection, didFailWithError..");
}

//the URL connection calls this repeatedly as data arrives
- (void)connection:(NSURLConnection *)theConnection didReceiveData:(NSData *)incrementalData {
  syslog(LOG_DEBUG, "connection didReceiveData..");
  if (data==nil) { 
    data = [[[NSMutableData alloc] initWithCapacity:2048] retain]; 
  }
  [data appendData:incrementalData];
}

//the URL connection calls this once all the data has downloaded
- (void)connectionDidFinishLoading:(NSURLConnection*)theConnection {
  syslog(LOG_DEBUG, "connectionDidFinishLoading..");
  //so self data now has the complete image 
  [connection release];
  connection=nil;
  if ([[self subviews] count]>0) {
    //then this must be another image, the old one is still in subviews
    [[[self subviews] objectAtIndex:0] removeFromSuperview]; //so remove it (releases it also)
  }
  
  //make an image view for the image
  UIImageView* imageView = [[[UIImageView alloc] initWithImage:[UIImage imageWithData:data]] autorelease];
  //make sizing choices based on your needs, experiment with these. maybe not all the calls below are needed.
  imageView.contentMode = UIViewContentModeScaleAspectFit;
  imageView.autoresizingMask = ( UIViewAutoresizingFlexibleWidth || UIViewAutoresizingFlexibleHeight );
  [self addSubview:imageView];
  imageView.frame = self.bounds;
  [imageView setNeedsLayout];
  [self setNeedsLayout];

  [data release]; //don't need this any more, its in the UIImageView now
  data=nil;
}

//just in case you want to get the image directly, here it is in subviews
- (UIImage*) image {
  UIImageView* iv = [[self subviews] objectAtIndex:0];
  return [iv image];
}

@end
