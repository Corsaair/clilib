/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package cli.args
{
    /**
     * @private
     * 
     * Pads [source] to [length] by adding spaces at the end.
     * @playerversion AVM 0.4
     * @langversion 3.0
     */
    public function _padRight( source:String, length:int ):String
    {
        var str:String = "";
            str += source;
        
        while( str.length < length )
        {
            str += " ";
        }
        
        return str;
    }
}