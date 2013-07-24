# Ruby-Processing

Is a ruby wrapper around [Processing][] built using [JRuby][], that allows you to code processing sketches in ruby.
[processing]: http://www.processing.org/

## Installation
Either clone this repo to your local Mac/Linux/Windows system
```bash
git clone https://github.com/monkstone/ruby-processing.git
```
Or download an release snapshot and unzip that followed by
```bash
cd ruby-processing
rake # build and test gem
gem install ruby-processing-2.1.0.gem # to install gem
```
Or if using jruby
```bash
jruby -S gem ruby-processing-2.1.0.gem # to install gem
```

## Documentation

See [Wiki][]
See also [Contributing][] and [Samples][]

# Usage Example

```bash
rp5 run my_sketch.rb
```
where a simple my_sketch.rb could look like this

```ruby
def setup
  size 400, 400  
  fill 255
end

def draw
  background 0
  ellipse mouse_x, mouse_y, 100, 100
end
```

## Supported Ruby Version

This library has been tested with the following ruby implementations

* Ruby 1.9.3
* Ruby 2.0.0
* [JRuby][]

[License][]

[license]: LICENSE.md
[contributing]: CONTRIBUTING.md
[jruby]: http://www.jruby.org/
[samples]: https://github.org/monkstone/code/samples/
[wiki]: https://github.org/monkstone/wiki/
## What's new

New capabilities since processing-2.0 include ability to use OPENGL VBO (PShape) and GLSL shaders (PShader), to keep abreast of latest developments check out the [codeanticode blog](http://codeanticode.wordpress.com/2013/06/04/processing-2-0-is-out-processing-2-0-is-in/). Some worked examples using new feature are included in the samples. The update to the latest jruby is also significant as the default is to run with ruby-1.9 support, and there have been many performance improvements. To use the invoke-dynamic java support for dynamic language, use java-7+ (NB: on the Mac need Intel-based Mac running Mac OS X version 10.7.3 and above to install java 7 otherwise use java 6). Many more worked examples are included.



