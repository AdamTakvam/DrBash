# Admin-Scripts
A collection of bash scripts for basic (and not-so-basic) system administration. See the Philosophy section below for more details on what makes this repo special.

## ASSumptions 
These scripts are only intended to work correctly on Debian 12 with Bash 5. 

So, if you find a bug and you're running something else, you must verify it on this setup before logging it. Otherwise, it will fall under "ports" which is experimental at this time. 

Basically, I'm just one guy and I'm not assuming that anyone will fall in love with a collection of shell scripts to the point that they're motivated to make a big deal out of it by supporting everything under the sun. So it is what it is.

## Installation
* There is no apt package for this repo. These are scripts; the source is the executable.
* Clone this repo then run the ./mkbinlink script to create symlinks in `~/bin` to the executable scripts in this repo.
* Ensure that '~/bin/' is in your path and Bob's your uncle. (I'm not really that old; I just think it's funny)
* Refer to the Scripts section below for a summaery of what the most significant scripts do.

## Usage
How the scripts are used varies depending on the directory they are found in:

* Root of repo: These are all top-level executable scripts. After completing the installation steps described above, you can run them by just specifying the filename without the .sh extension (as they appear in `~/bin`). These should all be relatively complete and mature top-level scripts with their own help (-h) and everything. So approach them as any other software you install via packages.

* env: The scripts in this subdirectory are intended to be sourced into your environment to be used. I suggest adding a `for` loop (warning: the `source` command doesn't always work how you might expect with wildcards) to your `.bashrc` so that they will always be available as any other built-in commands. Here's the copy-pasta for you:

```
for awesomeShellScript in ~/src/admin-scripts/env/*; do
  source $awesomeShellScript
done
```

* lib : These scripts are intended to be sourced by other scripts in order to provide library-like functionality.

* snippets : Examples of how to do certain things, how to call the modules, or just neat bash tricks. The code in here is inttended for copy/paste usage.

* installers : If a script has an external dependency on a package that does not exist in the main Debian repo, then t:noh
ihere should be a script in here that you can run to install that dependency. For the most part, the scripts in here should just add third-party repos so that you can then just `apt-get install` what you need.

# Executable Scripts

To get you oriented, here is a brief overview of the most significant scripts in this repo. Other scripts you may encounter should be used with caution as they may be extremely niche or simply old and poorly maintained. Nonetheless, they should all print a help page when invoked with a '-h'. So either start there or start by just cracking them open and peeking at what is inside, whichever suits you better.

Naming Convention: 
* The directories named with a ".shd" extension contain scripts that were written on the platform. 
* The directories lacking the extension are part of the platform itself.

Remember, after running 'mkbinlink' you don't need to include the ".sh" extension to run any of these scripts nor do you need to be in the directory where they reside.

To learn about all of the options and syntactical details, run the desired script with the "-h" parameter.

[work in progress]

## [root]/
* ad-hoc-web-server : A quick and easy web server that provides HTTP access to whatever files are in the current directory when you run the command.
* chmodt : Adds the ability to specify whether you want chmod to act on only files or directories. Particularly useful if you don't like destroying your directory structure when recursing subdirectories. It's actually quite surprising that this is not in the command itself.
* debug.sh : A simple script to easily run any script you name in the bash debugger.
* explain-this.sh : A tool that dynamically interrogates the scripts in this collection and extracts summaries of their functionality, which it then collates and displays to the user as a README-style document.
* mkbinlink.sh : The exception to the rule. This one is intended to be run directly, ".sh" exetension and all. It makes links in the ~/bin directory for all of the executable scripts in this collection. 
* script.template.sh : An example script that for anyone wanting to write a script leveraging this platform to be able to simply copy and get right to work with all of the platform-specific stuff already taken care of.
* template.shd : This is a different approach to script templating. This one accomplishes much the same goal as script.template.sh, but in a different way. This template is intended to be sourced. It provides many common functions, but delegates the custom parts to the developer by way of prescribed functions that must be implemented. It is currently experimental.

## env/
< See "The Environment Commands" section for more details. >

## lib/
< See "The Base Class Libraries" section for more detauils. >

## media.shd/

## net.shd/

## serial.shd/

## system.shd/

## web.shd/

## zfs.shd/

# Philosophy

What you're looking at is a scriptuiung framework built in Bash for creating a suite of utilities with a common look and feel as well as a structured methodology for developemnt.So, naturally you're going to hate it at first. It's the irony of the fact that offering capabuilities to people also requires introducing usability limitations. So you're going to have to take a moment and read this to be able to undertsand what's going on.

ChatGPT has reveiwed much of this code and it says that I'm taking Bash scripts somewhere that they were never intended to go. I appreciate the compliment. But I'm really just trying to make Bash follow proper programming conventions and structures as much as possible. So you'll note the use of abstractions, inheritance, separation of concerns, data-driven development and all sorts of goodies like that.

To that end, the most important scripts are located in the 'lib/' directory. This is your new Base Class Libraries (BCL). In here, you will find your logging subsystem (logging.sh), a runtime abstraction that integrated with logging to create a sandbox-type experience (run.sh), general helper utilities (general.sh), and specialized utilties (see next section).

# The Base Class Libraries (lib/)
These are the scripts located in 'lib/'. They form the basis for all of the other scripts in this collection.

## run.sh
This is generally the main stareting point and the script that you'll want to include to get the most access to the kingdom. 

* Sources: general.sh, logging.sh
* What happens when I source it? This file does nothing upon being sourced, but check the dependencies!
* What does this file provide? This file gives you a much more capable environment for reliably executing other programs, scriptrs, command, aliases, built-ins, etc. If the code isn't in your script, but it is located elsewhere, just place the word 'Run' before the normal command with all of its parameters just like you normally would and let the framework handle it.
* I don't get it. I can run things just fine now! Sure, because it's your computer and you've got it all setup just the way it needs to be. So of course you can. But is my computer setup to run your stuff? How do you know? If it's not, what are you going to do about it? Run.sh answers those questions. If you wqrite a script that requires 'ffmpeg', for example, run.sh will check whether 'ffmpeg' is installed. If it isn't, run.sh will install it. You see? There's more to this that you thought, huh? Trust the libraries. They've got your back!
* Debug mode: logging.sh includes the concept of a debug mode which can be set by passing '-vv' to any script. Run.sh integrates with this to provide a simulation mode where anything passed in to 'Run' gets all the way to the point of being executed, but at the last moment the command that would have been executed gets logged instead. Thuis provides a built-in way to perform dry runs of things that might alter other files or do things that take a minute to sert back up again before you can do another test run.

## general.sh
A smattering of utility methods and some annoying config loader logic.

* Sources: logging.sh
* What happens when I source it? It will attempt to source $USERDATA/media-scripts.conf. If you don't care about the media management stuff, then just put an empty file there to shut it up.
* What does this file provide? This is a collection of generally helpful little functions arounf user management, sudoing, and stuff like that. It's a short file; it's probably best to just take a quick peek at it.

## logging.sh
The logging subsystem. This is kind of the nexus of the whole thing. All roads lead to logging.sh.

* Sources: arrays.sh
* What happens when I source it? It will ravage your command line arguments at parse out the ones related to logging. This is essentially it setting itself up so that you don't have to worry about it. But maintaining this abstraction does mean you have to do a few things in a very specific way... (see below)
* What does this file provide? Everything you need to log to the console or to the Systemd journal can be found here. There are four logging levels: Quiet, Normal, Verbose, and Debug. These are set automatically depending on whether the user specified -q, [nothing], -v, or -vv on the command line. There are functions for fancy formatting, colors, and all sorts of fun things. There's even an abstraction for reading user input that was recently added. 
* So what needs to be done a specific way? Mostly, your Help() function has to be caerefully written to maintain the abstraction. Hopefully, by the time you read this, a script template will exist in the root of this repository with a working example of exactly what to do. If it isn't, then have a look at how one of the media scripts do it. media-merge.sh is a good example. If you want to see a very complex example, check out media-fixtitle-latest.sh.

Essential functions:

* Log - Writes to the console (stdout). 
* LogError - Writes to the console (stderr)
* LogVerbose - Writes to the console if Verbose mode is active
* LogVerboseError - I think you can guess. We're not trying to trick you here.  ;-)
* LogDebug - Writes to the console if Debug mode is active
* LogDebugError - Rinse and repeat.
* LogParamsHelp - Call this from your Help() function to print the log-related parameters.
* Journal - Write to the SystemD Journaling subsystem
* LogTee - Write to both the console and Journal
* LogHeader - Will spit out whatever you pass into it in what appears to be bold face. Intended for situations where the header takes up the entire line.
* Header - Same as 'LogHeader' except used when you only want to emphasize a portion of the text on a line.
* LogTable - Accepts multiline input and renders it as a table using tab '\t' as the delimiter.
* ColorText - Renders whatever text you pass to it in trhe color you specify. Source this file from your shell and the run 'ShowColors' to see the options.

"Wait a second... why would you ever need to log an error at Verbose or Debug levels?" Great question! Logically, you probably wouldn't. But this isn't logic; this is Bash. In Bash, return values are printed like any other output to stdout and then redirected by the caller to avoid actually printing on screen. In such a method, if you want something to print to the screen, then you have no other choice but to direct it through stderr.

Notes:
* All of the Log* functions accept a message as a parameter or piped in.
* All of the Log* functions know how to render control characters (e.g. '\n')

## arrays.sh
A collection of powerful methods to serializing, deserialkizing, and making bulk edits to arrays.

* Sources: [nothing]
* What happens when I source it? Nothing.
* What does this file provide? A collection of powerful methods to serializing, deserialkizing, and making bulk edits to arrays.

# The Environment Commands
These scripts are intended to be sourced into one's environment - usually in ~/.bashrc - to serve as complimentary commands to the ones Bash natively provides. As such, the script files themselves are of little interest. The important part is the commands themselves, of which there can be many per file. So, lets dig in...

[work in progress]

# Environment Variables
You're going to want to define these in your .bashrc file:

* USERSRC - Set this to the directory that this repo is cloned into
* USERLIB - Set this to: '$USERSRC/lib'
* USERENV - Set this to: '$USERSRC/env'
* USERBIN - Set this to: '$(readlink ~/bin)'
* USERDATA - This is where your config files will be. Can be anywhere except in the directory where you cloned this repo. I set mine to: '"$HOME/src/.data'

These are for the media management sub-project. You can define these in '$USERDATA/media-scripts.conf'

* MEDIADATA - (optional) The location of media-scripts.conf. If not set, USERDATA will be used instead. [don't bother setting this]
* MEDIAREPO - This is your main media repository. Should be '~/media' or '~/movies' or whatever.
* MEDIAEXTS - (optional) File extensions that should be considered media files. Defaults to 'mp4 avi'.
* MEDIAUSER - This is only if you decide to use the permnissions script, which you probably won't. 
* MEDIAGROUP - This and the previous variable are what the permissions script will set your files to.

# Configuration Files
It is only necessary to create these if you want to use the media-related scripts. Even then, all but media-scripts.conf are optional. These are located in '$USERDATA':

* media-scripts.conf - (sourced) An attempt to centralize what config can be centralized among the media scripts. Currently, it's just the collection of environment variables mention above.
* media-fixtags-tagfixes.shdata - (parsed) The contents of an associative array containing regular expressions as keys and literal strings as values. Normal Bash syntax, but only the part that would normally follow after the equals sign in such an array declaration. Used to correct manual entry errors in media file tags.
* media-fixtitle-abbr.shdata - (parsed) This is just a list (one per line) of abbreviations or anything else that you want to always be in upper case in media file names.
* media-fixtitle-delete.shdata - (parsed) This is a list of regular expressions (one per line) that if matched against a filename will indicate that it should be deleted. Examples include stuff like '.crdownload', '.part', etc. 
* media-fixtitle-filler.shdata - (parsed) This is basically the opposite of media-fixtitle-abbr.shdata. Anothing you want to always be in lowercase gets listed here. These are usually filler words like "a", "in", "the", etc. Note: This does not apply to the first word in a title.
* media-fixtitle-patterns.shdata - (parsed) This is a list of regular expressions (one per line) that will be removed from media filenames. This is different from delete that deletes all files with names matching the pattern. Instead this matches and removes substrings from titles.
* setperms.conf - (sourced) Sets a few environment variables used by the setperms.sh script that you won't use, so don't worry about it.

# FAQ

Q: That is quite a big assumption that you've based these scripts on. What if I'm inclined to help expand the range of systems these scripts work on?

A: If you are running another distro, notice a script not working properly, are motivated to get the script working on that distro, and add proper conditional code to make your changes take effect only on the distros you've tested and certified the functionality on, then by all means issue a pull request for that shizz. 
However, I'm not especially interested in backports to earlier versions of Bash prior to 4 because I'm well aware that I make heavy use of Bash-isms that didn't exist in Bash 3. So let's just let the past stay in the past, OK?

Q: Why can't I install these utilities as a package with apt?

A: Because we're just not that cool yet. Maybe one day..

Q: You say Bash, but will these run under 'ksh', 'zsh', or 'fish'?

A: Yes. The scripts in the .shd directories should run fine. They've had limited testing on zsh and they worked fine because the shebang line causes them to run under bash regardless of the shell used to invoke them. However, you could run into issues with sourcing the scripts in 'env/'.

