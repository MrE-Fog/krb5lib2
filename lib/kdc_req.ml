open Sexplib.Std
open Asn.S
include Krb_combinators

type t =
  { padata : Pa_data.t list
  ; req_body : Kdc_req_body.t
  } [@@deriving sexp]

module Ast = struct
  type t =
      int (* pvno - 5 *)
    * int (* msg_type *)
    * Pa_data.Ast.t list option (* Non-empty *)
    * Kdc_req_body.Ast.t

  let app_asn tag =
    Application_tag.tag tag
      (sequence4
         (tag_required 1 ~label:"pvno" int)
         (tag_required 2 ~label:"msg_type" int)
         (tag_optional 3 ~label:"padata" (sequence_of Pa_data.Ast.asn))
         (tag_required 4 ~label:"req_body" Kdc_req_body.Ast.asn))
end

let app_ast_of_t t tag =
  let padata =
    match t.padata with
    | [] -> None
    | lst -> Some (List.map Pa_data.ast_of_t lst)
  in
  ( 5 (* Where 5 means krb5 - this is a constant forever *)
  , Application_tag.int_of_t tag
  , padata
  , Kdc_req_body.ast_of_t t.req_body
  )

let t_of_ast : Ast.t -> t = function
  | (_, _, a, b) -> 
    let padata = match a with
      | None -> []
      | Some l -> List.map Pa_data.t_of_ast l in
    let req_body = Kdc_req_body.t_of_ast b in
    { padata; req_body }