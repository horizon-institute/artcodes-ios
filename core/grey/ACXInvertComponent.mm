/*
 * Aestheticodes recognises a different marker scheme that allows the
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
#import "ACXInvertComponent.h"

@implementation ACXInvertComponent

- (void) process:(ACXBufferManager*)bufferManager
{
	cv::Mat *buffer = [bufferManager mostRecentData];
	cv::bitwise_not(*buffer, *buffer);
}

- (bool) segmentSafe
{
	return true;
}

- (bool) segmentRecommended
{
	return false;
}

- (void) releaseResources
{
}

@end
