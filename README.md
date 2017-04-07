# lita-who_has

[![Build Status](https://travis-ci.org/knuedge/lita-who_has.png?branch=master)](https://travis-ci.org/knuedge/lita-who_has)
[![Coverage Status](https://coveralls.io/repos/github/knuedge/lita-who_has/badge.svg)](https://coveralls.io/github/knuedge/lita-who_has)

Record and retrieve information about things

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
