# bash
A collection of bash scripts for basic (and not-so-basic) system administration

## ASSumptions 
These scripts are only intended to work correctly on Debian 12 with Bash 5. 

So, if you find a bug and you're running something else, you must verify it on this setup before logging it. Otherwise, it will fall under "ports" which is experimental at this time. 

Basically, I'm just one guy and I'm not assuming that anyone will fall in love with a collection of shell scripts to the point that they're motivated to make a big deal out of it by supporting everything under the sun. So it is what it is.

## Installation
There is no apt package for this repo. These are scripts; the source is the executable.
Clone this repo then run the ./mkbinlink script to create symlinks in `~/bin` to the executable scripts in this repo.
Ensure that '~/bin/' is in your path and Bob's your uncle. (I'm not really that old, I just think it's funny to talk like I am)
Refer to the Scripts section below for a summaery of what the most significant scripts do.

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

* installers : If a script has an external dependency on a package that does not exist in the main Debian repo, then there should be a script in here that you can run to install that dependency. For the most part, the scripts in here should just add third-party repos so that you can then just `apt-get install` what you need.

# Scripts

To get you oriented, here is a brief overview of the most significant scripts in this repo. Other scripts you may encounter should be used with caution as they may be extremely niche or simply old and poorly maintained. Nonetheless, they should all print a help page when invoked with a '-h'. So either start there or start by just cracking them open and peeking at what is inside, whichever suits you better.

[section not yet complete]

## /
* ad-hoc-web-server : A quick and easy web server that provides HTTP access to whatever files are in the current directory when you run the command.
* chmodt : Adds the ability to specify whether you want chmod to act on only files or directories. Particularly useful if you don't like destroying your directory structure when recursing subdirectories. It's actually quite surprising that this is not in the command itself.

## env/

## lib/


# FAQ

Q: That is quite a big assumption that you've based these scripts on. What if I'm inclined to help expand the range of systems these scripts work on?
A: If you are running another distro, notice a script not working properly, are motivated to get the script working on that distro, and add proper conditional code to make your changes take effect only on the distros you've tested and certified the functionality on, then by all means issue a pull request for that shizz. 
However, I'm not especially interested in backports to earlier versions of Bash prior to 4 because I'm well aware that I make heavy use of Bash-isms that didn't exist in Bash 3. So let's just let the past stay in the past, OK?

Q: Why can't I install these utilities as a package with apt?
A: Because we're just not that cool yet. Maybe one day..
