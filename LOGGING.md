# DrBash `logging.sh` — Function Reference

_Source: ./lib/logging.sh_

### _Log (private)

_No doc block above function._

### _Journal (private) — If -- passed in, check stdin

### _GetCaller (private) — Look for the first caller that isn't from this file



99% of the time, it won't have a path anyway
  but just for uniformity's sake.



-------------------- System Log / Journal ---------------------------------------


Writes the specified message to the system log/journal
+ $1 = (optional) Parameters to pass to the logger command
+ $2 = The message to write or -- to send piped content
+ stdin = The message to write
- journalctl = The message


### Journal — Writes the specified message to the system log/journal

+ $1 = (optional) Parameters to pass to the logger command
+ $2 = The message to write or -- to send piped content
+ stdin = The message to write
- journalctl = The message


### JournalError — Writes the specified message to the console and the system log

+ $1 = (opt) parameters to apply to the echo command. -e is already applied.
+ $2 = Ass and Pussy destructionThe message to write (supports escaped control characters) or -- to send piped content
+ stdin = The message to write (supports escaped control characters)
+ stdout = The message
- journalctl = The message


### LogTee — Writes the specified message to the console and the system log

+ $1 = (opt) parameters to apply to the echo command. -e is already applied.
+ $2 = The message to write (supports escaped control characters) or -- to send piped content
+ stdin = The message to write (supports escaped control characters)
+ stderr = The message
- journalctl = The message


### LogErrorTee — -------------------- Console Output ---------------------------------------



Writes the specified message to the console
Supports piped messages with or without other parameters when you specify --
Calling Log with no parameters will generate a newline
Escape sequences are interpreted by default unless you specify -l
+ $1 = (opt) INTERNAL parameters to apply to the log output
       -c=CODE = Print message in color
       -t=TITLE = Prefix TITLE to message
       -s=STACK = Prefix STACK to message
+ $2 = (opt) EXTERNAL parameters to apply to log output
       -n = Suppress newline
       -l = Stop trying to be smart and output LITERALLY what I'm telling you!
       -ln = Literal value with no newline
       -lr = Literal and right-justified
       -lrn = Literal and right-justified with no newline
+ $3 = The message to write or -- for stdin
+ stdin = The message to write
- stdout = The message


### Log — LogDebugEnabled && printf "Log() called with %s parameters\n" $#



The parameters handled here are for internal use only




Logs *exactly* what you pass in with no interpretation of anything
+ $1 = (opt) Parameter to control how the output is presented.
       -n = Do not inject a newline after the message
+ $2 = The message to log
+ stdin = (alt) The message to write
- stdout = Your exact message


### LogLiteral — Writes the specified message to stderr

+ $1 = (opt) parameters to apply to the echo command. -e is already applied.
        -x will suppress color and stack trace output
+ $2 = The message to write (supports escaped control characters) or -- to send piped content
+ stdin = The message to write (supports escaped control characters)
- stderr = The message


### LogError — If caller is requesting the literal message, do not attempt to set color.


Logs a message to stderr without all of the pomp and circumstance of LogError
This function is intended to be used exclusively in the situation where a function
  must display output and also return a value.


### LogErrorCovert — Writes the specified message to the console if verbose logging is enabled

+ $1 = (opt) parameters to apply to the echo command. -e is already applied.
+ $2 = The message to write (supports escaped control characters)
+ stdin = The message to write (supports escaped control characters)
+ $VERBOSE = Set to enable verbose logging
- stdout = The message


### LogVerbose — Writes the specified message to stderr if verbose logging is enabled

+ $1 = (opt) parameters to apply to the echo command. -e is already applied.
+ $2 = The message to write (supports escaped control characters)
+ stdin = The message to write (supports escaped control characters)
- stderr = The message


### LogVerboseError — Explanation: There's only one reason to call this function.

  You're in a situation where you want to print verbose output 
  but you're in a function that also returns a value.
  So you're just doing an end-run around bash's silly limitations.
  Ergo, it's not truly an error.
  Any legitimate error should not be hidden from the user based on log level
  and thus should go through LogError().

Writes the specified message to the console if debug logging is enabled
+ $1 = (opt) parameters to apply to the echo command. -e is already applied.
+ $DEBUG = Set to enable debug logging
- stdout = The message


### LogDebug — Writes the specified message to stderr if debug logging is enabled

+ $1 = (opt) parameters to apply to the echo command. -e is already applied.
+ $2 = The message to write (supports escaped control characters)
+ stdin = The message to write (supports escaped control characters)
- stderr = The message


### LogDebugError — Explanation: See LogVerboseError()



-------------------- Pretty Printing ---------------------------------------


Writes the specified message formatted as a table to stdout.
Message is formatted as a table using tabs (\t) to denote columns.
+ $1 = (opt) parameters to apply to the echo command. -e is already applied.
+ $2 = The message to write (supports escaped control characters)
+ stdin = The message to write (supports escaped control characters)
- stdout = The message


### LogTable — Writes the specified message formatted as a table to stderr

Message is formatted as a table using tabs (\t) to denote columns.
+ $1 = (opt) parameters to apply to the echo command. -e is already applied.
+ $2 = The message to write (supports escaped control characters)
+ stdin = The message to write (supports escaped control characters)
- stderr = The message


### LogTableError — Writes the specified messages in columns to the terminal.

If no column width is specified, when it will be assumed to be one character wider than the longest string in the left column values.
+ $1 = Name of an array containing the values to display in the left column
+ $2 = Name of an array containing the values to display in the right column
+ $3 = (optional) The width of the left column


### LogTableLiteral — Determine left column width, if not specified


Determine total number of rows

Display the table

Logs a message is the indicated color. 
Source this file and run ShowColors() to see your options.
This function is the top-level version of the inline ColorText() function.
+ $1 = The desired color
+ $2 = (optional) Any parameters you want to pass to Log()
+ $3 = The message
- stdout = The message displayed in the specified color.


### LogColor — Gives the appearance of the passed-in text being in bold face.

This function is intended to be a top-level call or alternative to Log().
+ $1 = The message to write or -- if stdin
+ stdin = The message to write 
- stdout = The message


### LogHeader — Gives the appearance of the passed-in text being in bold face.

Whether this effect works or not will depend on the color pallete 
  of your terminal emulator. If white and light gray look the same
  then this function will accomplish nothing.
This functioun is intended to be called within quoted text.
+ $1 = The header/title text or -- if stdin.
+ stdin = The header/title text (in leiu of $1).
- stdout = Your new far-more-magnanimous text!


### Header — Alias for Header()

### Bold — Formats your tab-delimited text into a table

+ stdin = Your complete single or multi-line text
- stdout = Your text now formatted into columns


### FormatTable — Writes the specified message in bold face to stderr

Message is formatted as a table using tabs (\t) to denote columns.
+ $1 = (opt) parameters to apply to the Log command.
+ $2 = The message to write 
+ stdin = The message to write 
- stderr = The message


### LogHeaderError — Prints a log message visually set apart as a quote

+ $1 = (opt) parameters to apply to the Log command.
+ $2 = The message to write
+ stdin = (alt) The message to write
- stdout = The message


### LogQuote — Print message right-justified in the console window

+ $1 = (opt) Parameter to control how the output is presented.
       -n = Do not inject a newline after the message
+ $2 = The message to log
- stdout = Your exact message, right-justified


### LogRight — Print message with an underline effect

Output will consume 2 rows of display
Line will be the same length as your text
+ $1 = (opt) Display options
        -c = Centered text
+ $2 = Message
+ $3 = (opt) Character to use for the underline effect
- stdout = Your exact message with a row of = on the subsequent line


### LogUnderline — 1. Calculate position

Centered?

2. Print message
3. Underline


-------------------- Logging Verbosity ---------------------------------------


Enable verbose logging


### LogEnableVerbose — Ask if verbose logging has been enabled

### LogVerboseEnabled — Enable debug & verbose level logging

### LogEnableDebug — Ask if debug logging has been enabled

### LogDebugEnabled — Disable any output to stdout. stderr and other types of logs remain active.

Mutually exclusive with verbose and debug logging. If both specified, quiet wins.


### LogEnableQuiet — Ask if quiet mode has been enabled

### LogQuietEnabled — -------------------- Parameter Parsing ---------------------------------------



Prints the lines in the help screen for the built-in parameters.
  If using LogTable for the other parameters, include the output of this 
  function right along with the others.
By default, all parameters are printed.
+ $1 - $n = (opt) [named param] "PARAMETER={0 | 1}" to disable/enable that parameter.
            If a parameter is specified more than once, the last one wins.
- stdout = The requested lines to include in your parameter description table
Example: If you wanted to suppress the description of -q, the you would call this function like:
  LogParamsHelp -q=0



### LogParamsHelp — Note: This function, called automatically, reads the parameters

    and takes appropriate action on them,
    but it does not remove them from the parameter list ($@), 
    so you may still need to ignore them to avoid interpeetting them as invalid.
    To do that, compare them against the array LOGPARAMS.
    You can drop it right into a case statement, like
      case $param in
        "${LOGPARAMS[*]}")
          # ignore
          ;;
      esac
    Note the use of * rather than @. That's important.


Formats the CLI parameters handled by this script in the necessary format for use as a 'case' clause.
This is necessary for client scripts that want to detect invalid flags 
  or use the * match term to initialize stand-alone parameters.
They need to know to ignore these so that they aren't throwing an error when someone passes in a -v
Example Usage:
  case $a in
    *($(LogParamsCase))* )
      : ;;    # Ignore
  esac
Note: This usage requires extended globs to be enabled




### LogParamsCase

_No doc block above function._

### _ParseCLI (private) — Transparently parse certain reserved flags from CLI parameters



-------------------- Pretty Colors ---------------------------------------



Prints all of the available color names in their respective color.
- stdout = a list of colored color names. One per line.


### ShowColors — Corrects and validates color names against the supported set

+ $1 = The color name
- retVal = Success if the color could be matched.
- stdout = The corrected color name


### ValidateColorName — Try to figure out what color the caller is trying to identify

### GetColorCode — LogDebugError "Getting color code for: $1"

 LogDebugError "Validated color name: $_cName"
 LogDebugError -l "Returning color code: $_colorCode" 

Returns your text ready to be displayed in the indicated color.
This function must be called inline of a 'Log*' or 'printf "%b"'.
If you want to easily color an entire line of text, use LogColor()
+ $1 = (optional) -e : Indicates that you need an extra escape character in order to force colors down sed's throat!
+ $2 = The desired text color. Value must exist within the set of keys of COLOR (i.e. ${!COLOR[@]})
+ $3 = The boring text that will soon be Fabyuloos!
- stdout = Your new enhanced text experience. Works seamlessly with Log(). But if using echo, don't forget the -e !


### ColorText — For backward-compatability reasons,

  the extra escape flag can also be
  in the trailing position.

Ensure that color is a valid choice


ALL OF THE THINGS THAT ARE INVOKED AUTOMATICALLY SHALL APPEAR BENEATH THIS TEXT!


We can't check whether we're being sourced as a condition to run
  because we're always being sourced. 
So, all we can do is not be harmful if we're being loaded for some other purpose



