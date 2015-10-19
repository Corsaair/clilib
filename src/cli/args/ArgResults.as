/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package cli.args
{
    import flash.utils.Proxy;
    import flash.utils.flash_proxy;

    /**
     * The results of parsing a series of command line arguments using
     * [ArgParser.parse()].
     * 
     * <p>
     * Includes the parsed options and any remaining unparsed command line
     * arguments.
     * </p>
     * 
     * @playerversion AVM 0.4
     * @langversion 3.0
     */
	public dynamic class ArgResults extends Proxy
	{
        
        // The [ArgParser] whose options were parsed for these results.
        private var _parser:ArgParser;
        
        // The option values that were parsed from arguments.
        private var _parsed:Object;
        
        //private var _results:Object = {};
        
        /**
         * If these are the results for parsing a command's options, this will
         * be the name of the command. For top-level results, this returns `null`.
         */
        public var name:String;
        
        /**
         * The command that was selected, or `null` if none was.
         * 
         * <p>
         * This will contain the options that were selected for that command.
         * </p>
         */
        public var command:ArgResults;
        
        /**
         * The remaining command-line arguments that were not parsed as options
         * or flags.
         * 
         * <p>
         * If `--` was used to separate the options from the remaining arguments,
         * it will not be included in this list unless parsing stopped before the
         * `--` was reached.
         * </p>
         */
        public var rest:Array      = [];
        
        /**
         * The original list of arguments that were parsed.
         */
        public var arguments:Array = [];
        
        /**
         * Creates a new [ArgResults].
         */
		public function ArgResults( parser:ArgParser, parsed:Object,
                                    name:String = "",
                                    command:ArgResults = null,
                                    rest:Array = null,
                                    arguments:Array = null )
		{
			super();
            
            _parser = parser;
            _parsed = parsed;
            
            //trace( "parsed = " + parsed );
            //trace( "parsed: " + JSON.stringify( parsed, null, "  " ) );
            
            //_applyToOptions( parsed );
            
            this.name = name;
            
            this.command = command;
            
            if( rest != null )
            {
                this.rest = this.rest.concat( rest );
            }
            
            if( arguments != null )
            {
                this.arguments = this.arguments.concat( arguments );
            }
		}
        
        /*
        private function _applyToOptions( parsed:Object ):void
        {
            var option:Option;
            for each( var p:* in parsed )
            {
                //results[ p ] = _parsed[ p ];
                option = _parser.getOptionByName( p );
                if( option )
                {
                    trace( p + " = " + parsed[p] );
                    option.defaultValue = parsed[ p ];
                }
            }
            
        }*/
        
        override flash_proxy function setProperty( name:*, value:* ):void
        {
            /*
            trace( "ArgResults set [" + name + "] = " + value );
            
            var option:Option = _parser.getOptionByName( name );
            if( option == null )
            {
                throw new ArgumentError( "Could not find an option named \"" + name + "\"." );
            }
            
            option.defaultValue = value; //???
            */
            
            //_results[ name ] = value;
            options[ name ] = value;
        }
        
        /**
         * Gets the parsed command-line option named [name].
         */
        override flash_proxy function getProperty( name:* ):*
        {
            /*
            var option:Option = _parser.getOptionByName( name );
            if( option == null )
            {
                throw new ArgumentError( "Could not find an option named \"" + name + "\"." );
            }
            
            return option.getOrDefault( _parsed[name] );
            */
            
            /*
            if( !_results.hasOwnProperty( name ) )
            {
                throw new ArgumentError( "Could not find an option named \"" + name + "\"." );
            }
            
            return _results[name];
            */
            
            if( !options.hasOwnProperty( name ) )
            {
                throw new ArgumentError( "Could not find an option named \"" + name + "\"." );
            }
            
            return options[name];
        }
        
        override flash_proxy function callProperty(methodName:*, ... args):*
        {
            trace( "methodName = " + String(methodName) );
        }
        
        override flash_proxy function hasProperty( name:* ):Boolean
        {
            /*
            var option:Option = _parser.getOptionByName( name );
            if( option == null )
            {
                return false;
            }
            
            return true;
            */
            
            //return _results.hasOwnProperty( name );
            return options.hasOwnProperty( name );
        }
        
        override flash_proxy function nextNameIndex( index:int ):int
        {
            /*
            if( index > (_parser.options.length - 1) )
            {
                return 0;
            }
            
            return index;
            */
            
            /*
            var items:Array = [];
            for( var m:String in _results )
            {
                items.push( m );
            }
            
            if( index > (items.length - 1) )
            {
                return 0;
            }
            
            return index;
            */
            
            var items:Array = [];
            for( var m:String in options )
            {
                items.push( m );
            }
            
            if( index > (items.length - 1) )
            {
                return 0;
            }
            
            return index;
        }
        
        override flash_proxy function nextName( index:int ):String
        {
            /*
            var option:Option = _parser.options[ index ];
            return option.name;
            */
            
            var items:Array = [];
            for( var m:String in options )
            {
                items.push( m );
            }
            
            return options[ items[index] ];
        }
        
        /**
         * Get the names of the available options as an [Iterable].
         * 
         * <p>
         * This includes the options whose values were parsed or that have defaults.
         * Options that weren't present and have no default will be omitted.
         * </p>
         */
        public function get options():Object
        {
            var results:Object = {};
            
            // Include the options that have defaults.
            _parser.options.forEach( function( item:Option, index:int, vector:Vector.<Option> ) {
                if( item.defaultValue != null )
                {
                    if( _parsed.hasOwnProperty( item.name ) )
                    {
                        results[ item.name ] = _parsed[ item.name ];
                    }
                    else
                    {
                        results[ item.name ] = item.getOrDefault();
                    }
                }
            } );
            
            return results;
        }
        
        /*public function listOptions():void
        {
            for each( var opt:Option in _parser.options )
            {
                trace( opt.name + " = " + opt.getOrDefault() );
            }
        }*/
        
        /**
         * Returns `true` if the option with [name] was parsed from an actual
         * argument.
         * 
         * <p>
         * Returns `false` if it wasn't provided and the default value or no default
         * value would be used instead.
         * </p>
         */
        public function wasParsed( name:String ):Boolean
        {
            var option:Option = _parser.getOptionByName( name );
            if( option == null )
            {
                throw new ArgumentError( "Could not find an option named \"" + name + "\"." );
            }
            
            //return _parsed.indexOf( name ) > -1;
            return _parsed.hasOwnProperty( name );
        }
        
        public function toString():String
        {
            return "[object ArgResults]";
        }
        
	}

}