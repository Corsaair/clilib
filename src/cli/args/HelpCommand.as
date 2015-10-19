/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package cli.args
{
    
    /**
     * The built-in help command that's added to every [CommandRunner].
     * 
     * <p>
     * This command displays help information for the various subcommands.
     * </p>
     * 
     * @playerversion AVM 0.4
     * @langversion 3.0
     */
    public class HelpCommand extends Command
    {
        public function HelpCommand()
        {
            super( "help" );
        }
        
        /** @inheritDoc */
        public override function get description():String
        {
            return "Display help information for " + runner.executableName + "."
            //return "Display help information for runner.executableName."
        }
        
        /** @inheritDoc */
        public override function get invocation():String
        {
            return runner.executableName + " help [command]";
            //return "runner.executableName help [command]";
        }
        
        /** @inheritDoc */
        public override function run():void
        {
            trace( "HelpCommand.run()" );
            trace( "rest = " + argResults.rest );
            
            // Show the default help if no command was specified.
            if( argResults.rest.length == 0 )
            {
                runner.printUsage();
                return;
            }
            
            // Walk the command tree to show help for the selected command or
            // subcommand.
            var commands:Vector.<Command> = runner.commands;
            var command:Command = null;
            var commandString:String = runner.executableName;
            
            for each( var name:String in argResults.rest )
            {
                trace( "name = " + name );
                if( commands.length == 0 )
                {
                    command.usageError( "Command \"" + commandString + "\" does not expect a subcommand." );
                }
                
                if( runner.getCommandByName( name ) == null )
                {
                    if( command == null )
                    {
                        runner.usageError( "Could not find a command named \"" + name + "\"." );
                    }
                    
                    command.usageError( "Could not find a subcommand named \"" + name + "\" for \"" + commandString + "\"." );
                }
                
                command = runner.getCommandByName( name );
                commands = command.subcommands;
                commandString += " " + name;
            }
            
            command.printUsage();
        }
        
    }
}