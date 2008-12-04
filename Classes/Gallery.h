//
//  Gallery.h
//  iGallery
//
//  Created by Matt Wright on 04/10/2008.
//  Copyright 2008 Matt Wright Consulting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CFNetwork/CFNetwork.h>
#import "AsyncSocket.h"

@interface Gallery : NSObject {
  AsyncSocket *socket;
  id delegate;
  
  NSData *uploadData;
  
  NSString *galleryURL;
  NSString *authToken;
  
  CFHTTPMessageRef messageRef;
  
  int uploadChunkSize;
}

@property (nonatomic,retain) NSString *galleryURL;
@property (nonatomic,assign) id delegate;

- (id)initWithGalleryURL:(NSString*)url;
- (id)initWithGalleryURL:(NSString*)url delegate:(id)delegate;

- (NSURLRequest*)requestForCommandDictionary:(NSDictionary*)dict;
- (NSURLRequest*)requestForCommandDictionary:(NSDictionary*)dict imageName:(NSString*)name;
- (NSDictionary*)commandDictionaryFromData:(NSData*)data;

- (BOOL)beginAsyncRequest:(NSURLRequest*)request;
- (BOOL)beginAsyncRequest:(NSURLRequest*)request withTag:(long)tag;

- (id)sendSynchronousCommand:(NSDictionary*)formData error:(NSError**)error;

@end

@interface NSObject (GalleryDelegates)

- (void)gallery:(Gallery*)gallery didRecieveCommandDictionary:(NSDictionary*)dictionary withTag:(long)tag;
- (void)gallery:(Gallery*)aGallery didUploadBytes:(long)count withTag:(long)tag;

@end
