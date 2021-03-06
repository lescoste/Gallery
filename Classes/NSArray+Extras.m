/*
 NSArray+Extras.m
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

#import "NSArray+Extras.h"


@implementation NSArray (Extras)

- (NSArray*)arrayOfStringsStartingWithString:(NSString*)string
{
  NSMutableArray *array = [NSMutableArray array];
  for (id item in self)
  {
    if ([item isKindOfClass:[NSString class]])
    {
      if (([item length] >= [string length]) &&
          ([[item substringToIndex:[string length]] isEqual:string]))
      {
        [array addObject:item];
      }
    }
  }
  return [NSArray arrayWithArray:array];
}

@end
