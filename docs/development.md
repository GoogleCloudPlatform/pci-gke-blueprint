# Development

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for information on contributing to this project.


### License Header

Each source code requires a copyright notice in the header. Use the
`addlicense` script to add this boilerplate to any new files.

```
go get -u github.com/google/addlicense
```

### Linting

The makefile in this project will lint or sometimes just format any shell,
Python, golang, Terraform, or Dockerfiles. The linters will only be run if
the makefile finds files with the appropriate file extension.

All of the linter checks are in the default make target, so you just have to
run

```
make -s
```

The -s is for 'silent'. Successful output looks like this

```
Running shellcheck
Running terraform validate
Running hadolint on Dockerfiles
Checking for required files
Testing the validity of the header check
..
----------------------------------------------------------------------
Ran 2 tests in 0.019s

OK
Checking file headers
The following lines have trailing whitespace
```

The linters
are as follows:
* Shell - shellcheck. Can be found in homebrew
* Terraform - terraform has a built-in linter in the 'terraform validate'
command.
* Dockerfiles - hadolint. Can be found in homebrew
