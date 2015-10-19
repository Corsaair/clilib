/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package cli.args
{
    use namespace shadow;
    
    /**
     * A class for invoking [Commands] based on raw command-line arguments.
     * 
     * @playerversion AVM 0.4
     * @langversion 3.0
     */
    public class CommandRunner
    {
        
        private var _commands:Vector.<Command> = new Vector.<Command>();
        private var _commandsMap:Object        = {};
        
        private var _description:String;
        
        /**
         * The name of the executable being run.
         * 
         * <p>
         * Used for error reporting and [usage].
         * </p>
         */
        public var executableName:String;
        
        /**
         * An optional footer for [usage].
         * 
         * <p>
         * If a subclass overrides this to return a string, it will
         * automatically be added to the end of [usage].
         * </p>
         */
        public var usageFooter:String = "";
        
        /**
         * The top-level argument parser.
         * 
         * <p>
         * Global options should be registered with this parser; they'll end up
         * available via [Command.globalResults].
         * Commands should be registered with [addCommand] rather than directly
         * on the parser.
         * </p>
         */
        public var argParser:ArgParser = new ArgParser();
        
        /**
         * 
         */
        public function CommandRunner( executableName:String = "",
                                       description:String = "" )
        {
            super();
            
            this.executableName = executableName;
            _description        = description;
            
            argParser.addFlag( "help", "h", "Print this runner usage information.", false, false );
            addCommand( new HelpCommand() );
        }
        
        // Returns [usage] with [description] removed from the beginning.
        private function get _usageWithoutDescription():String
        {
            var usage:String = "";
                usage += "Usage: " + invocation + "\n";
                usage += "\n";
                usage += "Global options:\n";
                usage += argParser.usage + "\n";
                usage += "\n";
                usage += _getCommandUsage( _commands ) + "\n";
                usage += "\n";
                usage += "Run \"" + executableName + " help <command>\"";
                usage += " for more information about a command.";
                
            if( usageFooter != "" )
            {
                usage += "\n" + usageFooter;
            }
            
            return usage;
        }
        
        /**
         * A short description of this executable.
         */
        public function get description():String
        {
            return _description;
        }
        
        /**
         * A single-line template for how to invoke this executable.
         * 
         * <p>
         * Defaults to "$executableName &lt;command&gt; [arguments]".
         * Subclasses can override this for a more specific template.
         * </p>
         */
        public function get invocation():String
        {
            return executableName + " <command> [arguments]";
        }
        
        /**
         * Generates a string displaying usage information for the executable.
         * 
         * <p>
         * This includes usage for the global arguments as well as a list of
         * top-level commands.
         * </p>
         */
        public function get usage():String
        {
            var str:String = "";
                str += description;
                str += "\n\n";
                str += _usageWithoutDescription;
            
            return str;
        }
        
        /**
         * An unmodifiable view of all top-level commands defined for this runner.
         */
        public function get commands():Vector.<Command>
        {
            return _commands;
        }
        
        private function _getCommandByNameFrom( name:String, commands:Vector.<Command> ):Command
        {
            var command:Command;
            for each( command in commands )
            {
                if( command.name == name )
                {
                    return command;
                }
            }
            
            return null;
        }
        
        public function getCommandByName( name:String ):Command
        {
            if( !_commandsMap.hasOwnProperty( name ) )
            {
                return null;
            }
            
            return _commands[ _commandsMap[name] ];
        }
        
        /**
         * Adds [Command] as a top-level command to this runner.
         */
        public function addCommand( command:Command ):void
        {
            command._runner = this;
            
            //trace( "add command = " + command.name );
            //trace( "command: " + JSON.stringify( command, null, "  " ) );
            var names:Array = [ command.name ];
                names = names.concat( command.aliases );
            //trace( "names = " + names );
            
            var name:String;
            for each( name in names )
            {
                _commands.push( command );
                _commandsMap[ name ] = _commands.length - 1;
                argParser.addCommand( name, command.argParser );
            }
            
            
        }
        
        /**
         * Prints the usage information for this runner.
         * 
         * <p>
         * This is called internally by [run] and can be overridden by
         * subclasses to ontrol how output is displayed or integrate with a
         * logging system.
         * </p>
         */
        public function printUsage():void
        {
            trace( usage );
        }
        
        /**
         * Throws a [UsageException] with [message].
         */
        public function usageError( message:String ):void
        {
            throw new UsageError( message, _usageWithoutDescription );
        }
        
        /**
         * Parses [args] and invokes [Command.run] on the chosen command.
         * 
         * <p>
         * This always returns a [Future] in case the command is asynchronous.
         * The [Future] will throw a [UsageError] if [args] was invalid.
         * </p>
         */
        public function run( args:Array ):void
        {
            try
            {
                runCommand( parse( args ) );
            }
            catch( e:UsageError )
            {
                trace( e );
            }
            
        }
        
        /**
         * Parses [args] and returns the result, converting a [FormatException]
         * to a [UsageException].
         * 
         * <p>
         * This is notionally a protected method. It may be overridden or called
         * from subclasses, but it shouldn't be called externally.
         * </p>
         */
        protected function parse( args:Array ):ArgResults
        {
            try
            {
                // TODO: if arg parsing fails for a command, print that command's
                // usage, not the global usage.
                return argParser.parse( args );
            }
            catch( e:Error )
            {
                usageError( e.message );
            }
            
            return null;
        }
        
        /**
         * Runs the command specified by [topLevelResults].
         * 
         * <p>
         * This is notionally a protected method. It may be overridden or called
         * from subclasses, but it shouldn't be called externally.
         * </p>
         * 
         * <p>
         * It's useful to override this to handle global flags and/or wrap the
         * entire command in a block. For example, you might handle the
         * `--verbose` flag here to enable verbose logging before running the
         * command.
         * </p>
         */
        protected function runCommand( topLevelResults:ArgResults ):void
        {
            var argResults:ArgResults = topLevelResults;
            var commands:Vector.<Command> = _commands.concat();
            var command:Command = _getCommandByNameFrom( argResults.name, commands );
            var commandString:String = executableName;
            
            //trace( "runCommand - argResults[" + argResults.name + "] = " + argResults );
            //trace( "runCommand - argResults: " + JSON.stringify( argResults, null, "    "  ) );
            
            while( commands.length > 0 )
            {
                //trace( "commands.length = " + commands.length );
                
                if( argResults.command == null )
                {
                    if( argResults.rest.length == 0 )
                    {
                        if( command == null )
                        {
                            // No top-level command was chosen.
                            printUsage();
                            return;
                        }
                        
                        command.usageError( "Missing subcommand for \"" + commandString + "\"." );
                    }
                    else
                    {
                        if( command == null )
                        {
                            usageError( "Could not find a command named \"" + argResults.rest[0] + "\"." );
                        }
                        
                        command.usageError( "Could not find a subcommand named \"" + argResults.rest[0] + "\" for \"" + commandString + "\"." );
                    }
                }
                
                // Step into the command.
                //trace( "--step--" );
                //argResults = argResults.command;
                //trace( "argResults[" + argResults.name + "] = " + argResults );
                //command = _commands[ _commandsMap[ argResults.name ] ];
                //command = getCommandByName( argResults.name );
                command = _getCommandByNameFrom( argResults.name, commands );
                //trace( "command = " + command );
                if( command != null )
                {
                    command._globalResults = topLevelResults;
                    command._argResults = argResults;
                    commands = command.subcommands;
                }
                commandString += " " + argResults.name;
                
                //trace( "argResults.options[name] =" + argResults.options["help"] );
                //trace( "argResults[name] =" + argResults["help"] );
                
                //if( argResults.hasOwnProperty( "help" ) )
                if( command.name == "help" )
                {
                    //trace( ">>> found help" );
                    //trace( "command = " + command );
                    //command.printUsage();
                    command.run();
                    return;
                }
                
            }
            
            // Make sure there aren't unexpected arguments.
            if( !command.takesArguments && (argResults.rest.length != 0) )
            {
                command.usageError( "Command \"" + argResults.name + "\" does not take any arguments." );
            }
            
            command.run();
        }
        
    }
}