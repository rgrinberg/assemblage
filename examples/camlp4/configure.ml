#use "topfind";;
#require "tools";;
open Project

let t = Unit.create ~deps:[
    Dep.pkg_p4o "sexplib.syntax";
    Dep.pkg_p4o "comparelib.syntax";
    Dep.pkg     "sexplib";
    Dep.pkg     "comparelib";
    Dep.pkg     "xmlm";
  ] "t"

let lib = Lib.create [t] "mylib"

let conf = Project.Conf.create ~native:false ()

let () =
  Makefile.of_project (create ~libs:[lib] ~conf ())
