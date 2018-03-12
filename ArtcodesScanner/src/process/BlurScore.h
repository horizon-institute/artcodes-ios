/*
 * Artcodes recognises a different marker scheme that allows the
 * creation of aesthetically pleasing, even beautiful, codes.
 * Copyright (C) 2013-2015  The University of Nottingham
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU Affero General Public License as published
 *     by the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU Affero General Public License for more details.
 *
 *     You should have received a copy of the GNU Affero General Public License
 *     along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#import <UIKit/UIKit.h>
#import "ImageProcessor.h"

@protocol FocusCallback;

/*
 Based on Pech-Pacheco et al. “Diatom autofocusing in brightfield
 microscopy: a comparative study” (https://doi.org/10.1109/ICPR.2000.903548)
 and blog post
 https://www.pyimagesearch.com/2015/09/07/blur-detection-with-opencv/,
 it evaluates how blurry the image is and then re-focuses the camera if
 required.
 */
@interface BlurScore : NSObject<ImageProcessor>

-(id)initWithFocusClosure:(id<FocusCallback>)focusClosure;
-(void) process:(ImageBuffers*) buffers;

@end
