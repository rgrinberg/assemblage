(*
 * Copyright (c) 2014 Thomas Gazagnaire <thomas@gazagnaire.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *)

open Project
open Printf

let (/) x y = Filename.concat x y

let (//) x y =
  match x with
  | None   -> y
  | Some x -> Filename.concat x y


module Variable = struct

  type assign = string

  type t = {
    name    : string;
    assign  : assign;
    contents: string;
  }

  let (=) name contents =
    { name; contents; assign = "=" }

  let (:=) name contents =
    { name; contents; assign = ":=" }

  let (+=) name contents =
    { name; contents; assign = "+=" }

  let subst t name ~input ~output =
    { name; assign = "=";
      contents = sprintf "$(${%s}:%s=%s)" t.name input output
    }

  let name t =
    sprintf "$(%s)" t.name

  let generate buf t =
    bprintf buf "%-25s %s %s\n" t.name t.assign t.contents

  let shell name command =
    { name; assign = "=";
      contents = sprintf "$(shell %s)" command
    }

  let files name ~dir ~ext =
    { name; assign = "=";
      contents = sprintf "$(wildcard %s/*.%s)" dir ext }

end

module Rule = struct

  type t = {
    name: string;
    targets: string list;
    prerequisites:string list;
    order_only_prerequisites:string list;
    recipe:string list;
  }

  let create ~name ~targets ~prereqs ?(order_only_prereqs=[]) ~recipe =
    { name; targets;
      prerequisites=prereqs;
      order_only_prerequisites=order_only_prereqs;
      recipe }

  let generate buf t =
    bprintf buf "%s: %s%s\n"
      (String.concat " " t.targets)
      (String.concat " " t.prerequisites)
      (match t.order_only_prerequisites with
       | []  -> ""
       | l   -> sprintf " | %s" (String.concat " " l));
    let () = match t.recipe with
      | [] -> bprintf buf "\t@\n"
      | l  -> List.iter (bprintf buf "\t%s\n") l
    in
    bprintf buf "\n"

  let target = "$@"
  let target_member = "$%"
  let prereq = "$<"
  let changed_prereqs = "$?"
  let prereqs = "$^"
  let dedup_prereqs = "$+"
  let stem = "$*"

end


type t = {
  header: string list;
  phony: string list;
  variables: Variable.t list;
  rules: Rule.t list;
}

let create ?(header=[]) ?(phony=[]) variables rules =
  { phony; header; variables; rules }

let write ?(file="Makefile") t =
  printf "\027[36m+ write %s\027[m\n" file;
  let buf = Buffer.create 1024 in
  bprintf buf "# Generated by ocaml-tools\n\n";
  List.iter (fun s ->
      Buffer.add_string buf s;
      Buffer.add_string buf "\n\n";
    ) t.header;
  let () = match t.phony with
    | [] -> ()
    | l  -> bprintf buf ".PHONY: %s\n\n" (String.concat " " l)
  in
  List.iter (Variable.generate buf) t.variables;
  bprintf buf "\n";
  List.iter (Rule.generate buf) t.rules;
  let oc = open_out file in
  output_string oc (Buffer.contents buf);
  close_out oc

(******************************************************************************)

module Unit: sig
  include (module type of Unit with type t = Unit.t)
  val rules: t -> Conf.t -> Rule.t list
  val variables: t -> Conf.t -> Variable.t list
end = struct

  type ext = {
    p4flags  : Variable.t option;
    compflags: Variable.t;
    prereqs  : [`native | `byte] -> string list;
  }

  let p4oflags t conf =
    match Unit.p4oflags t conf Ocamlfind.p4o with
    | [] -> None
    | l  ->
      let var = "P4FLAGS_" ^ Unit.name t in
      Some (Variable.(var := String.concat " " l))

  let compflags t conf =
    let links = Unit.compflags t conf Ocamlfind.incl in
    let var = "COMPFLAGS_" ^ Unit.name t in
    Variable.(var := String.concat " " links)

  let prereqs t conf mode =
    let lib = Unit.lib t in
    let ext = match mode with `native -> ".cmx" | `byte -> ".cmi" in
    let units = Dep.get_units (Unit.deps t) in
    let units = List.map (fun d ->
        match lib with
        | None   -> "$(DESTDIR)" / Unit.name d ^ ext
        | Some l -> "$(DESTDIR)" / Lib.name l / Unit.name d ^ ext
      ) units in
    let locals = Dep.get_local_libs (Unit.deps t) in
    let locals = List.map (fun l ->
        let units = Lib.units l in
        let cmxs = List.map (fun u ->
            "$(DESTDIR)" / Lib.name l / Unit.name u ^ ext
          ) units in
        let cmis = List.map (fun u ->
            "$(DESTDIR)" / Lib.name l / Unit.name u ^ ext
          ) units in
        (if Conf.native conf then cmxs else []) @ cmis
      ) locals in
    units @ List.concat locals

  let process t conf =
    let prereqs = prereqs t conf in
    let compflags = compflags t conf in
    let p4flags = p4oflags t conf in
    { prereqs; compflags; p4flags }

  let rules t conf =

    let x = process t conf in

    let lib_name = match Unit.lib t with
      | None   -> None
      | Some l -> Some (Lib.name l) in

    let pp = match x.p4flags with
      | None   -> ""
      | Some v -> sprintf "-pp '$(CAMLP4O) %s' " (Variable.name v) in

    let incl = match lib_name with
      | None   -> ""
      | Some l -> sprintf "-I %s " ("$(DESTDIR)" / l) in

    let target ext =
      "$(DESTDIR)" / (lib_name // Unit.name t ^ ext) in

    let source ext =
      Unit.dir t // Unit.name t ^ ext in

    let ln = (* link source file to target directory *)
      let aux ext =
        let source = source ext in
        let target = target ext in
        if Sys.file_exists source then
          [Rule.create ("ln" ^ ext)
             [target] [source]
             ((match lib_name with
                 | None   -> []
                 | Some d -> [sprintf "mkdir -p %s" ("$(DESTDIR)" / d)])
              @ [sprintf "ln -sf $(shell pwd)/%s %s" source target])]
        else []
      in
      aux ".ml" @ aux ".mli"
    in

    let cmi = (* generate cmis *)
      let targets, prereqs =
        if Sys.file_exists (source ".mli") then [target ".cmi"], [target ".mli"]
        else [target ".cmo"; target ".cmi"], [target ".ml"] in
      [Rule.create "cmi"
         targets
         (prereqs @ x.prereqs `byte)
         [sprintf "$(OCAMLC) -c %s%s%s %s"
            incl pp (Variable.name x.compflags) Rule.prereq]]
    in

    let cmo = (* Generate cmos *)
      if Sys.file_exists (source ".mli") then
        [Rule.create "cmo"
           [target ".cmo"]
           (target ".ml" :: target ".cmi" :: x.prereqs `byte)
           [sprintf "$(OCAMLC) -c %s%s%s %s"
              incl pp (Variable.name x.compflags) Rule.prereq]]
      else
        []
    in

    let cmx = (* Generate cmxs *)
      if Conf.native conf then
        [Rule.create "cmx"
           [target ".cmx"]
           (target ".ml" :: target ".cmi" :: x.prereqs `native)
           [sprintf "$(OCAMLOPT) -c %s%s%s %s"
              incl pp (Variable.name x.compflags) Rule.prereq]]
      else
        []
    in
    ln @ cmi @ cmo @ cmx

    let variables t conf =
      let x = process t conf in
      x.compflags :: match x.p4flags with
      | None   -> []
      | Some l -> [l]

    include Unit

end

module Lib: sig
  include (module type of Lib with type t = Lib.t)
  val rules: t -> Conf.t -> Rule.t list
  val variables: t -> Conf.t -> Variable.t list
end = struct

  let variables t conf =
    List.concat (List.map (fun u -> Unit.variables u conf) (Lib.units t))

  let rules t conf =
    let file_u u ext = "$(DESTDIR)" / Lib.name t / Unit.name u ^ ext in
    let file ext     = "$(DESTDIR)" / Lib.name t / Lib.name t ^ ext in
    let cma =
      let cmo = List.map (fun u -> file_u u ".cmo") (Lib.units t) in
      let cmi = List.map (fun u -> file_u u ".cmi") (Lib.units t) in
      Rule.create "cma" [file ".cma"] (cmo @ cmi) [
        sprintf "$(OCAMLC) -a %s -o %s" (String.concat " " cmo) Rule.target
      ] in
    let aux mode =
      if mode = `shared && not (Conf.native_dynlink conf) then []
      else
        let ext, mode = if mode = `shared then "cmxs", "-shared" else "cmxa", "-a" in
        let cmx = List.map (fun u -> file_u u  ".cmx") (Lib.units t) in
        let cmi = List.map (fun u -> file_u u  ".cmi") (Lib.units t) in
        [Rule.create ext [file ("." ^ ext)] (cmx @ cmi) [
            sprintf "$(OCAMLOPT) %s %s -o %s" mode (String.concat " " cmx) Rule.target
          ]] in
    (Rule.create (Lib.name t)
       [Lib.name t]
       ([file ".cma"]
        @ (if Conf.native conf then [file ".cmxa"] else [])
        @ (if Conf.native_dynlink conf then [file ".cmxs"] else []))
       [])
    :: cma
    :: (if Conf.native conf then aux `archive else [])
    @ (if Conf.native_dynlink conf then aux `shared else [])
    @ List.concat (List.map (fun u -> Unit.rules u conf) (Lib.units t))

  include Lib

end

module Top: sig
  include (module type of Top with type t = Top.t)
  val rules: t -> Conf.t -> Rule.t list
  val variables: t -> Conf.t -> Variable.t list
end = struct

  let variables t conf =
    let link =
      Top.libs t
      |> Dep.local_libs
      |> Dep.closure
      |> Dep.get_libs
      |> Ocamlfind.bytlink
      |> String.concat " "
    in
    let n = sprintf "LINKTOP_%s" (Top.name t) in
    Variable.(n := link)
    :: List.concat (List.map (fun l -> Lib.variables l conf) (Top.libs t))

  let rules t conf =
    let deps =
      Top.libs t
      |> Dep.local_libs
      |> Dep.closure in
    let cma =
      deps
      |> Dep.get_local_libs
      |> List.map (fun l -> "$(DESTDIR)" / Lib.name l / Lib.name l ^ ".cma") in
    let link = sprintf "$(LINKTOP_%s)" (Top.name t) in
    Rule.create "toplevel-target"
      [Top.name t]
      ["$(DESTDIR)" / Top.name t / Top.name t]
      []
    :: Rule.create "toplevel"
      ["$(DESTDIR)" / Top.name t / Top.name t]
      cma
      [sprintf "mkdir -p %s" ("$(DESTDIR)" / Top.name t);
       sprintf "$(OCAMLMKTOP) %s %s -o %s" link Rule.prereqs Rule.target]
    :: List.concat (List.map (fun l -> Lib.rules l conf) (Top.libs t))

  include Top

end

module Bin: sig
  include (module type of Bin with type t = Bin.t)
  val rules: t -> Conf.t -> Rule.t list
  val variables: t -> Conf.t -> Variable.t list
end = struct

  let variables t conf =
    let link =
      Dep.local_libs (Bin.libs t) @ Dep.units (Bin.units t)
      |> Dep.closure
      |> Dep.get_libs
      |> (fun links ->
          if Conf.native conf then Ocamlfind.natlink links
          else Ocamlfind.bytlink links)
      |> String.concat " " in
    let n = "LINK_" ^ Bin.name t in
    (* XXX: ugly *)
    let l' = Lib.create [] (Bin.name t) in
    Variable.(n := link)
    :: List.concat (List.map (fun u -> Unit.variables (Unit.with_lib u l') conf) (Bin.units t))
    @  List.concat (List.map (fun l -> Lib.variables l conf) (Bin.libs t))

  let rules t conf =
    let deps =
      Dep.local_libs (Bin.libs t) @ Dep.units (Bin.units t)
      |> Dep.closure in
    let libs =
      deps
      |> Dep.get_local_libs
      |> List.map (fun l ->
          let file ext = "$(DESTDIR)" / Lib.name l / Lib.name l ^ ext in
          if Conf.native conf then file ".cmxa"
          else file ".cma") in
    let file u ext =
      "$(DESTDIR)" / Bin.name t / Unit.name u ^ ext in
    let units =
      Bin.units t
      |> List.map (fun u ->
          if Conf.native conf then file u ".cmx"
          else file u ".cmo") in
    let link = sprintf "$(LINK_%s)" (Bin.name t) in
    let compiler = if Conf.native conf then "$(OCAMLOPT)" else "$(OCAMLC)" in
    (* XXX: ugly *)
    let l' = Lib.create [] (Bin.name t) in
    Rule.create "bin-target"
      [Bin.name t]
      ["$(DESTDIR)" / Bin.name t / Bin.name t]
      []
    :: Rule.create "bin"
      ["$(DESTDIR)" / Bin.name t / Bin.name t]
      (libs @ units)
      [sprintf "%s %s %s -o %s" compiler link Rule.prereqs Rule.target]
    :: List.concat (List.map (fun u -> Unit.rules (Unit.with_lib u l') conf) (Bin.units t))
    @  List.concat (List.map (fun l -> Lib.rules l conf) (Bin.libs t))

  include Bin

end

let conmap f l = List.concat (List.map f l)

let dedup l =
  let saw = Hashtbl.create (List.length l) in
  let rec aux acc = function
    | []   -> List.rev acc
    | h::t ->
      if Hashtbl.mem saw h then aux acc t
      else (
        Hashtbl.add saw h true;
        aux (h :: acc) t
      ) in
  aux [] l

let of_project ?file t =
  let libs = Project.libs t in
  let bins = Project.bins t in
  let tops = Project.tops t in
  let conf = Project.conf t in
  let variables =
    dedup (
      Variable.("DESTDIR" := Conf.destdir conf)
      :: Variable.("OCAMLOPT"   := "ocamlopt")
      :: Variable.("OCAMLC"     := "ocamlc")
      :: Variable.("OCAMLMKTOP" := "ocamlmktop")
      :: Variable.("CAMLP4O"    := "camlp4o")
      :: conmap (fun t -> Lib.variables t conf) libs
      @  conmap (fun t -> Bin.variables t conf) bins
      @  conmap (fun t -> Top.variables t conf) tops
    ) in
  let rules =
    dedup (
      conmap (fun t -> Lib.rules t conf) libs
      @ conmap (fun t -> Bin.rules t conf) bins
      @ conmap (fun t -> Top.rules t conf) tops
    ) in
  let main = Rule.create "main" ["all"]
      (List.map Lib.name libs @ List.map Bin.name bins @ List.map Top.name tops)
      [] in
  let clean = Rule.create "clean" ["clean"] [] [
      "rm -f *~ **/*~";
      sprintf "rm -rf $(DESTDIR)";
    ] in
  let t = create
      ~phony:["all"; "clean"]
      variables
      (main :: clean :: rules) in
  write ?file t
