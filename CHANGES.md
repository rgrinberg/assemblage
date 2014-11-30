
# 0.4.0: [trunk]
- Fix regression in the generation of docs
- Merlin .merlin file generation

# 0.3.0: [2014-08]
- #43 Simpler and saner command-line options handling.
  Use `--feature=[true|false]` instead of --[enable|disable]-feature
- #63 Remove the big recursive module in As_project: that makes the code simpler
  and easier to maintain and extend
- #66 Rename the `Dir` component to `Container` to better reflect its semantics
- #55, #74 Unify `configure.ml` and `describe.ml` into an unique `assemblage`
  command-line tool
- #65 The `Dir` argument became `Path` and now takes a list of directory names
- Remove the dependency to `camlp4`: do not depend on `optcomp` anymore but
  instead use the "linking trick" to include a different directory depending
  on the version of the compiler. Also, use the generated Makefiles now use the
  newly released `ocaml-dumpast` when it is available to dump the parsetree
  instead of calling `camlp4`. Use `assemble setup --no-dumpast` to continue
  to always use `camlp4`.
- Fix a linking bug when building a binary with multiple files
- Do not generate an empty META file when there is no library in the project
- Fix a bug in the dependency tracking, now only the dependency of the modified
  files are re-computed
- Use ASSEMBLAGE_UTF8_MSGS to have a nice wine emoji
- Better startup procedure: `assemble.ml` now needs to call the code to parse
  the command-line (`Assemble.assemble`), which also means that that file can be
   compiled to a self-contained native binary if needed.
- Faster and simpler bootstrap procedure
- Add a `Doc` component

# 0.2.0: [2014-08]

- #54 No more mutation in the underlying component graph
- #52 Unify the compilation units, with different kinds: they can be OCaml,
  C or Js
- #50 Generalise the `Other' components to be similar to a Makefile rule
- (almost) all the components can now take an `Other' as argument to express the
  fact that they can be generated
- #38 We still have a static collection of components, but their
  inter-dependencies is computed dynamically, as you don't want to run
  `./configure` every time you change a dependency between modules.
- #24 Be always explicit when creating a library and a binary to let the user
  specify the order in which component units should be linked
- For each compilation unit, apply the pre-processors only once at the beginning
  of the build process
- Move most of the compilation rules in As_project instead of As_makefile and
  make it generic enough to be used by other tools
- Be more explicit in the type describing the different compilation phases and
  the different files

# 0.1.0: [2014-07]
- Initial release to get early feedback.
- Support for simple to medium projects
- Not working: the C stub generation does not work completely
- Not working: no release hooks
- Not working: the .js files are not installed
