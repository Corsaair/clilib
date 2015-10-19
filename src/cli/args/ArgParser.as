/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package cli.args
{

	/**
	 * A class for taking a list of raw command line arguments and parsing out
	 * options and flags from them.
	 * 
     * @playerversion AVM 0.4
     * @langversion 3.0
     */
	public class ArgParser
	{

		private var _options:Vector.<Option>;
		private var _optionsMap:Object;
        
        private var _commands:Vector.<ArgParser>;
        private var _commandsMap:Object;

		/* A list of the [Option]s in [options] intermingled with
		   [String] separators.
		*/
		private var _optionsAndSeparators:Array = [];
        
        /**
         * Whether or not this parser parses options that appear after
         * non-option arguments.
         */
		public var allowTrailingOptions:Boolean;

		/**
		 * Creates a new ArgParser.
		 * 
		 * If [allowTrailingOptions] is set, the parser will continue parsing even
		 * after it finds an argument that is neither an option nor a command.
		 * This allows options to be specified after regular arguments.
		 * Defaults to `false`.
		 */
		public function ArgParser( options:Vector.<Option> = null, commands:Vector.<ArgParser> = null,
			                       allowTrailingOptions:Boolean = false )
		{
			super();
            
            if( options == null )
            {
                options = new Vector.<Option>();
                _optionsMap = {};
            }
            
            if( commands == null )
            {
                commands = new Vector.<ArgParser>();
                _commandsMap = {};
            }
            
			_options = options;
			_commands = commands;
			this.allowTrailingOptions = allowTrailingOptions;
		}
        
        private function _addOption( name:String,
                                     abbr:String = "",
                                     help:String = "",
                                     valueHelp:String = "",
                                     allowed:Array = null,
                                     allowedHelp:Object = null,
                                     defaultsTo:* = null,
                                     callback:Function = null,
                                     type:OptionType = null,
                                     negatable:Boolean = false,
                                     splitCommas:Boolean = true,
                                     hide:Boolean = false ):void
        {
            // Make sure the name isn't in use.
            if( _optionsMap.hasOwnProperty( name ) )
            {
                throw new ArgumentError( "Duplicate option \"" + name + "\"." );
            }
            
            // Make sure the abbreviation isn't too long or in use.
            if( abbr != "" )
            {
                var existing:Option = findByAbbreviation( abbr );
                if( existing != null )
                {
                    throw new ArgumentError( "Abbreviation \"" + abbr + "\" is already used by \"" + existing.name + "\"." );
                }
            }
            
            var option:Option = new Option( name, abbr, help, valueHelp,
                                            allowed, allowedHelp, defaultsTo,
                                            callback, type, negatable,
                                            splitCommas, hide );
            _options.push( option );
            //_optionsMap[ name ] = _options[ _options.length - 1 ];
            _optionsMap[ name ] = _options.length - 1;
            _optionsAndSeparators.push( option );
        }

        public function add( option:Option ):void
        {
            _addOption( option.name,
                        option.abbreviation,
                        option.help,
                        option.valueHelp,
                        option.allowed,
                        option.allowedHelp,
                        option.defaultValue,
                        option.callback,
                        option.type,
                        option.negatable,
                        option.splitCommas,
                        option.hide );
        }

		/**
         * The options that have been defined for this parser.
         */
		public function get options():Vector.<Option> { return _options; }

		/**
         * The commands that have been defined for this parser.
         */
		public function get commands():Vector.<ArgParser> { return _commands; }
        
        /**
         * Generates a string displaying usage information for the defined
         * options.
         * 
         * <p>
         * This is basically the help text shown on the command line.
         * </p>
         */
        public function get usage():String
        {
            var tmp:Usage = new Usage( _optionsAndSeparators );
            return tmp.generate();
        }
        
		/**
		 * Defines a command.
		 * 
		 * A command is a named argument which may in turn define its own options and
		 * subcommands using the given parser. If [parser] is omitted, implicitly
		 * creates a new one. Returns the parser for the command.
		 */
		public function addCommand( name:String, parser:ArgParser = null ):ArgParser
		{
			// Make sure the name isn't in use.
			if( _commandsMap.hasOwnProperty( name ) )
			{
				throw new ArgumentError('Duplicate command "' + name + '".' );
			}

			if( parser == null )
			{
				parser = new ArgParser();
			}

            _commands.push( parser );
            _commandsMap[ name ] = _commands.length - 1;
			return parser;
		}
        
        /**
         * Defines a flag.
         * 
         * <p>
         * Throws an [ArgumentError] if:
         * </p>
         * <ul>
         *   <li>There is already an option named [name].</li>
         *   <li>There is already an option using abbreviation [abbr].</li>
         * </ul>
         */
        public function addFlag( name:String,
                                 abbr:String = "",
                                 help:String = "",
                                 defaultsTo:Boolean = false,
                                 negatable:Boolean = true,
                                 callback:Function = null,
                                 hide:Boolean = false ):void
        {
            _addOption( name, abbr, help, "", null, null, defaultsTo, callback,
                        OptionType.FLAG, negatable, false, hide );
        }
        
        /**
         * Defines a value-taking option.
         * 
         * <p>
         * Throws an [ArgumentError] if:
         * </p>
         * <ul>
         *   <li>There is already an option with name [name].</li>
         *   <li>There is already an option using abbreviation [abbr].</li>
         *   <li>[splitCommas] is passed but [allowMultiple] is `false`.</li>
         * </ul>
         */
        public function addOption( name:String,
                                   abbr:String = "",
                                   help:String = "",
                                   valueHelp:String = "",
                                   allowed:Array = null,
                                   allowedHelp:Object = null,
                                   defaultsTo:String = "",
                                   callback:Function = null,
                                   allowMultiple:Boolean = false,
                                   splitCommas:Boolean = false,
                                   hide:Boolean = false ):void
        {
            if( !allowMultiple && splitCommas )
            {
                throw new ArgumentError( "splitCommas may not be set if allowMultiple is false." );
            }
            
            var type:OptionType = ( allowMultiple ? OptionType.MULTIPLE: OptionType.SINGLE );
            _addOption( name, abbr, help, valueHelp, allowed, allowedHelp,
                        defaultsTo, callback, type, false, splitCommas, hide );
        }

        /**
         * Adds a separator line to the usage.
         * 
         * <p>
         * In the usage text for the parser, this will appear between any
         * options added before this call and ones added after it.
         * </p>
         */
        public function addSeparator( text:String ):void
        {
            _optionsAndSeparators.push( text );
        }
        
        /**
         * Parses [args], a list of command-line arguments, matches them against
         * the flags and options defined by this parser, and returns the result.
         */
        public function parse( args:Array ):ArgResults
        {
            var p:Parser = new Parser( "", this, args, null, null );
            return p.parse();
        }
        
        /**
         * Get the default value for an option.
         * 
         * <p>
         * Useful after parsing to test if the user specified something other
         * than the default.
         * </p>
         */
        public function getDefault( option:String ):*
        {
            if( !_optionsMap.hasOwnProperty( option ) )
            {
                throw new ArgumentError( "No option named " + option );
            }
            
            return _options[ _optionsMap[option] ].defaultValue;
        }
        
        public function getOptionByName( name:String ):Option
        {
            if( !_optionsMap.hasOwnProperty( name ) )
            {
                return null;
            }
            
            return _options[ _optionsMap[name] ];
        }
        
        public function getCommandByName( name:String ):ArgParser
        {
            if( !_commandsMap.hasOwnProperty( name ) )
            {
                return null;
            }
            
            return _commands[ _commandsMap[name] ];
        }
        
        /**
         * Finds the option whose abbreviation is [abbr], or `null` if no option
         * has that abbreviation.
         */
        public function findByAbbreviation( abbr:String ):Option
        {
            var option:Option;
            for each( option in _options )
            {
                if( option.abbreviation == abbr )
                {
                    return option;
                }
            }
            
            return null;
        }
        
	}

}