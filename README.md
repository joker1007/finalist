# Finalist
[![Build Status](https://travis-ci.org/joker1007/finalist.svg?branch=master)](https://travis-ci.org/joker1007/finalist)
[![Gem Version](https://badge.fury.io/rb/finalist.svg)](https://badge.fury.io/rb/finalist)

Finalist adds `final` method modifier.
`final` forbids method override.

This gem is pseudo static code analyzer by `method_added` and `singleton_method_added` and `included` and `extended`.

it detect final violation when class(module) is defined, not runtime.

Simple case is following.

```ruby
class A1
  extend Finalist

  final def foo
  end
end

class A2 < A1
  def foo # => raise
  end
end
```

This case raises `Finalist::OverrideFinalMethodError` at `def foo in A2 class`.

This gem supports other cases.
(see [finalist_spec.rb](https://github.com/joker1007/finalist/blob/master/spec/finalist_spec.rb))

### My similar gems

- [overrider](https://github.com/joker1007/overrider) (`override` implementation)
- [abstriker](https://github.com/joker1007/abstriker) (`abstract` implementation)

## Requirements
- ruby-2.5.0 or later (depend on `UnbountMethod#super_method` behavior)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'finalist'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install finalist

## Usage

A class or module extends `Finalist` module
And add `final` modifier to target method.
(`final` can accept symbol as method name.)

### for Production
If you want to disable Finalist, write `Finalist.disable = true` at first line.

### Examples

#### include module

```ruby
module E1
  extend Finalist

  final def foo
  end
end

module E2
  include E1
end

module E3
  include E2

  def foo # => raise
  end
end
```

#### include module after override

```ruby
module F1
  extend Finalist

  final def foo
  end
end

class F2
  def foo
  end

  include F1 # => raise
end
```

#### class method

```ruby
class J1
  extend Finalist

  class << self
    final def foo
    end
  end
end

class J2 < J1
  class << self
    def foo # => raise
    end
  end
end
```

#### extend object

```ruby
module H1
  extend Finalist

  final def foo
  end
end

a = "str"
a.extend(H1)
def a.foo # => raise
end
```

#### extend object after override

```ruby
module I1
  extend Finalist

  final def foo
  end
end

a = "str"
def a.foo
end
a.extend(I1) # => raise
```

#### class method by extend module

```ruby
module K1
  extend Finalist

  final def foo
  end
end

class K2
  extend K1

  class << self
    def foo # => raise
    end
  end
end
```

#### class method by extend module after override

```ruby
module L1
  extend Finalist

  final def foo
  end
end

class L2
  class << self
    def foo
    end
  end

  extend L1 # => raise
end
```

#### overrided by module prepend

This case is a intended loophole.

```ruby
module M1
  extend Finalist

  final def foo
  end
end

module M3
  def foo
    "foo"
  end
end

class M2
  include M1
  prepend M3
end

M2.new.foo # => "foo"
```

## How is this implemented?

Use so many ruby hooks. `method_added` and `singleton_method_added` and `included` and `extended`.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/joker1007/finalist.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
