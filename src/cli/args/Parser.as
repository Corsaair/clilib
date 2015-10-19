/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package cli.args
{
    import shell.Diagnostics;
    
    /**
     * The actual argument parsing class.
     * 
     * <p>
     * Unlike [ArgParser] which is really more an "arg grammar", this is the
     * class that does the parsing and holds the mutable state required during
     * a parse.
     * </p>
     * 
     * @playerversion AVM 0.4
     * @langversion 3.0
     */
    public class Parser
    {
        private static const _SOLO_OPT:RegExp = new RegExp( '^-([a-zA-Z0-9])$' );
        private static const _ABBR_OPT:RegExp = new RegExp( '^-([a-zA-Z0-9]+)(.*)$' );
        private static const _LONG_OPT:RegExp = new RegExp( '^--([a-zA-Z\-_0-9]+)(=(.*))?$' );
        
        /**
         * If parser is parsing a command's options, this will be the name of
         * the command. For top-level results, this returns `null`.
         */
        public var commandName:String;

        /**
         * The parser for the supercommand of this command parser, or `null` if
         * this is the top-level parser.
         */        
        public var parent:Parser;
        
        /**
         * The grammar being parsed.
         */
        public var grammar:ArgParser;
        
        /**
         * The arguments being parsed.
         */
        public var args:Array = [];
        
        /**
         * The remaining non-option, non-command arguments.
         */
        public var rest:Array = [];
        
        /**
         * The accumulated parsed options.
         */
        public var results:Object = {};
        
        /**
         * 
         */
        public function Parser( commandName:String,
                                grammar:ArgParser = null,
                                args:Array = null,
                                parent:Parser = null,
                                rest = null )
        {
            super();
            
            this.commandName = commandName;
            this.grammar     = grammar;
            
            if( args != null )
            {
                this.args = this.args.concat( args );
            }
            
            this.parent      = parent;
            
            if( rest != null )
            {
                this.rest = this.rest.concat( rest );
            }
        }
        
        /**
         * The current argument being parsed.
         */
        public function get current():String { return args[0]; }

        /**
         * Validates that [value] is allowed as a value of [option].
         */
        private function _validateAllowed( option:Option, value:String ):void
        {
            if( option.allowed == null ) { return; }
            
            validate( option.allowed.indexOf( value ) > -1, "\"" + value + "\" is not an allowed value for option \"" + option.name + "\"." );
        }
        
        private function _invokeCallback( item:Option, index:int, vector:Vector.<Option> ):void
        {
            //trace( "_invokeCallback() = " + item.name );
            if( item.callback == null )
            {
                //trace( "no callback" );
                return;
            }
            
            //trace( "have callback" );
            item.callback( item.getOrDefault( results[ item.name ] ) );
        }
        
        /**
         * Parses the arguments. This can only be called once.
         */
        public function parse():ArgResults
        {
            //trace( "Parser.parse()" );
            var arguments:Array = args.concat();
            //trace( "arguments = [" + arguments + "]" );
            var commandResults:ArgResults = null;
            var commandName:String = "";
            
            // Parse the args.
            while( args.length > 0 )
            {
                if( current == "--" )
                {
                    // Reached the argument terminator, so stop here.
                    args.shift();
                    break;
                }
                
                // Try to parse the current argument as a command. This happens
                // before options so that commands can have option-like names.
                var command:ArgParser = grammar.getCommandByName( current );
                //trace( "command = " + command );
                if( command != null )
                {
                    validate( rest.length == 0, "Cannot specify arguments before a command." );
                    commandName = args.shift();
                    //trace( "commandName = " + commandName );
                    var commandParser:Parser = new Parser( commandName, command, args, this, rest );
                    commandResults = commandParser.parse();
                    
                    // All remaining arguments were passed to command so clear them here.
                    rest.length = 0;
                    rest = [];
                    break;
                }
                
                // Try to parse the current argument as an option. Note that the
                // order here matters.
                if( parseSoloOption() ) { continue; }
                if( parseAbbreviation( this ) ) { continue; }
                if( parseLongOption() ) { continue; }
                
                // This argument is neither option nor command, so stop parsing
                // unless the [allowTrailingOptions] option is set.
                if( !grammar.allowTrailingOptions )
                {
                    break;
                }
                
                rest.push( args.shift() );
            }
            
            // Invoke the callbacks.
            grammar.options.forEach( _invokeCallback );
            
            // Add in the leftover arguments we didn't parse to the innermost command.
            rest = rest.concat( args );
            args.length = 0;
            args = [];
            
            return new ArgResults( grammar, results, commandName, commandResults, rest, arguments );
        }
        
        /**
         * Pulls the value for [option] from the second argument in [args].
         * 
         * <p>
         * Validates that there is a valid value there.
         * </p>
         */
        public function readNextArgAsValue( option:Option ):void
        {
            // Take the option argument from the next command line arg.
            validate( args.length > 0  , "Missing argument for \"" + option.name + "\"." );
            
            //trace( "readNextArgAsValue:" );
            //trace( "-results: " + JSON.stringify( results ) );
            //trace( "-option: " + JSON.stringify( option ) );
            //trace( "-current: " + current );
            
            setOption( results, option, current );
            args.shift();
        }
        
        /**
         * Tries to parse the current argument as a "solo" option, which is a
         * single hyphen followed by a single letter.
         * 
         * <p>
         * We treat this differently than collapsed abbreviations (like "-abc")
         * to handle the possible value that may follow it.
         * </p>
         */
        public function parseSoloOption():Boolean
        {
            var soloOpt:Array = current.match( _SOLO_OPT );
            if( (soloOpt == null) ||
                (soloOpt && (soloOpt.length == 0)) )
            {
                return false;
            }
            
            //trace( "soloOpt = " + soloOpt );
            
            var option:Option = grammar.findByAbbreviation( soloOpt[1] );
            if( option == null )
            {
                // Walk up to the parent command if possible.
                validate( parent != null, "Could not find an option or flag \"-" + soloOpt[1] + "\"." );
                return parent.parseSoloOption();
            }
            
            args.shift();
            
            if( option.isFlag() )
            {
                setFlag( results, option, true );
            }
            else
            {
                readNextArgAsValue( option );
            }
            
            return true;
        }
        
        /**
         * Tries to parse the current argument as a series of collapsed
         * abbreviations (like "-abc") or a single abbreviation with the value
         * directly attached to it (like "-mrelease").
         */
        public function parseAbbreviation( innermostCommand:Parser ):Boolean
        {
            var abbrOpt:Array = current.match( _ABBR_OPT );
            if( (abbrOpt == null) ||
                (abbrOpt && (abbrOpt.length == 0)) )
            {
                return false;
            }
            
            //trace( "abbrOpt = " + abbrOpt );
            
            // If the first character is the abbreviation for a non-flag option,
            // then the rest is the value.
            var c:String = String(abbrOpt[1]).substring( 0, 1 );
            var first:Option = grammar.findByAbbreviation( c );
            if( first == null )
            {
                // Walk up to the parent command if possible.
                validate( parent != null, "Could not find an option with short name \"-" + c + "\"." );
                return parent.parseAbbreviation( innermostCommand );
            }
            else if( !first.isFlag() )
            {
                // The first character is a non-flag option, so the rest must be
                // the value.
                var value:String =  String(abbrOpt[1]).substring(1) + String(abbrOpt[2]);
                setOption( results, first, value );
            }
            else
            {
                // If we got some non-flag characters, then it must be a value,
                // but if we got here, it's a flag, which is wrong.
                validate( abbrOpt[2] == "", "Option \"-" + c + "\" is a flag and cannot handle value \"" + String(abbrOpt[1]).substring(1) + String(abbrOpt[2]) + "\"." );
                
                // Not an option, so all characters should be flags.
                // We use "innermostCommand" here so that if a parent command
                // parses the *first* letter, subcommands can still be found to
                // parse the other letters.
                for( var i:uint = 0; i < String(abbrOpt[1]).length; i++ )
                {
                    var s:String = String(abbrOpt[1]).substring(i, i + 1);
                    innermostCommand.parseShortFlag( s );
                }
            }
            
            args.shift();
            return true;
        }
        
        /**
         * 
         */
        public function parseShortFlag( c:String ):void
        {
            var option:Option = grammar.findByAbbreviation( c );
            if( option == null )
            {
                // Walk up to the parent command if possible.
                validate( parent != null, "Could not find an option with short name \"-" + c + "\"." );
                parent.parseShortFlag( c );
                return ;
            }
            
            // In a list of short options, only the first can be a non-flag. If
            // we get here we've checked that already.
            validate( option.isFlag(), "Option \"-" + c + "\" must be a flag to be in a collapsed \"-\"." );
            setFlag( results, option, true );
        }
        
        /**
         * Tries to parse the current argument as a long-form named option,
         * which may include a value like "--mode=release" or "--mode release".
         */
        public function parseLongOption():Boolean
        {
            //var longOpt:Array = current.match( _LONG_OPT );
            var longOpt:Array = _LONG_OPT.exec( current );
            if( (longOpt == null) ||
                (longOpt && (longOpt.length == 0)) )
            {
                return false;
            }
            
            //trace( "longOpt = " + longOpt );
            
            var name:String = longOpt[1];
            var option:Option = grammar.getOptionByName( name );
            
            //trace( "name = " + name );
            
            if( option != null )
            {
                args.shift();
                if( option.isFlag() )
                {
                    validate( longOpt[3] == null, "Flag option \"" + name + "\" should not be given a value." );
                    setFlag( results, option, true );
                }
                else if( longOpt[3] != null )
                {
                    // We have a value like --foo=bar.
                    setOption( results, option, longOpt[3] );
                }
                else
                {
                    // Option like --foo, so look for the value as the next arg.
                    readNextArgAsValue( option );
                }
                
            }
            else if( name.substring( 0, 3 ) == "no-" )
            {
                // See if it's a negated flag.
                name = name.substring( "no-".length );
                //trace( "(no-)name = " + name );
                option = grammar.getOptionByName( name );
                //trace( "option = " + option );
                if( option == null )
                {
                    // Walk up to the parent command if possible.
                    validate( parent != null, "Could not find an option named \"" + name + "\"." );
                    return parent.parseLongOption();
                }
                
                args.shift();
                validate( option.isFlag(), "Cannot negate non-flag option \"" + name + "\"." );
                validate( option.negatable, "Cannot negate option \"" + name + "\"." );
                
                setFlag( results, option, false );
            }
            else
            {
                // Walk up to the parent command if possible.
                validate( parent != null, "Could not find an option named \"" + name + "\"." );
                return parent.parseLongOption();
            }
            
            return true;
        }
        
        /**
         * Called during parsing to validate the arguments.
         * 
         * <p>
         * Throws a [FormatException] if [condition] is `false`.
         * </p>
         */
        public function validate( condition:Boolean, message:String ):void
        {
            if( !condition )
            {
                throw new SyntaxError( message );
            }
        }
        
        private function _assert( condition:Boolean ):void
        {
            if( Diagnostics.isDebugger() && !condition )
            {
                throw new Error( "assertion" );
            }
        }
        
        /**
         * Validates and stores [value] as the value for [option], which must
         * not be a flag.
         */
        public function setOption( results:Object, option:Option, value:String ):void
        {
            _assert( !option.isFlag() );
            
            if( !option.isMultiple() )
            {
                _validateAllowed( option, value );
                results[ option.name ] = value;
                return;
            }
            
            var list:Array;
            if( results.hasOwnProperty( option.name ) )
            {
                list = results[ option.name ];
            }
            else
            {
                list = [];
            }
            
            if( option.splitCommas )
            {
                var items:Array;
                
                if( value.indexOf( "," ) > -1 )
                {
                    items = value.split(",");
                }
                else
                {
                    items = [value];
                }
                
                for each( var element:String in items )
                {
                    _validateAllowed( option, element );
                    list.push( element );
                }
            }
            else
            {
                _validateAllowed( option, value );
                list.push( value );
            }
            
            results[ option.name ] = list;
        }
        
        /**
         * Validates and stores [value] as the value for [option], which must
         * be a flag.
         */
        public function setFlag( results:Object, option:Option, value:Boolean ):void
        {
            _assert( option.isFlag() );
            
            //trace( "setFlag: [" + option.name + "] = " + value );
            results[ option.name ] = value;
        }
        
    }
}