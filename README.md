# lita-who_has

[![Build Status](https://travis-ci.org/knuedge/lita-who_has.png?branch=master)](https://travis-ci.org/knuedge/lita-who_has)
[![Coverage Status](https://coveralls.io/repos/github/knuedge/lita-who_has/badge.svg)](https://coveralls.io/github/knuedge/lita-who_has)

Still using (and need to keep track of) physical things? This plugin helps record and retrieve information about those things.

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
@bot claim thing2
@bot claimables thing.*
# => thing2 (user)
@bot wrestle thing2 from Jon Doe
@bot describe thing2 location the moon
@bot describe thing2
# => Here's what I know about thing2
# => {
#      "in use by": "user",
#      "location": "the moon"
#    }
```
