A module to crawl zerome hubs.

Usage
-----

See <https://weakish.github.io/zerome-crawler/api/>

Install
-------

### Dependencies

Java 7+

It does not depend on `zeronet.py`.
So you can copy ZeroHub files from other machines.

Also, it will not modify ZeroHub directory.

### As a library

#### With Java

Download the jar file at [Releases] page and put it in `classpath`.

[Releases]: https://github.com/weakish/zerome-crawler/releases

#### With Ceylon

Download the car file at [Releases] page and put it in ceylon module repository.

### As a command line tool

Download the jar file at [Releases] page and rename it to `zerome-crawler.jar`
or anything you like.

Development
-----------

You need Ceylon, unless you want to mess up with decompiled Java code.

Tested on Ceylon 1.2.2, may work with other versions.

If you need to modify the source, clone this repository with git.

If you do not want to use git,
download the tarball, zip or car file at [Releases].

### Makefile

There is a `Makefile` in the repository, compatible with both BSD and GNU `make`.

#### Test

```sh
make test
```

#### Compile

```
make build
```

#### Package

Packages to a fat jar (requires `ceylon` 1.2.3 snapshot)

```sh
make jar
```

### Contribute

See `CONTRIBUTING.md` in the repository.

License
-------

0BSD
