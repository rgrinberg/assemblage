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

(** Manage OCamlfind invocations. *)

open Project

val p4o: Dep.resolver
(** Resolve external syntax extensions. *)

val incl: Dep.resolver
(** Resolve includes for external packages. *)

val bytlink: Dep.resolver
(** Resolve bytecode compilation for external packages. *)

val natlink: Dep.resolver
(** Resolve native code compilation for external packages. *)

module META: sig

  (** Generate META files. *)

  type t

  val create: version:string -> libs:Lib.t list -> Conf.t -> t option
  (** Create a META file. *)

  val write: t -> unit
  (** Write a META file. *)

  val of_project: Project.t -> unit
  (** Generate a META file for the given project. *)

end
