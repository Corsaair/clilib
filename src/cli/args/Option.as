/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package cli.args
{
    
    /**
     * A command-line option. Includes both flags and options which take a value.
     * 
     * @playerversion AVM 0.4
     * @langversion 3.0
     */
    public class Option
    {
        private static var _invalidChars:RegExp = new RegExp( "[ \t\r\n\"\'\\\/]" );
        
        public var name:String;
        public var abbreviation:String;
        public var help:String;
        public var valueHelp:String;
        
        public var allowed:Array      = [];
        public var allowedHelp:Object = {};
        
        public var defaultValue:*;
        
        public var callback:Function;
        
        public var type:OptionType;
        
        public var negatable:Boolean;
        public var splitCommas:Boolean;
        public var hide:Boolean;
        
        public function Option( name:String,
                                abbreviation:String = "",
                                help:String = "",
                                valueHelp:String = "",
                                allowed:Array = null,
                                allowedHelp:Object = null,
                                defaultValue:* = null,
                                callback:Function = null,
                                type:OptionType = null,
                                negatable:Boolean = false,
                                splitCommas:Boolean = false,
                                hide:Boolean = false )
        {
            super();
            
            if( name == "" )
            {
                throw new ArgumentError( "Name cannot be empty." );
            }
            else if( name.charAt(0) == "-" )
            {
                throw new ArgumentError( "Name \"" + name + "\" cannot start with \"-\"." );
            }
            
            // Ensure name does not contain any invalid characters.
            if( name.search( _invalidChars ) > -1 )
            {
                throw new ArgumentError( "Name \"" + name + "\" contains invalid characters." );
            }
            
            if( abbreviation != "" )
            {
                if( abbreviation.length != 1 )
                {
                    throw new ArgumentError( "Abbreviation must be null or have length 1." );
                }
                else if( abbreviation == "-" )
                {
                    throw new ArgumentError( "Abbreviation cannot be \"-\"." );
                }
                
                if( abbreviation.search( _invalidChars ) > -1 )
                {
                    throw new ArgumentError( "Abbreviation is an invalid character." );
                }
            }
            
            // If the user doesn't specify [splitCommas], it defaults to true for
            // multiple options.
            if( splitCommas )
            {
                type = OptionType.MULTIPLE;
            }
            
            this.name = name;
            this.abbreviation = abbreviation;
            this.help = help;
            this.valueHelp = valueHelp;
            this.allowed = allowed;
            this.allowedHelp = allowedHelp;
            this.defaultValue = defaultValue;
            this.callback = callback;
            this.type = type;
            this.negatable = negatable;
            this.splitCommas = splitCommas;
            this.hide = hide;
            
        }
        
        /**
         * Whether the option is boolean-valued flag.
         */
        public function isFlag():Boolean { return type == OptionType.FLAG; }

        /**
         * Whether the option takes a single value.
         */
        public function isSingle():Boolean { return type == OptionType.SINGLE; }
        
        /**
         * Whether the option allows multiple values.
         */
        public function isMultiple():Boolean { return type == OptionType.MULTIPLE; }
        
        /**
         * Returns [value] if non-`null`, otherwise returns the default value
         * for this option.
         * 
         * <p>
         * For single-valued options, it will be [defaultValue] if set or `null`
         * otherwise. For multiple-valued options, it will be an empty list or a
         * list containing [defaultValue] if set.
         * </p>
         */
        public function getOrDefault( value:* = null ):*
        {
            if( value != null )
            {
                return value;
            }
            
            if( !isMultiple() )
            {
                return defaultValue;
            }
            
            if( defaultValue != null )
            {
                return [ defaultValue ];
            }
            
            return [];
        }
        
    }
}