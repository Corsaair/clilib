/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package cli.args
{
    
    /**
     * 
     * @playerversion AVM 0.4
     * @langversion 3.0
     */
    public dynamic class UsageError extends Error
    {
        prototype.name = "UsageError";
        
        private var _usage:String;
        
        public function UsageError( message:String = "",
                                    usage:String = "" )
        {
            super( message );
            
            this.name  = prototype.name;
            _usage = usage;
        }
        
        public function get usage():String { return _usage; }
        
        public function toString():String
        {
            var str:String = "";
                str += message;
                str += "\n\n";
                str += usage;
            
            return str;
            
            /*
            var len:uint = this.name.length;
            var pad:String = "";
            while( pad.length < len )
            {
                pad += " ";
            }
            
            var str:String = "";
                str += this.name + ": ";
                str += this.message;
                str += "\n";
            var padding:String = pad + "  ";
            var lines:Array;
            
            if( this.usage.indexOf( "\n" ) > -1 )
            {
                lines = this.usage.split( "\n" );
            }
            else
            {
                lines = [ this.usage ];
            }
            
            var i:uint;
            var l:uint = lines.length;
            for( i = 0; i < l; i++ )
            {
                str += padding + lines[i] + "\n";
            }
            
            return str;
            */
        }
    }
}