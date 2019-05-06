export_locals_without_parens = [
  database: 1,
  field: 1,
  field: 2,
  measurement: 1,
  tag: 1,
  tag: 2
]

[
  inputs: [
    "{bench,config,lib,test}/**/*.{ex,exs}",
    "{.credo,.formatter,mix}.exs"
  ],
  locals_without_parens: export_locals_without_parens,
  export: [locals_without_parens: export_locals_without_parens]
]
