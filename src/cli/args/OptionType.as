/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package cli.args
{

    /**
     * What kinds of values an <code>Option</code> accepts.
     * 
     * @playerversion AVM 0.4
     * @langversion 3.0
     */
    public class OptionType
    {
        
        /**
         * An option that can only be `true` or `false`.
         * 
         * <p>
         * The presence of the option name itself in the argument list means `true`.
         * </p>
         */
        public static const FLAG:OptionType     = new OptionType( 0, "FLAG" );

        /**
         * An option that takes a single value.
         * 
         * Examples:
         * <pre>
         *     --mode debug
         *     -mdebug
         *     --mode=debug
         * </pre>
         * 
         * <p>
         * If the option is passed more than once, the last one wins.
         * </p>
         */
        public static const SINGLE:OptionType   = new OptionType( 1, "SINGLE" );
        
        /**
         * An option that allows multiple values.
         * 
         * Example:
         * <pre>
         *     --output text --output xml
         * </pre>
         * 
         * <p>
         * In the parsed [ArgResults], a multiple-valued option will always
         * return a list, even if one or no values were passed.
         * </p>
         */
        public static const MULTIPLE:OptionType = new OptionType( 2, "MULTIPLE" );
        
    
        private var _value:int;
        private var _name:String;
        
        public function OptionType( value:int = 0 , name:String = "" )
        {
            super();
            
            _value = value;
            _name  = name;
        }
    }
}