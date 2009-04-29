//
//  iGalleryPhotoController.h
//  iGallery
//
//  Created by Matt Wright on 04/10/2008.
//  Copyright 2008 Matt Wright Consulting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Gallery.h"

@interface iGalleryPhotoController : UIViewController <UITextFieldDelegate> {
  Gallery *gallery;
  
  UIImage *image;
  UIToolbar *toolbar;
  
  // toolbar views
  UITextField *imageNameTextField;
  
  NSArray *normalToolbarArray;
  NSArray *editToolbarArray;
  NSArray *uploadToolbarArray;
  
  NSString *imageName;
  
  int uploadedBytes;
  int totalBytes;
  
  bool keyboardShown;
}

@property (nonatomic, retain) Gallery *gallery;

@property (nonatomic, retain) UIImage *image;
@property (nonatomic, retain) UIToolbar *toolbar;

@property (nonatomic, retain) NSString *imageName;

#pragma mark Toolbar Generation

- (NSArray*)normalToolbarArray;
- (NSArray*)editToolbarArray;
- (NSArray*)uploadToolbarArray;

@end
