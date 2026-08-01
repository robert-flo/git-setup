# Use a dotbare-style Arch distribution layout

git-setup will keep its source repository separate from its Arch package
repository. The source tree will use a small root launcher with one private
`runtime/` payload containing `helper/`, `lib/`, executable command modules in
`scripts/`, and `templates/`. The command modules remain directly executable;
the runtime folder only groups implementation files for discoverability.
dotbare-specific helpers will not be copied. The Arch package will install the
private payload in `/opt/git-setup` and expose `/usr/bin/git-setup` as its
launcher. This follows the established dotbare model and keeps distribution
concerns outside the source project.
