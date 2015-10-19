/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package cli.args
{
    import flash.utils.getQualifiedClassName;
    
    use namespace shadow;
    
    /**
     * A single command.
     * 
     * <p>
     * A command is known as a "leaf command" if it has no subcommands and is
     * meant to be run. Leaf commands must override [run].
     * </p>
     * 
     * <p>
     * A command with subcommands is known as a "branch command" and cannot be
     * run itself. It should call [addSubcommand] (often from the constructor)
     * to register subcommands.
     * </p>
     * 
     * @playerversion AVM 0.4
     * @langversion 3.0
     */
    public class Command
    {
        
        shadow var _parent:Command           = null;
        shadow var _runner:CommandRunner     = null;
        shadow var _globalResults:ArgResults = null;
        shadow var _argResults:ArgResults    = null;
        
        private var _subcommands:Vector.<Command> = new Vector.<Command>();
        private var _subcommandsMap:Object        = {};
        
        private var _description:String;
        
        /**
         * The name of this command.
         */
        public var name:String;
        
        /**
         * The argument parser for this command.
         * 
         * <p>
         * Options for this command should be registered with this parser (often
         * in the constructor); they'll end up available via [argResults].
         * Subcommands should be registered with [addSubcommand] rather than
         * directly on the parser.
         * </p>
         */
        public var argParser:ArgParser = new ArgParser();
        
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
         * Whether or not this command takes positional arguments in addition to
         * options.
         * 
         * <p>
         * If false, [CommandRunner.run] will throw a [UsageException] if
         * arguments are provided. Defaults to true.
         * </p>
         * 
         * <p>
         * This is intended to be overridden by commands that don't want to
         * receive arguments. It has no effect for branch commands.
         * </p>
         */
        public var takesArguments:Boolean = true;
        
        /**
         * Alternate names for this command.
         * 
         * <p>
         * These names won't be used in the documentation, but they will work
         * when invoked on the command line.
         * </p>
         * 
         * <p>
         * This is intended to be overridden.
         * </p>
         */
        public var aliases:Array = [];
        
        /**
         * Create a Command.
         */
        public function Command( name:String = "",
                                 description:String = "" )
        {
            super();
            
            this.name    = name;
            _description = description;
            
            argParser.addFlag( "help", "h", "Print this usage information.", false, false );
        }
        
        // Returns [usage] with [description] removed from the beginning.
        private function get _usageWithoutDescription():String
        {
            var str:String = "";
                str += "Usage: " + invocation + "\n";
                str += argParser.usage + "\n";
                
            if( _subcommands.length > 0 )
            {
                str += "\n";
                str += _getCommandUsage( _subcommands, true ) + "\n";
            }
            
                str += "\n";
                str += "Run \"" + runner.executableName + " help\" to see global options.";
                
            if( usageFooter != "" )
            {
                str += "\n";
                str += usageFooter;
            }
            
            return str;
        }
        
        /**
         * A short description of this command.
         */
        public function get description():String
        {
            return _description;
        }
        
        public function get invocation():String
        {
            var parents:Array = [ name ];
            var command:Command;
            for( command = parent; command != null; command = command.parent )
            {
                parents.push( command.name );
            }
            parents.push( runner.executableName );
            
            var invocations:String = parents.reverse().join( " " );
            
            if( _subcommands.length > 0 )
            {
                return invocations + " <subcommand> [arguments]";
            }
            
            return invocations + " [arguments]";
        }
        
        /**
         * The command's parent command, if this is a subcommand.
         * 
         * <p>
         * This will be `null` until [Command.addSubcommmand] has been called
         * with this command.
         * </p>
         */ 
        public function get parent():Command { return _parent; }
        
        /**
         * The command runner for this command.
         * 
         * <p>
         * This will be `null` until [CommandRunner.addCommand] has been called
         * with this command or one of its parents.
         * </p>
         */
        public function get runner():CommandRunner
        {
            if( parent == null )
            {
                return _runner;
            }
            
            return parent.runner;
        }
        
        /**
         * The parsed global argument results.
         * 
         * <p>
         * This will be `null` until just before [Command.run] is called.
         * </p>
         */
        public function get globalResults():ArgResults { return _globalResults; }
        
        /**
         * The parsed argument results for this command.
         * 
         * <p>
         * This will be `null` until just before [Command.run] is called.
         * </p>
         */
        public function get argResults():ArgResults { return _argResults; }
        
        /**
         * Generates a string displaying usage information for this command.
         * 
         * <p>
         * If a subclass overrides this to return a string, it will
         * automatically be added to the end of [usage].
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
         * An unmodifiable view of all sublevel commands of this command.
         */
        public function get subcommands():Vector.<Command> { return _subcommands; }
        
        public function getSubCommandByName( name:String ):Command
        {
            if( !_subcommandsMap.hasOwnProperty( name ) )
            {
                return null;
            }
            
            return _subcommands[ _subcommandsMap[name] ];
        }
        
        private function _isCommandHidden( item:Command, index:int, vector:Vector.<Command> ):Boolean
        {
            return item.hidden;
        }
        
        /**
         * Whether or not this command should be hidden from help listings.
         * 
         * <p>
         * This is intended to be overridden by commands that want to mark
         * themselves hidden.
         * </p>
         * 
         * <p>
         * By default, leaf commands are always visible. Branch commands are
         * visible as long as any of their leaf commands are visible.
         * </p>
         */
        public function get hidden():Boolean
        {
            // Leaf commands are visible by default.
            if( _subcommands.length == 0 )
            {
                return false;
            }
            
            // Otherwise, a command is hidden if all of its subcommands are.
            return _subcommands.every( _isCommandHidden );
        }
        
        /**
         * Runs this command.
         * 
         * <p>
         * If this returns a [Future], [CommandRunner.run] won't complete until
         * the returned [Future] does. Otherwise, the return value is ignored.
         * </p>
         */
        public function run():void
        {
            var cname:String = getQualifiedClassName( this );
            throw new UninitializedError( "Leaf command " + cname + " must implement run()." );
        }
        
        /**
         * Adds [Command] as a subcommand of this.
         */
        public function addSubcommand( command:Command ):void
        {
            var names:Array = [ command.name ];
                names = names.concat( command.aliases );
            
            var name:String;
            for each( name in names )
            {
                _subcommands.push( command );
                _subcommandsMap[ name ] = _subcommands.length - 1;
                argParser.addCommand( name, command.argParser );
            }
            
            command._parent = this;
        }
        
        /**
         * Prints the usage information for this command.
         * 
         * <p>
         * This is called internally by [run] and can be overridden by
         * subclasses to control how output is displayed or integrate with a
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
    }
}