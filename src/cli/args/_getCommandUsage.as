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
     * Returns a string representation of [commands] fit for use in a usage
     * string.
     * 
     * <p>
     * [isSubcommand] indicates whether the commands should be called "commands"
     * or "subcommands".
     * </p>
     * 
     * @playerversion AVM 0.4
     * @langversion 3.0
     */
    public function _getCommandUsage( commands:Vector.<Command>,
                                      isSubcommand:Boolean = false ):String
    {
        var str:String = "";
        var names:Array = [];
        var data:Object = {};
        
        commands.forEach( function( item:Command, index:int, vector:Vector.<Command> ):void {
            var name:String = item.name;
            // Don't include aliases.
            if( item.aliases && (item.aliases.indexOf( name ) == -1 ) )
            {
                // Filter out hidden ones, unless they are all hidden.
                if( !item.hidden )
                {
                    names.push( item.name );
                    data[ item.name ] = item;
                }
            }
            
        } );
        
        var length:int = 0;
        for each( var n:String in names )
        {
            length = Math.max( length, n.length );
        }
        
        // Show the commands alphabetically.
        names.sort( Array.CASEINSENSITIVE | Array.DESCENDING );
        
            str += "Available " + (isSubcommand ? "sub" : "") + "commands:";
        
        for each( var name:String in names )
        {
            str += "\n";
            str += "  ";
            str += _padRight( name, length );
            str += "   ";
            str += data[name].description.split("\n")[0];
            str += "";
            str += "";
        }
        
        return str;
    }
}