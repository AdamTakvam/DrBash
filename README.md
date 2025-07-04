[![License](https://img.shields.io/github/license/AdamTakvam/admin-scripts)](https://github.com/AdamTakvam/admin-scripts)
[![Tests](https://github.com/AdamTakvam/admin-scripts/actions/workflows/tests.yml/badge.svg)](https://github.com/AdamTakvam/admin-scripts)
[![ShellCheck Can Kick Rocks](https://img.shields.io/badge/ShellCheck-can_kick_rocks-yellow)](https://github.com/AdamTakvam/admin-scripts)
[![ChatGPT](https://img.shields.io/badge/ChatGPT-4.1--Approved-blueviolet?style=flat)](https://github.com/AdamTakvam/admin-scripts)


# Dr. Bash
A platform for building professional-grade Bash scripts. We make Bash beautiful in spite of itself!
Includes a collection of scripts for basic (and not-so-basic) system administration and a whole "thing" for managing large media file repositories. 
See the Philosophy section below for more details on what makes this repo special.

## ASSumptions 
These scripts are only intended to work correctly on Debian 12 (and derivatives thereof) with Bash 5.x. I'm not aware of any incompatibilities with Bash 4.x, but I'm not actively validating the scripts on that version, so you might run into issues. Bash 3.x is definitely not compatible.

So, if you find a bug and you're running something else, you must verify it on this setup before logging it. Otherwise, it will fall under "ports" which is not really a thing unless you want to make it a thing. 

Basically, I'm just one guy and I'm not assuming that anyone will fall in love with this platform or motley collection of shell scripts to the point that they're motivated to make a big deal out of it by supporting everything under the sun. So it is what it is. If I'm wrong, hey, that would be cool too!

## Installation

### For users of this project:
* Download one of the two release types:
  * Full = Everything
  * Lite = Everything minus `media.shd/`
* Unzip the downloaded file
* Run `./install`
* Follow any additional instructions that the installer may provide

### For contributors to this project:
* Clone this repo then run the ./mkbinlink script to create symlinks in `~/bin` to the executable scripts in this repo.
* Ensure that `~/bin/` is in your path and Bob's your uncle. (I'm not really that old; I just think it's funny)
* Refer to the Scripts section below for a summary of what the most significant scripts do.
* Check for README.md files in the subdirectories for a technical description of every single script
  * If no README files exist in the subdirectories, that's because the planned tool to generate them has not been built yet

## Usage
How the scripts are used varies depending on the directory they are found in:

* Root of repo: These are scripts related to packaging and installing the platform itself as well as some files to help make developing new scripts on the platform as painless as possible.

* lib : These scripts are intended to be sourced by other scripts in order to provide library-like functionality.
  
* env: The scripts in this subdirectory are intended to be sourced into your environment to be used. I suggest adding a `for` loop (warning: the `source` command doesn't always work how you might expect with wildcards) to your `.bashrc` so that they will always be available as any other built-in commands. Here's the copy-pasta for you:

```
for script in /usr/local/env/*; do
  source $script
done
```
* *.shd/: These are scripts born of necessity related to the area of system administration indicated by the directory name. After completing the installation steps described above, you can run them by just specifying the filename without the .sh extension (as they appear in `~/bin`). These should all be relatively complete and mature top-level scripts with their own help (-h) and everything. So approach them as any other software you install via packages.


# Upcoming Features (no release date commitments)
* Finish out the template script.
* Get `explain_this.sh` working to generate README files dynamically for the subdirectories by pulling metadata from the scripts (like a doxygen sort of thing).
* Create a new base library `lib/help.cs` which is anticipated to be necessary to implement `explain_this.sh` the way I want to.
* Create and install actual manpages for this stuff.
* Package as a `.deb` and perhaps trick someone into hosting it for me.
* Continue development on the media management platform. I've gotten as far with it as I can with Bash and it's definitely usable in its current form. So, I started to develop the deduplication logic in Python. But I really don't have a compelling reason to learn Python, especially when I already know C# inside and out. So all future media platform development will be in C#. Sorry, not sorry.

# Executable Scripts
To get you oriented, here is a brief overview of the scripts in the root or the repo as well as the `*.shd/` subs generally. A detailed description of the `lib/` and `env/` subs can be found further down in this epic docxument.
For informatiuon on the scripts in the `*.shd/` subs, refer to the README files in those respective subs.
For a more detailed explanation of exactly what each script does, simply run it with the `-h` and all will be revealed.
One near-term goal is to automate the generation of README files for each of the `*.shd/` subdirectories. `lib/` and `env/` will be automated eventually, but that's a different task due to the nature of those files.

Naming Convention: 
* The directories named with a `.shd` extension contain scripts that were written on the platform. 
* The directories lacking the extension are part of the platform itself.

Remember, after running `install` or `mkbinlink` you don't need to include the ".sh" extension to run any of these scripts nor do you need to be in the directory where they reside.

To learn about all of the options and syntactical details, run the desired script with the `-h` parameter.

## /
* debug.sh : A simple script to easily run any script you name in the bash debugger. You need to run this one directly with some ./ love because - unlike the *.shd/ scripts - this one isn't in your $PATH. [stable]
* explain-this.sh : A tool that dynamically interrogates the scripts in this collection and extracts summaries of their functionality, which it then collates and displays to the user as a README-style document. [WIP]
* mkbinlink.sh : Part of the installation process, but also helpful if you develop new scripts. It creates a symlink in your ~/bin/ directory pointing to the script file you indicate. It also handles file permissions, making sure your script is executable, and generally just helps ensure that you don't mess it up because it's easier than you think! Unlike the scripts in the *.shd/ subs, you've got to run this one with a full path to it. It's highly recommended to change to the repo root and give it the old ./ treatment. [stable]
* script.template.sh : An example script that for anyone wanting to write a script leveraging this platform to be able to simply copy and get right to work with all of the platform-specific stuff already taken care of. [WIP]
* template.shd : This is a different approach to script templating. This one accomplishes much the same goal as script.template.sh, but in a different way. This template is intended to be sourced. It provides many common functions, but delegates the custom parts to the developer by way of prescribed functions that must be implemented. It is currently experimental. [WIP]

## grav.shd
A collection of commands to help automate the provisioning and use of Grav CMS. WordPress is a scam and it sucks.

## media.shd/
A suite of utilities for managing a large library of media files. What constitutes a "large" library? My test library stands at over 6,000 titles, so at least that many!
Status:
* Ingest: Complete / Stable
* Deduping: Experimental
* Indexing: In Development
* Search: Primitive / Stable

## net.shd/
A set of utilities for wrestling control of your network when you have far too many network adapters.

## serial.shd/
One word: Cisco
But certainly can be useful for any appliance with a serial port interface.

## system.shd/
A collection of commands to make life as a system administrator more palatable.

## zfs.shd/
It may be the best file system ever, but there's always room for some tweaks.

# Philosophy

What you're looking at is a scripting framework built in Bash for creating a suite of utilities with a common look and feel as well as a structured methodology for developemnt. So, naturally you're going to hate it at first. It's the irony of the fact that offering capabilities to people also requires introducing usability limitations. So you're going to have to take a moment and read this to be able to understand what's going on.

ChatGPT has reveiwed much of this code and it says that I'm taking Bash scripts somewhere that they were never intended to go. I appreciate the compliment. But I'm really just trying to make Bash follow proper programming conventions and structures as much as possible. So you'll note the use of abstractions, inheritance, separation of concerns, data-driven development and all sorts of goodies like that.

To that end, the most important scripts are located in the 'lib/' directory. This is your new Base Class Libraries (BCL). In here, you will find your logging subsystem (logging.sh), a runtime abstraction (run.sh) that integrates with logging to create a sandbox-type experience, general helper utilities (general.sh), and some specialized utilties (see next section).

# The Base Class Libraries (lib/)
These are the scripts located in 'lib/'. They form the basis for all of the other scripts in this collection.

## run.sh
This is generally the main starting point and the script that you'll want to include to get the most access to the kingdom. 

* Sources: general.sh, logging.sh
* What happens when I source it? This file does nothing upon being sourced, but check the dependencies!
* What does this file provide? This file gives you a much more capable environment for reliably executing other programs, scripts, commands, aliases, built-ins, etc. If the code isn't in your script, but it is located elsewhere, just place the word 'Run' before the normal command with all of its parameters just like you normally would and let the framework handle it.
* "I don't get it. I can run things just fine now!" Sure, because it's your computer and you've got it all setup just the way it needs to be. So of course you can. But is my computer setup to run your stuff? How do you know? If it's not, what are you going to do about it? Run.sh answers those questions. If you write a script that requires 'ffmpeg', for example, run.sh will check whether 'ffmpeg' is installed. If it isn't, run.sh will install it. You see? There's more to this that you thought, huh? Trust the libraries. They've got your back!
* Debug mode: logging.sh includes the concept of a debug mode which can be set by passing '-vv' to any script. Run.sh integrates with this to provide a simulation mode where anything passed in to 'Run' gets all the way to the point of being executed, but at the last moment the command that would have been executed gets logged instead. Thuis provides a built-in way to perform dry runs of things that might alter other files or do things that take a minute to set back up again before you can do another test run.

## general.sh
A smattering of utility methods and some annoying config loader logic.

* Sources: logging.sh
* What happens when I source it? It will attempt to source $USERDATA/media-scripts.conf. If you don't care about the media management stuff, then just put an empty file there to shut it up.
* What does this file provide? This is a collection of generally helpful little functions around user management, sudoing, and stuff like that. It's a short file; it's probably best to just take a quick peek at it.

## logging.sh
The logging subsystem. This is kind of the nexus of the whole thing. All roads lead to logging.sh.

* Sources: arrays.sh
* What happens when I source it? It will ravage your command line arguments and parse out the ones related to logging. It's self-configuring so that you don't have to worry about it. But maintaining this abstraction does mean you have to do a few things in a very specific way... (see below)
* What does this file provide? Everything you need to log to the console or to the Systemd journal can be found here. There are four logging levels: Quiet, Normal, Verbose, and Debug. These are set automatically depending on whether the user specified -q, [nothing], -v, or -vv on the command line. There are functions for fancy formatting, colors, and all sorts of fun things. There's even an abstraction for reading user input that was recently added. 
* So what needs to be done a specific way? Mostly, your Help() function has to be caerefully written to maintain the abstraction. Hopefully, by the time you read this, a script template will exist in the root of this repository with a working example of exactly what to do. If it isn't, then have a look at how one of the media scripts does it. media-merge.sh is a good example. If you want to see a very complex example, check out media-fixtitle-latest.sh.

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
A collection of powerful methods to serializing, deserializing, and making bulk edits to arrays.

* Sources: [nothing]
* What happens when I source it? Nothing.
* What does this file provide? A collection of powerful methods to serializing, deserializing, and making bulk edits to arrays.

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

* media-scripts.conf - (sourced) An attempt to centralize what config can be centralized among the media scripts. Currently, it's just the collection of environment variables mentioned above.
* media-fixtags-tagfixes.shdata - (parsed) The contents of an associative array containing regular expressions as keys and literal strings as values. Normal Bash syntax, but only the part that would normally follow after the equals sign in such an array declaration. Used to correct manual entry errors in media file tags.
* media-fixtitle-abbr.shdata - (parsed) This is just a list (one per line) of abbreviations or anything else that you want to always be in upper case in media file names.
* media-fixtitle-delete.shdata - (parsed) This is a list of regular expressions (one per line) that if matched against a filename will indicate that it should be deleted. Examples include stuff like '.crdownload', '.part', etc. 
* media-fixtitle-filler.shdata - (parsed) This is basically the opposite of media-fixtitle-abbr.shdata. Anything you want to always be in lowercase gets listed here. These are usually filler words like "a", "in", "the", etc. Note: This does not apply to the first word in a title.
* media-fixtitle-patterns.shdata - (parsed) This is a list of regular expressions (one per line) that will be removed from media filenames. This is different from delete that deletes all files with names matching the pattern. Instead this matches and removes substrings from titles.
* setperms.conf - (sourced) Sets a few environment variables used by the setperms.sh script that you won't use, so don't worry about it.

# Functional Tests
They exist! But you'll be shocked to learn that the code coverage is pitiful and really the only file with anything resembling comprehensive coverave is `lib/logger.sh`. It's tests are located in `lib/logger.tests.sh`. To run the tests, just execute the script.
There needs to be more of that sort of thing going on...

# FAQ

Q: What are derivatives of Debian?

The Linux ecosystem of operating systems is organized into families. Families have a progenitor or "root distribution" that leads the way by starting witgh the Linux kernel and making all of the fundamental tooling and pathing decisions necessary to make the kernel into a full-fledged operating system. 
Within a family, there may or may not exist derivatives of a core distro. Other distributions or "distros" put theirr own spin on the root distribution, but usually stop short of making any fundamental changes thgat would break script compatibility.

Q: That is quite a big assumption that you've based these scripts on. What if I'm inclined to help expand the range of systems these scripts work on?

A: If you are running another distro, notice a script not working properly, are motivated to get the script working on that distro, and add proper conditional code to make your changes take effect only on the distros you've tested and certified the functionality on, then by all means issue a pull request for that shizz. 
However, I'm not especially interested in backports to earlier versions of Bash prior to 4 because I'm well aware that I make heavy use of Bash-isms that didn't exist in Bash 3. So let's just let the past stay in the past, OK?

Q: Why can't I install these utilities as a package with apt?

A: Because we're just not that cool yet. Maybe one day..

Q: You say Bash, but will these run under 'ksh', 'zsh', or 'fish'?

A: Yes. The scripts in the .shd directories should run fine. They've had limited testing on zsh and they worked fine because the shebang line causes them to run under bash regardless of the shell used to invoke them. However, you could run into issues with sourcing the scripts in 'env/'.

