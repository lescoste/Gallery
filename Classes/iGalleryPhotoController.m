/*
 iGalleryPhotoController.m
 Copyright (c) 2009 Matt Wright.
 
 Gallery is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 as published by the Free Software Foundation; either version 2
 of the License, or (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

#import "iGalleryPhotoController.h"
#import "iGallerySettingsController.h"
#import "ProgressTextBarView.h"
#import "UIImage+Extras.h"

#define PROGRESS_STEPS (1.0 / 4.0)

enum
{
  GalleryProgressLogin,
  GalleryProgressRotate,
  GalleryProgressStartUpload,
  GalleryProgressUpload,
  GalleryProgressFinishing,
};

@interface iGalleryPhotoController (Private)

- (NSArray*)normalToolbarArray;
- (NSArray*)uploadToolbarArray;

- (void)showUploadButton;
- (void)showProgressIndicator;

- (void)updateUploadProgress;

- (ProgressTextBarView*)toolbarProgressView;

@end

@implementation iGalleryPhotoController

@synthesize gallery;
@synthesize image;
@synthesize toolbar;
@synthesize imageName;

// Override initWithNibName:bundle: to load the view using a nib file then perform additional customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil 
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) 
    {
      // Custom initialization
    }
    return self;
}

// Implement loadView to create a view hierarchy programmatically.
- (void)loadView {
  [super loadView];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didShowKeyboard:) name:@"UIKeyboardDidShowNotification" object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willHideKeyboard:) name:@"UIKeyboardWillHideNotification" object:nil];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gallerySettingsDidChange:) name:IGSettingsDidChangeNotification object:nil];
  
  self.title = @"Gallery";
  [self showUploadButton];
  
  // Init the gallery object
  self.gallery = [[Gallery alloc] initWithGalleryURL:[[NSUserDefaults standardUserDefaults] valueForKey:@"gallery_url"] delegate:self];

  toolbar = [[UIToolbar alloc] init];

  // Generate an image name based on the current date
  NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
  [dateFormatter setDateFormat:@"ddMMyy-HHmm"];
  self.imageName = [NSString stringWithFormat:@"iPhone-%@.jpg", [[dateFormatter stringFromDate:[NSDate date]] stringByReplacingOccurrencesOfString:@" " withString:@""]];
  
  // Lets get the size of the toolbar as default.
  [toolbar sizeToFit];
  CGFloat toolbarHeight = toolbar.frame.size.height;
  CGRect viewBounds = self.view.bounds;
  
  toolbar.autoresizingMask = (UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth);
  toolbar.barStyle = UIBarStyleBlackTranslucent;
  [toolbar setFrame:CGRectMake(CGRectGetMinX(viewBounds), CGRectGetMinY(viewBounds) + CGRectGetHeight(viewBounds) - toolbarHeight, CGRectGetWidth(viewBounds), toolbarHeight)];  
  [self.view addSubview:toolbar];
  
  [toolbar setItems:[self normalToolbarArray] animated:YES];
  
  normalToolbarArray = [[self normalToolbarArray] retain];
  editToolbarArray = [[self editToolbarArray] retain];
  uploadToolbarArray = [[self uploadToolbarArray] retain];
}

#pragma mark Show/Hide Toolbars

- (void)showToolbars
{
  // Get rid of our toolbar now
  [UIView beginAnimations:@"ToolbarShow" context:(void*)toolbar];
  [UIView setAnimationDuration:0.25];
  toolbar.alpha = 1.0;
  [UIView commitAnimations];
}

- (void)hideToolbars
{
  // Get rid of our toolbar now
  [UIView beginAnimations:@"ToolbarHide" context:(void*)toolbar];
  [UIView setAnimationDuration:0.25];
  toolbar.alpha = 0.0;
  [UIView commitAnimations];  
}

#pragma mark Toolbar Generation

- (NSArray*)normalToolbarArray
{
  UILabel *topTextView = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 18)] autorelease];
  topTextView.backgroundColor = [UIColor clearColor];
  topTextView.text = self.imageName;
  topTextView.textAlignment = UITextAlignmentCenter;
  topTextView.font = [UIFont boldSystemFontOfSize:[UIFont smallSystemFontSize]];
  topTextView.textColor = [UIColor whiteColor];
  
  // Yeah hacky, i know
  imageNameTextField = [topTextView retain];
  
  UILabel *bottomTextView = [[[UILabel alloc] initWithFrame:CGRectMake(0, 18, 200, 18)] autorelease];
  bottomTextView.backgroundColor = [UIColor clearColor];
  bottomTextView.text = [NSString stringWithFormat:@"%1.fx%1.f", image.size.width, image.size.height];
  bottomTextView.textAlignment = UITextAlignmentCenter;
  bottomTextView.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
  bottomTextView.textColor = [UIColor whiteColor];
  
  UIView *textViews = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 36)] autorelease];
  [textViews addSubview:topTextView];
  [textViews addSubview:bottomTextView];
  
  // Meh, can't set the width of a space in one line.
  UIBarButtonItem *space = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil] autorelease];
  space.width = 20;
  
  return [NSArray arrayWithObjects:
          [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(action:)] autorelease],
          [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease],
          [[[UIBarButtonItem alloc] initWithCustomView:textViews] autorelease],
          [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease],
          [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(edit:)] autorelease],
          nil];
}

- (NSArray*)editToolbarArray
{
  UITextField *textField = [[[UITextField alloc] initWithFrame:CGRectMake(0, 0, toolbar.bounds.size.width * 0.8, 27)] autorelease];

  textField.delegate = self;
  textField.backgroundColor = [UIColor clearColor];
  textField.borderStyle = UITextBorderStyleRoundedRect;
  textField.textColor = [UIColor blackColor];
  textField.text = self.imageName;
  
  textField.autocorrectionType = UITextAutocorrectionTypeDefault;	// no auto correction support
  textField.keyboardType = UIKeyboardTypeDefault;
  textField.returnKeyType = UIReturnKeyDone;
  textField.clearButtonMode = UITextFieldViewModeWhileEditing;  // has a clear 'x' button to the right
  
  return [NSArray arrayWithObjects:
          [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease],
          [[[UIBarButtonItem alloc] initWithCustomView:textField] autorelease],
          [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease],
          nil];
}


- (NSArray*)uploadToolbarArray
{
  ProgressTextBarView *progressTextView = [[[ProgressTextBarView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(toolbar.bounds) * 0.6, CGRectGetHeight(toolbar.bounds) * 0.8)] autorelease];
  progressTextView.textField.text = @"Initialising...";
  progressTextView.progressView.progress = 0.0;
  
  return [NSArray arrayWithObjects:
          [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease],
          [[[UIBarButtonItem alloc] initWithCustomView:progressTextView] autorelease],
          [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease],
          nil];
}

- (void)didShowKeyboard:(NSNotification*)notification
{
  if (keyboardShown)
  {
    return;
  }
  
  NSValue *boundsValue = [[notification userInfo] objectForKey:UIKeyboardBoundsUserInfoKey];
  CGRect keyboardBounds = [boundsValue CGRectValue];
  CGRect toolbarFrame = toolbar.frame;
  toolbarFrame.origin.y -= keyboardBounds.size.height;
  toolbar.frame = toolbarFrame;
  
  keyboardShown = YES;
}

- (void)willHideKeyboard:(NSNotification*)notification
{
  NSValue *boundsValue = [[notification userInfo] objectForKey:UIKeyboardBoundsUserInfoKey];
  CGRect keyboardBounds = [boundsValue CGRectValue];
  CGRect toolbarFrame = toolbar.frame;
  toolbarFrame.origin.y += keyboardBounds.size.height;
  toolbar.frame = toolbarFrame;
  
  keyboardShown = NO;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
  self.imageName = textField.text;
  if ([self.imageName isEqual:@""])
  {
    // Generate an image name based on the current date
    NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
    [dateFormatter setDateFormat:@"ddMMyy-HHmm"];
    self.imageName = [NSString stringWithFormat:@"iPhone-%@.jpg", [[dateFormatter stringFromDate:[NSDate date]] stringByReplacingOccurrencesOfString:@" " withString:@""]];
  }
  if (![[self.imageName substringWithRange:NSMakeRange([self.imageName length] - 4, 4)] isEqualToString:@".jpg"])
  {
    self.imageName = [self.imageName stringByAppendingString:@".jpg"];
  }
  imageNameTextField.text = self.imageName;

  [textField resignFirstResponder];
  [toolbar setItems:normalToolbarArray animated:YES];
  return NO;
}

- (ProgressTextBarView*)toolbarProgressView
{
  id view = [[[toolbar items] objectAtIndex:1] customView];
  if ([view isKindOfClass:[ProgressTextBarView class]])
  {
    return view;
  }
  return nil;
}

- (void)showUploadButton
{
  [self.navigationItem setRightBarButtonItem:[[[UIBarButtonItem alloc] initWithTitle:@"Upload" style:UIBarButtonItemStyleDone target:self action:@selector(upload:)] autorelease] animated:YES];
}

- (void)showProgressIndicator
{ 
  // Just clear the button now, instead of showing an indicator. We've already got a progress bar and the network indicator to go off.
  [self.navigationItem setRightBarButtonItem:nil animated:YES];
}

- (IBAction)upload:(id)sender
{
  [toolbar setItems:uploadToolbarArray animated:YES];
  [self showProgressIndicator];
  
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSString *galleryUsername = [defaults valueForKey:@"username"];
  NSString *galleryPassword = [defaults valueForKey:@"password"];
  
  if ((!galleryUsername || !galleryPassword) || ([galleryUsername isEqual:@""] || [galleryPassword isEqual:@""]))
  {
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Credentials Error" message:@"You have not setup your gallery details." delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:@"Settings", nil] autorelease];
    [alert show];
    
    [self showUploadButton];
    [toolbar setItems:normalToolbarArray animated:YES];
    
    return;
  }
  
  [gallery setUsername:galleryUsername];
  [gallery setPassword:galleryPassword];
  
  [self toolbarProgressView].textField.text = @"Logging in...";
  [self toolbarProgressView].progressView.progress += PROGRESS_STEPS;

  NSURLRequest *request = [self.gallery requestForCommandDictionary:[NSDictionary dictionaryWithObjectsAndKeys:galleryPassword, @"password", galleryUsername, @"uname", @"login", @"cmd", nil]];
  [gallery beginAsyncRequest:request withTag:GalleryProgressLogin];
}

- (IBAction)edit:(id)sender
{
  [toolbar setItems:editToolbarArray animated:YES];
  UIView *view = [[[toolbar items] objectAtIndex:1] customView];
  [view becomeFirstResponder];
}

- (void)queueTagEvent:(NSNumber*)tag
{
  [self gallery:nil didRecieveCommandDictionary:nil withTag:[tag intValue]];
}

- (void)gallerySettingsDidChange:(NSNotification*)notification
{
  [self.gallery setGalleryURL:[[NSUserDefaults standardUserDefaults] valueForKey:@"gallery_url"]];
}

- (void)gallery:(Gallery*)aGallery didRecieveCommandDictionary:(NSDictionary*)dictionary withTag:(long)tag
{
  switch (tag)
  {
    case GalleryProgressLogin:
    {
      if (dictionary == nil)
      {
        // We got an error, don't continue
        return;
      }
            
      if ([[dictionary valueForKey:@"status"] intValue] != 0)
      {
        UIAlertView *alert;
        switch ([[dictionary valueForKey:@"status"] intValue])
        {
          case 201:
            alert = [[[UIAlertView alloc] initWithTitle:@"Gallery Error" message:[dictionary valueForKey:@"status_text"] delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:@"Settings", nil] autorelease];
            break;
          default:
            alert = [[[UIAlertView alloc] initWithTitle:@"Gallery Error" message:[dictionary valueForKey:@"status_text"] delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] autorelease];
            break;
        }
        [alert show];
        
        [self showUploadButton];
        [toolbar setItems:normalToolbarArray animated:YES];
        return;
      }
      
      [self toolbarProgressView].textField.text = @"Rotating...";
      [self toolbarProgressView].progressView.progress += PROGRESS_STEPS;
      [self performSelector:@selector(queueTagEvent:) withObject:[NSNumber numberWithInt:GalleryProgressRotate] afterDelay:0.0];
      break;
    }
    case GalleryProgressRotate:
    {
      self.image = [image rotateImage];
      [self toolbarProgressView].textField.text = [NSString stringWithFormat:@"Uploading..."];
      [self performSelector:@selector(queueTagEvent:) withObject:[NSNumber numberWithInt:GalleryProgressStartUpload] afterDelay:0.0];
      break;
    }
    case GalleryProgressStartUpload:
    {
      NSString *galleryID = [[NSUserDefaults standardUserDefaults] valueForKey:@"albumID"];
      NSURLRequest *uploadRequest = [gallery requestForCommandDictionary:[NSDictionary dictionaryWithObjectsAndKeys:self.image, @"g2_userfile", galleryID, @"set_albumName", @"add-item", @"cmd", nil] imageName:self.imageName];
      
      uploadedBytes = 0;      
      [gallery beginAsyncRequest:uploadRequest withTag:GalleryProgressUpload];
      break;
    }
    case GalleryProgressUpload:
    {
      NSString *itemID = [dictionary objectForKey:@"item_name"];
      NSURLRequest *request = [gallery requestForCommandDictionary:[NSDictionary dictionaryWithObjectsAndKeys:itemID, @"id", @"image-properties", @"cmd", nil]];
      [gallery beginAsyncRequest:request withTag:GalleryProgressFinishing];
      break;
    }
    case GalleryProgressFinishing:
    {        
      NSLog(@"%@", dictionary);
      [self showUploadButton];
      [toolbar setItems:normalToolbarArray animated:YES];
      break;
    }
    default:
      NSLog(@"Unknown tag, received dictionary: %@", dictionary);
      break;
  }
}

- (void)gallery:(Gallery*)aGallery didError:(NSError*)error
{
  [self showUploadButton];
  [toolbar setItems:normalToolbarArray animated:YES];
  
  if ([[error domain] isEqual:@"GalleryDomain"])
  {
    switch ([error code])
    {
      case 1001:
      case 1002:
        [[[[UIAlertView alloc] initWithTitle:@"Error" message:[error localizedDescription] delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:@"Settings", nil] autorelease] show];
        return;
        break;
    }
  }
  [[[[UIAlertView alloc] initWithTitle:@"Error" message:[error localizedDescription] delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] autorelease] show]; 
}

- (void)gallery:(Gallery*)gallery didUploadBytes:(long)count bytesRemaining:(long)remaining withTag:(long)tag
{
  if (tag == GalleryProgressUpload)
  {
    uploadedBytes += count;
    totalBytes = uploadedBytes + remaining;
    [self performSelector:@selector(updateUploadProgress) withObject:nil afterDelay:0.0];
  }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
  if (buttonIndex == 1)
  {
    UINavigationController *nav = [self navigationController];
    [nav pushViewController:[[[iGallerySettingsController alloc] init] autorelease] animated:YES];
  }
}

- (void)updateUploadProgress
{
  if (uploadedBytes == totalBytes)
  {
    [self toolbarProgressView].textField.text = [NSString stringWithFormat:@"Finishing..."];
  }
  else
  {
    [self toolbarProgressView].textField.text = [NSString stringWithFormat:@"Uploading... (%dk/%dk)", uploadedBytes / 1024, totalBytes / 1024];
  }
  [self toolbarProgressView].progressView.progress = (PROGRESS_STEPS * 2.0) + ((2.0 * PROGRESS_STEPS) * ((float)uploadedBytes / (float)totalBytes));
}

// Implement viewDidLoad to do additional setup after loading the view.
- (void)viewDidLoad {
  [super viewDidLoad];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
  return ((interfaceOrientation == UIInterfaceOrientationPortrait) || (interfaceOrientation == UIInterfaceOrientationLandscapeRight) || (interfaceOrientation == UIInterfaceOrientationLandscapeLeft));
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}


- (void)dealloc 
{
  [imageNameTextField release];
  [uploadToolbarArray release];
  [normalToolbarArray release];
  [editToolbarArray release];
  
  [image release];
  [super dealloc];
}


@end
