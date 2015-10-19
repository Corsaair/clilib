/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package cli.args
{
    
    /**
     * Takes an [ArgParser] and generates a string of usage (i.e. help) text for
     * its defined options.
     * 
     * Internally, it works like a tabular printer.
     * The output is divided into three horizontal columns, like so:
     * <pre>
     *     -h, --help  Prints the usage information
     *     |  |        |                                 |
     * </pre>
     * 
     * <p>
     * It builds the usage text up one column at a time and handles padding with
     * spaces and wrapping to the next line to keep the cells correctly lined up.
     * </p>
     * 
     * @playerversion AVM 0.4
     * @langversion 3.0
     */
    public class Usage
    {
        public static const NUM_COLUMNS:uint = 3;
        
        /**
         * A list of the [Option]s intermingled with [String] separators.
         */
        public var optionsAndSeparators:Array;
        
        /**
         * The working buffer for the generated usage text.
         */
        public var buffer:String;
        
        /**
         * The column that the "cursor" is currently on.
         * 
         * <p>
         * If the next call to [write()] is not for this column, it will
         * correctly handle advancing to the next column (and possibly the next
         * row).
         * </p>
         */
        public var currentColumn:int = 0;
        
        /**
         * The width in characters of each column.
         */
        public var columnWidths:Vector.<int>;
        
        /**
         * The number of sequential lines of text that have been written to the
         * last column (which shows help info).
         * 
         * <p>
         * We track this so that help text that spans multiple lines can be
         * padded with a blank line after it for separation. Meanwhile,
         * sequential options with single-line help will be compacted next to
         * each other.
         * </p>
         */
        public var numHelpLines:int;
        
        /**
         * How many newlines need to be rendered before the next bit of text can
         * be written.
         * 
         * <p>
         * We do this lazily so that the last bit of usage doesn't have dangling
         * newlines. We only write newlines right *before* we write some real
         * content.
         * </p>
         */
        public var newlinesNeeded:int;
        
        public function Usage( optionsAndSeparators:Array )
        {
            super();
            
            this.optionsAndSeparators = optionsAndSeparators;
        }
        
        // Pads [source] to [length] by adding spaces at the end.
        /*private function _padRight( source:String, length:int ):String
        {
            var str:String = "";
                str += source;
            
            while( str.length < length )
            {
                str += " ";
            }
            
            return str;
        }*/
        
        private function _trim( source:String , chars:Array = null ):String
        {
            if( chars == null ) { chars = [ " ", "\t" ]; }
            
            if ( source == null || source == "" ) { return "" ; }
            
            var i:int;
            var l:int = source.length ;
            
            for( i = 0; (i < l) && (chars.indexOf( source.charAt( i ) ) > - 1) ; i++ )
            {
            }
            source = source.substring( i );
            
            l = source.length;
            for( i = source.length - 1; (i >= 0) && (chars.indexOf( source.charAt( i ) ) > - 1) ; i-- )
            {
            }
            source = source.substring( 0, i + 1 ) ;
            
            return source;
        }
        
        private function _getKeys( o:Object ):Array
        {
            var keys:Array = [];
            var m:String;
            for( m in o )
            {
                keys.push( m );
            }
            return keys;
        }
        
        /**
         * Generates a string displaying usage information for the defined
         * options.
         * 
         * <p>
         * This is basically the help text shown on the command line.
         * </p>
         */
        public function generate():String
        {
            buffer = "";
            
            calculateColumnWidths();
            
            var optionOrSeparator:*;
            for each( optionOrSeparator in optionsAndSeparators )
            {
                //trace( "optionOrSeparator = " + optionOrSeparator );
                if( optionOrSeparator is String )
                {
                    // Ensure that there's always a blank line before a separator.
                    if( buffer != "" )
                    {
                        buffer += "\n\n";
                    }
                    
                    buffer += optionOrSeparator;
                    newlinesNeeded = 1;
                    continue;
                }
                
                var option:Option = optionOrSeparator as Option;
                if( option.hide )
                {
                    continue;
                }
                
                write( 0, getAbbreviation( option ) );
                write( 1, getLongOption( option ) );
                
                //trace( "option.help = " + option.help );
                //trace( "option.defaultValue = " + option.defaultValue );
                if( option.help != "" )
                {
                    write( 2, option.help );
                }
                
                if( option.allowedHelp != null )
                {
                    //trace( ">>> option.allowedHelp != null" );
                    //trace( "allowedHelp = " + JSON.stringify( option.allowedHelp, null, "    " ) );
                
                    var allowedNames:Array = _getKeys( option.allowedHelp );
                        allowedNames.sort();
                    
                    newline();
                    for each( var name:String in allowedNames )
                    {
                        //trace( "name = " + name );
                        write( 1, getAllowedTitle( name ) );
                        //trace( "help = " + option.allowedHelp[name] );
                        write( 2, option.allowedHelp[name] );
                    }
                    newline();
                }
                
                if( option.allowed != null )
                {
                    //trace( ">>> option.allowed != null" );
                    write( 2, buildAllowedList( option ) );
                }
                else if( (option.defaultValue != null) &&
                    (option.defaultValue != "") )
                {
                    //trace( ">>> option.defaultValue != null" );
                    if( option.isFlag() && (option.defaultValue == true) )
                    {
                        write( 2, "(defaults to on)" );
                    }
                    else if( !option.isFlag() )
                    {
                        write( 2, "(defaults to \"" + option.defaultValue + "\")" );
                    }
                }
                
                /* If any given option displays more than one line of text on
                   the right column (i.e. help, default value, allowed options,
                   etc.) then put a blank line after it. This gives space where
                   it's useful while still keeping simple one-line options
                   clumped together.
                */
                if( numHelpLines > 1 )
                {
                    newline();
                }
                
            }
            
            return buffer;
        }
        
        public function getAbbreviation( option:Option ):String
        {
            if( option.abbreviation != "" )
            {
                return "-" + option.abbreviation + ", ";
            }
            
            return "";
        }
        
        public function getLongOption( option:Option ):String
        {
            var result:String = "";
            
            if( option.negatable )
            {
                result = "--[no-]" + option.name;
            }
            else
            {
                result = "--" + option.name;
            }
            
            if( option.valueHelp != "" )
            {
                result += "=<" + option.valueHelp + ">";
            }
            
            return result;
        }
        
        public function getAllowedTitle( allowed:String ):String
        {
            return "      [" + allowed + "]";
        }
        
        public function calculateColumnWidths():void
        {
            var abbr:int = 0;
            var title:int = 0;
            
            for each( var option:* in optionsAndSeparators )
            {
                if( !(option is Option) )
                {
                    continue;
                }
                
                if( option.hide )
                {
                    continue;
                }
                
                // Make room in the first column if there are abbreviations.
                abbr = Math.max( abbr, getAbbreviation( option ).length );
                
                // Make room for the option.
                title = Math.max( title, getLongOption( option ).length );
                
                // Make room for the allowed help.
                if( option.allowed != null )
                {
                    for( var allowed:String in option.allowedHelp )
                    {
                        title = Math.max( title, getAllowedTitle( allowed ).length );
                    }
                }
            }
            
            // Leave a gutter between the columns.
            title += 4;
            columnWidths = new <int>[abbr, title];
        }
        
        public function newline():void
        {
            newlinesNeeded++;
            currentColumn = 0;
            numHelpLines  = 0;
        }
        
        public function write( column:int, text:String ):void
        {
            //if( text == null ) { return; }
            
            var lines:Array;
            //trace( "text = " + text );
            
            if( text.indexOf( "\n" ) > -1 )
            {
                lines = text.split( "\n" );
            }
            else
            {
                lines = [ text ];
            }
            
            
            
            // Strip leading and trailing empty lines.
            while( (lines.length > 0) && (_trim(lines[0]) == "") )
            {
                lines.splice( 0, 1 );
            }
            
            while( (lines.length > 0) && (_trim(lines[ lines.length - 1 ]) == "") )
            {
                lines.pop();
            }
            
            //trace( "column = " + column );
            //trace( "lines = " + lines );
            //trace( "lines.length = " + lines.length );
            //trace( JSON.stringify( lines, null, "    " ) );
            
            var i:uint;
            var line:String;
            for( i = 0; i < lines.length; i++  )
            {
                line = lines[i];
                //trace( "line = " + line );
                writeLine( column, line );
            }
        }
        
        public function writeLine( column:int, text:String ):void
        {
            // Write any pending newlines.
            while( newlinesNeeded > 0 )
            {
                buffer += "\n";
                newlinesNeeded--;
            }
            
            // Advance until we are at the right column (which may mean wrapping
            // around to the next line.
            while( currentColumn != column )
            {
                if( currentColumn < NUM_COLUMNS - 1 )
                {
                    buffer += _padRight( "", columnWidths[ currentColumn ] );
                }
                else
                {
                    buffer += "\n";
                }
                
                currentColumn = (currentColumn + 1) % NUM_COLUMNS;
            }
            
            if( column < columnWidths.length )
            {
                // Fixed-size column, so pad it.
                buffer += _padRight( text, columnWidths[ column ] );
            }
            else
            {
                // The last column, so just write it.
                buffer += text;
            }
            
            // Advance to the next column.
            currentColumn = (currentColumn + 1) % NUM_COLUMNS;
            
            // If we reached the last column, we need to wrap to the next line.
            if( column == (NUM_COLUMNS - 1) )
            {
                newlinesNeeded++;
            }
            
            // Keep track of how many consecutive lines we've written in the last
            // column.
            if( column == (NUM_COLUMNS - 1) )
            {
                numHelpLines++;
            }
            else
            {
                numHelpLines = 0;
            }
        }
        
        public function buildAllowedList( option:Option ):String
        {
            var str:String = "";
                str += "[";
            
            var first:Boolean = true;
            for each( var allowed:String in option.allowed )
            {
                if( !first )
                {
                    str += ", ";
                }
                
                str += allowed;
                
                if( allowed == option.defaultValue )
                {
                    str += " (default)";
                }
                
                first = false;
            }
            
                str += "]";
            return str;
        }
        
    }
}