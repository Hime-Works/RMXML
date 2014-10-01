RMXML - REXML for RPG Maker.
=====

# Description

This is the REXML library packaged for RPG Maker.

# Installation

Download the zip or clone the project, then copy everything into your project's `System` folder:

* rexml folder
* set.rb
* encoding.rb
* stringio.rb (this allows you to encrypt your projects)

Open `rmxml.rb` in notepad and add the script into your project if you are not using an external script editor.

# Usage

There are two methods in the `RMXML` module

### Saving objects

`save_data(obj, path)` - takes an object and writes it out to the specified path. For example if you wanted to dump actors out to an XML file, you could say
````
RMXML.save_data($game_actors, "my_actor_data.xml")
````

### Loading objects

`load_data(path)` - takes a path to an XML object and returns a reconstructed Ruby object.
````
myActors = RMXML.load_data("my_actor_data.xml")
````

# Demo

There's a demo. It's called Demo.zip. It gives a quick overview of some functions.

# Resources

Main site:
http://www.germane-software.com/software/rexml/

Tutorial:
http://www.germane-software.com/software/rexml/docs/tutorial.html
