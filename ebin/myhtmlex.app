{application, myhtmlex, [
  {vsn, "0.2.1"},
  {description, "A module to decode HTML into a tree,\n  porting all properties of the underlying\n  library myhtml, being fast and correct\n  in regards to the html spec.\n"},
  {applications, [kernel,stdlib]},
  {modules, [myhtmlex, myhtmlex_nif]},
  {registered, []}
]}.
