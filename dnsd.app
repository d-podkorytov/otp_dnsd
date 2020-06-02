{application, dnsd,
 [{description, "An OTP DNS daemon"},
  {vsn, "0.1.0"},
  {registered, []},
  {mod, { dnsd_app, []}},
  {applications,
   [kernel,
    stdlib
   ]},
  {env,[]},
  {modules, []},

  {maintainers, []},
  {licenses, ["Apache 2.0"]},
  {links, []}
 ]}.
