# lita-who_has

[![Build Status](https://travis-ci.org/knuedge/lita-who_has.png?branch=master)](https://travis-ci.org/knuedge/lita-who_has)
[![Coverage Status](https://coveralls.io/repos/knuedge/lita-who_has/badge.png)](https://coveralls.io/r/knuedge/lita-who_has)

Record and retrieve information about environment usage

## Installation

Add lita-who_has to your Lita instance's Gemfile:

``` ruby
gem 'lita-who_has'
```

## Configuration

``` ruby
config.handlers.who_has.namespace = 'my_project'
```

## Usage

``` bash
@bot claim thing1
@bot release thing1
@bot forget thing1
@bot claimables
@bot claimables thing.*
@bot wrestle thing2 from Jon Doe
```
