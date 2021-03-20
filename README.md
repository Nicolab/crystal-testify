# Testify

[![CI Status](https://github.com/Nicolab/crystal-testify/workflows/CI/badge.svg?branch=master)](https://github.com/Nicolab/crystal-testify/actions) [![GitHub release](https://img.shields.io/github/release/Nicolab/crystal-testify.svg)](https://github.com/Nicolab/crystal-testify/releases) [![Docs](https://img.shields.io/badge/docs-available-brightgreen.svg)](https://nicolab.github.io/crystal-testify/)

Testing utilities for Crystal lang specs.

Specs or unit test style?

The both! Based on std's Crystal Spec, Testify is an OOP abstraction for creating unit and integration tests.
This allows structuring some tests in an objective of maintenability, extendability and reusability.

Some tests require a Spec style:

```crystal
it "should create an account and send a welcome email" do
  # ...
end
```

Other tests require a unitary way:

```crystal
def test_send_html_email
  # ...
end

def test_send_text_email
  # ...
end

def test_get_with_default_value
  # ...
end

def test_get_without_default_value
  # ...
end

def test_delete_by_id
  # ...
end
```

Other tests require the benefits of OOP. Advanced example:

```crystal
# Common tests for all model.
abstract class ModelTest < Testify::Test
  def before_all
    db.connect
    db.create_tables
  end

  def after_all
    db.clean
  end

  def before_each
    db.init
  end

  def after_each
    db.reset
  end

  abstract def db : DBHelper
  abstract def model_class : Model.class
  abstract def get_model_values : Hash
  abstract def get_updated_model_values : Hash

  @[Data("get_model_values")]
  def test_create(values, expected)
    model = model_class.create(values)
    model.should be_a Model
    model.to_h should eq expected
  end

  @[Data("get_updated_model_values")]
  def test_update(values, expected)
    model_class.create(get_model_values)
    model_class.update(values).to_h.should eq expected
    # ...
  end

  def test_delete_by_id
    id = model_class.create(get_model_values)
    id.should be_a(Int32)
    model_class.delete(id).rows_affected.should eq 1
    model_class.find?(id).should eq nil
  end

  def test_find_by_id
    # ...
  end
end
```

In this example, thanks to `ModelTest` class defined above.
Because we define a common behavior that can be used by all the models that inherit it.

With the main benefits:

* Common lifecycle hooks (before_all, before_each, ...).
* Some tests common to all models do not need to be repeated.
* Clean structured fashion for all models.
* Reusability (example: `AdminTest < UserTest` that reuses common tests, states and `Data` source).

Common tests will be automatically executed (by inheritance):

```crystal
# Test cases for the User model.
class UserTest < ModelTest
  getter db : DBHelper = DBHelper.new
  getter model_class : Model.class = User

  # `Data` source.
  def get_model_values : Hash
    {
      "username" => "foo",
      "email" => "hello@example.org",
      # ...
    }
  end

  # Updated `Data` source.
  def get_updated_model_values : Hash
    user_h = get_model_values
    user_h["username"] = "bar"
    user_h["email"] = "updated@example.org"
    user_h
  end

  # Just write other tests specific to the model User...
end
```

## Installation

1. Add the dependency to your `shard.yml`:

```yaml
   dependencies:
     testify:
       github: nicolab/crystal-testify
       version: ~> 1.0.0 # Check the latest version!
```

2. Run `shards install`

## Usage

📘 [API doc](https://nicolab.github.io/crystal-testify/).

---

Based and fully compliant with:

* [Crystal Spec std's](https://crystal-lang.org/api/Spec.html)
* [Testing Crystal Code](https://crystal-lang.org/reference/guides/testing.html)

---

Define the test(s) class(es):

```crystal
require "testify"

class ExampleTest < Testify::Test
  @hey = "Crystal is awesome!"

  def test_something
    true.should eq true
  end

  def test_my_mood
    @hey.should eq "Crystal is awesome!"
  end

  # ...
end

class AnotherTest < Testify::Test
  def test_foo
    true.should eq true
    # ...
  end

  # ...
end

# Runs all test cases
Testify.run_all
```

A `Test` class can be run alone:

```crystal
# Runs only ExampleTest tests
ExampleTest.run

# Runs only AnotherTest tests
AnotherTest.run
```

Internally, `Testify.run_all` executes the `run` method of each `Test` class defined.

### POO

All benefits related to a class are available, like:

* [macros: hooks](https://crystal-lang.org/reference/syntax_and_semantics/macros/hooks.html)
* [finalize](https://crystal-lang.org/reference/syntax_and_semantics/finalize.html)
* [annotations](https://crystal-lang.org/reference/syntax_and_semantics/annotations/index.html)
* Macros, inheritance, modules, variables, methods, visibility, ... powerful 🚀

Under the hood:

* A class defines a "describe" block.
* Methods `test_` and `ftest_`, define a `it` block.
* `ptest_` method, `Pending` and `Skip` annotations, define a `pending` block.
* `ftest_` method and `Focus` annotation, add `focus: true` to a `it` block.
* `Tags("foo")` annotation on a `test` method, add `tags: "foo"` to a `it` block.
* `Tags("foo")` annotation on a `Test` class, add `tags: "foo"` to a `describe` block.

### Lifecycle

Optionally if you need life cycle hooks related to your tests.

```crystal
class ExampleTest < Testify::Test
  def before_all
    puts "before_all"
  end

  def before_each
    puts "before_each"
  end

  def around_all(test)
    puts "around_all - before"
    test.run
    puts "around_all - after"
  end

  def around_each(test)
    puts "around_each - before"
    test.run
    puts "around_each - after"
  end

  def after_all
    puts "before_all"
  end

  def after_each
    puts "before_each"
  end

  # ...
end
```

### Initialize

Optionally if you need to initialize some variables.

```crystal
class ExampleTest < Testify::Test
  # You can initialize variables, constants, contexts, ...

  def initialize
    # Configure here...
  end
end
```

### Test cases

A test case, it's like:

```crystal
it "my feature" do
  # ...
end
```

Except that this is written in the OOP way, in a method:

```crystal
class ExampleTest < Testify::Test
  # A test case
  def test_my_feature
    # ...
  end

  # Another test.
  def test_another_thing
    # ...
  end

  # ...
end
```

### Pending test / Skip test

Pending test, it's like:

```crystal
pending "my feature" do
  # ...
end
```

This can be written:

```crystal
class ExampleTest < Testify::Test
  # Prefixed by `p`
  def ptest_my_feature
    # ...
  end

  # Pending test with `Pending` annotation.
  @[Pending]
  def test_my_feature
    # ...
  end

  # Pending test with `Skip` annotation.
  # Same as `Pending`, just another syntactic flavor.
  @[Skip]
  def test_my_feature
    # ...
  end

  # ...
end
```

A class can be skipped:

```crystal
@[Pending]
# or @[Skip]
class ExampleTest < Testify::Test
  # ...
end
```

It's like marking a `describe` block as `pending`.
All tests contained in the current class will be skipped.


### Focused test

Focused test, it's like:

```crystal
it "my feature", focus: true do
  # ...
end
```

This can be written:

```crystal
class ExampleTest < Testify::Test
  # Prefixed by `f`
  def ftest_my_feature
  end

  # Focused test with `Focus` annotation.
  @[Focus]
  def test_my_feature
  end
end
```

A class can be focused:

```crystal
@[Focus]
class ExampleTest < Testify::Test
  # ...
end
```

It's like focusing a `describe` block.
Only the tests contained in the focused class will be executed.

### Tags

Tags test with `Tags` annotation, it's like:

```crystal
it "my feature", tags: "slow" do
  # ...
end
```

This can be written:

```crystal
class ExampleTest < Testify::Test
  @[Tags("slow")]
  def test_my_feature
  end
end
```

A class can be tagged:

```crystal
@[Tags("foo")]
class ExampleTest < Testify::Test
  # ...
end
```

It's like tagging a `describe` block.

### Tacker / Tracer

Tracking utilities to trace some behaviors (like a method call, an event listener, a `spawn`, a `Channel`, ...).

## Development

Install dev dependencies:

```sh
shards install
```

Run:

```sh
crystal spec
```

Clean before commit:

```sh
crystal tool format
./bin/ameba
```

## Contributing

1. Fork it (https://github.com/Nicolab/crystal-testify/fork)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## LICENSE

[MIT](https://github.com/Nicolab/crystal-testify/blob/master/LICENSE) (c) 2021, Nicolas Talle.

## Author

| [![Nicolas Tallefourtane - Nicolab.net](https://www.gravatar.com/avatar/d7dd0f4769f3aa48a3ecb308f0b457fc?s=64)](https://github.com/sponsors/Nicolab) |
|---|
| [Nicolas Talle](https://github.com/sponsors/Nicolab) |
| [![Make a donation via Paypal](https://www.paypalobjects.com/en_US/i/btn/btn_donate_SM.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=PGRH4ZXP36GUC) |

### Inspi

* [Unit testing](https://en.wikipedia.org/wiki/Unit_testing)
* [Integration testing](https://en.wikipedia.org/wiki/Integration_testing)
* [Data-Driven testing](https://en.wikipedia.org/wiki/Data-driven_testing)
* [ASPEC class](https://github.com/athena-framework/spec/blob/a28a66ee0985d5aed7948183a5942c1c04848a31/src/test_case.cr)
* [Testing Crystal Code](https://crystal-lang.org/reference/guides/testing.html)
* [Crystal Spec std's](https://crystal-lang.org/api/Spec.html)